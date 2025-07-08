//
// DeliveryTracker.swift
// bitchat
//
// This is free and unencumbered software released into the public domain.
// For more information, see <https://unlicense.org>
//

import Foundation
import Combine

enum DeliveryStatus: String, CaseIterable {
    case pending = "pending"
    case sent = "sent"
    case delivered = "delivered"
    case failed = "failed"
    case partiallyDelivered = "partial"
    case retrying = "retrying"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .sent: return "Sent"
        case .delivered: return "Delivered"
        case .failed: return "Failed"
        case .partiallyDelivered: return "Partial"
        case .retrying: return "Retrying"
        }
    }
    
    var emoji: String {
        switch self {
        case .pending: return "⏳"
        case .sent: return "📤"
        case .delivered: return "✅"
        case .failed: return "❌"
        case .partiallyDelivered: return "⚠️"
        case .retrying: return "🔄"
        }
    }
}

class DeliveryTracker {
    static let shared = DeliveryTracker()
    
    // Track pending deliveries
    private var pendingDeliveries: [String: PendingDelivery] = [:]
    private let pendingLock = NSLock()
    
    // Track received ACKs to prevent duplicates
    private var receivedAckIDs = Set<String>()
    private var sentAckIDs = Set<String>()
    
    // Enhanced timeout configuration
    private let privateMessageTimeout: TimeInterval = 30  // 30 seconds
    private let roomMessageTimeout: TimeInterval = 60     // 1 minute
    private let favoriteTimeout: TimeInterval = 300       // 5 minutes for favorites
    
    // Enhanced retry configuration
    private let maxRetries = 5  // Increased from 3
    private let baseRetryDelay: TimeInterval = 2  // Base retry delay
    private let maxRetryDelay: TimeInterval = 30  // Maximum retry delay
    
    // Publishers for UI updates
    let deliveryStatusUpdated = PassthroughSubject<(messageID: String, status: DeliveryStatus), Never>()
    let retryAttempted = PassthroughSubject<(messageID: String, attempt: Int, maxAttempts: Int), Never>()
    
    // Cleanup timer
    private var cleanupTimer: Timer?
    
    // Retry timer
    private var retryTimer: Timer?
    
    // Weak reference to mesh service for retries
    weak var meshService: BluetoothMeshService?
    
    struct PendingDelivery {
        let messageID: String
        let originalMessage: BitchatMessage
        let sentAt: Date
        let recipientID: String
        let recipientNickname: String
        var retryCount: Int
        let isChannelMessage: Bool
        let isFavorite: Bool
        var ackedBy: Set<String> = []  // For tracking partial channel delivery
        let expectedRecipients: Int  // For channel messages
        var timeoutTimer: Timer?
        var nextRetryTime: Date?
        var lastRetryTime: Date?
        
        var isTimedOut: Bool {
            let timeout: TimeInterval = isFavorite ? 300 : (isChannelMessage ? 60 : 30)
            return Date().timeIntervalSince(sentAt) > timeout
        }
        
        var shouldRetry: Bool {
            return retryCount < 5 && !isTimedOut && (isFavorite || !isChannelMessage)
        }
        
        var nextRetryDelay: TimeInterval {
            // Exponential backoff with jitter
            let baseDelay: TimeInterval = 2.0
            let exponentialDelay = baseDelay * pow(2.0, Double(retryCount))
            let jitter = Double.random(in: 0.8...1.2) // ±20% jitter
            return min(exponentialDelay * jitter, 30.0) // Cap at 30 seconds
        }
        
        mutating func incrementRetry() {
            retryCount += 1
            lastRetryTime = Date()
            nextRetryTime = Date().addingTimeInterval(nextRetryDelay)
        }
    }
    
    private init() {
        startCleanupTimer()
        startRetryTimer()
    }
    
    deinit {
        cleanupTimer?.invalidate()
        retryTimer?.invalidate()
    }
    
    // MARK: - Public Methods
    
    func trackMessage(_ message: BitchatMessage, recipientID: String, recipientNickname: String, isFavorite: Bool = false, expectedRecipients: Int = 1) {
        // Don't track broadcasts or certain message types
        guard message.isPrivate || message.channel != nil else { return }
        
        var delivery = PendingDelivery(
            messageID: message.id,
            originalMessage: message,
            sentAt: Date(),
            recipientID: recipientID,
            recipientNickname: recipientNickname,
            retryCount: 0,
            isChannelMessage: message.channel != nil,
            isFavorite: isFavorite,
            expectedRecipients: expectedRecipients,
            timeoutTimer: nil
        )
        
        // Store the delivery with lock
        pendingLock.lock()
        pendingDeliveries[message.id] = delivery
        pendingLock.unlock()
        
        // Update status to sent
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.updateDeliveryStatus(message.id, status: .sent)
        }
        
        // Schedule timeout (outside of lock)
        scheduleTimeout(for: message.id)
    }
    
    func processDeliveryAck(_ ack: DeliveryAck) {
        // Prevent duplicate processing
        guard !receivedAckIDs.contains(ack.id) else { return }
        receivedAckIDs.insert(ack.id)
        
        pendingLock.lock()
        defer { pendingLock.unlock() }
        
        if var delivery = pendingDeliveries[ack.messageID] {
            if delivery.isChannelMessage {
                // For channel messages, track partial delivery
                delivery.ackedBy.insert(ack.senderID)
                
                let deliveryRatio = Double(delivery.ackedBy.count) / Double(delivery.expectedRecipients)
                
                if delivery.ackedBy.count >= delivery.expectedRecipients {
                    // Fully delivered
                    pendingDeliveries.removeValue(forKey: ack.messageID)
                    delivery.timeoutTimer?.invalidate()
                    
                    DispatchQueue.main.async { [weak self] in
                        self?.deliveryStatusUpdated.send((ack.messageID, .delivered))
                    }
                } else if deliveryRatio >= 0.5 {
                    // Partially delivered (>50%)
                    pendingDeliveries[ack.messageID] = delivery
                    
                    DispatchQueue.main.async { [weak self] in
                        self?.deliveryStatusUpdated.send((ack.messageID, .partiallyDelivered))
                    }
                }
            } else {
                // Private message - single ACK means delivered
                pendingDeliveries.removeValue(forKey: ack.messageID)
                delivery.timeoutTimer?.invalidate()
                
                DispatchQueue.main.async { [weak self] in
                    self?.deliveryStatusUpdated.send((ack.messageID, .delivered))
                }
            }
        }
    }
    
    func generateAck(for message: BitchatMessage, senderID: String, senderNickname: String) -> DeliveryAck? {
        let ackID = "\(message.id)-ack-\(senderID)"
        
        // Prevent duplicate ACKs
        guard !sentAckIDs.contains(ackID) else { return nil }
        sentAckIDs.insert(ackID)
        
        return DeliveryAck(
            id: ackID,
            messageID: message.id,
            senderID: senderID,
            senderNickname: senderNickname,
            timestamp: Date()
        )
    }
    
    func retryFailedMessage(_ messageID: String) {
        pendingLock.lock()
        guard var delivery = pendingDeliveries[messageID] else {
            pendingLock.unlock()
            return
        }
        
        guard delivery.shouldRetry else {
            pendingLock.unlock()
            updateDeliveryStatus(messageID, status: .failed)
            return
        }
        
        delivery.incrementRetry()
        pendingDeliveries[messageID] = delivery
        pendingLock.unlock()
        
        // Update status to retrying
        updateDeliveryStatus(messageID, status: .retrying)
        
        // Notify about retry attempt
        DispatchQueue.main.async { [weak self] in
            self?.retryAttempted.send((messageID, delivery.retryCount, 5))
        }
        
        // Attempt to resend the message
        DispatchQueue.main.asyncAfter(deadline: .now() + delivery.nextRetryDelay) { [weak self] in
            self?.attemptResend(delivery)
        }
    }
    
    // MARK: - Private Methods
    
    private func updateDeliveryStatus(_ messageID: String, status: DeliveryStatus) {
        DispatchQueue.main.async { [weak self] in
            self?.deliveryStatusUpdated.send((messageID, status))
        }
    }
    
    private func scheduleTimeout(for messageID: String) {
        pendingLock.lock()
        guard var delivery = pendingDeliveries[messageID] else {
            pendingLock.unlock()
            return
        }
        
        let timeout: TimeInterval = delivery.isFavorite ? favoriteTimeout : 
                                   (delivery.isChannelMessage ? roomMessageTimeout : privateMessageTimeout)
        
        delivery.timeoutTimer = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false) { [weak self] _ in
            self?.handleTimeout(messageID: messageID)
        }
        
        pendingDeliveries[messageID] = delivery
        pendingLock.unlock()
    }
    
    private func handleTimeout(messageID: String) {
        pendingLock.lock()
        guard let delivery = pendingDeliveries[messageID] else {
            pendingLock.unlock()
            return
        }
        
        if delivery.shouldRetry {
            pendingLock.unlock()
            retryFailedMessage(messageID)
        } else {
            pendingDeliveries.removeValue(forKey: messageID)
            pendingLock.unlock()
            updateDeliveryStatus(messageID, status: .failed)
        }
    }
    
    private func attemptResend(_ delivery: PendingDelivery) {
        guard let meshService = meshService else { return }
        
        if delivery.isChannelMessage {
            // Resend channel message
            if let channel = delivery.originalMessage.channel {
                meshService.sendMessage(
                    delivery.originalMessage.content,
                    mentions: delivery.originalMessage.mentions,
                    channel: channel
                )
            }
        } else {
            // Resend private message
            meshService.sendPrivateMessage(
                delivery.originalMessage.content,
                to: delivery.recipientID,
                recipientNickname: delivery.recipientNickname
            )
        }
    }
    
    private func startCleanupTimer() {
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.cleanupExpiredDeliveries()
        }
    }
    
    private func startRetryTimer() {
        retryTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.processRetryQueue()
        }
    }
    
    private func processRetryQueue() {
        let now = Date()
        var messagesToRetry: [String] = []
        
        pendingLock.lock()
        for (messageID, delivery) in pendingDeliveries {
            if let nextRetryTime = delivery.nextRetryTime,
               now >= nextRetryTime,
               delivery.shouldRetry {
                messagesToRetry.append(messageID)
            }
        }
        pendingLock.unlock()
        
        for messageID in messagesToRetry {
            retryFailedMessage(messageID)
        }
    }
    
    private func cleanupExpiredDeliveries() {
        pendingLock.lock()
        let expiredMessages = pendingDeliveries.filter { $0.value.isTimedOut }.map { $0.key }
        for messageID in expiredMessages {
            if let delivery = pendingDeliveries[messageID] {
                delivery.timeoutTimer?.invalidate()
                pendingDeliveries.removeValue(forKey: messageID)
            }
        }
        pendingLock.unlock()
        
        // Clean up old ACK IDs (keep only last 1000)
        if receivedAckIDs.count > 1000 {
            let toRemove = receivedAckIDs.count - 800
            receivedAckIDs = Set(receivedAckIDs.dropFirst(toRemove))
        }
        
        if sentAckIDs.count > 1000 {
            let toRemove = sentAckIDs.count - 800
            sentAckIDs = Set(sentAckIDs.dropFirst(toRemove))
        }
    }
    
    // MARK: - Public Query Methods
    
    func getPendingDeliveries() -> [PendingDelivery] {
        pendingLock.lock()
        defer { pendingLock.unlock() }
        return Array(pendingDeliveries.values)
    }
    
    func getDeliveryStatus(for messageID: String) -> DeliveryStatus? {
        pendingLock.lock()
        defer { pendingLock.unlock() }
        
        guard let delivery = pendingDeliveries[messageID] else { return nil }
        
        if delivery.isChannelMessage {
            let deliveryRatio = Double(delivery.ackedBy.count) / Double(delivery.expectedRecipients)
            if deliveryRatio >= 1.0 {
                return .delivered
            } else if deliveryRatio >= 0.5 {
                return .partiallyDelivered
            } else if delivery.retryCount > 0 {
                return .retrying
            } else {
                return .sent
            }
        } else {
            if delivery.retryCount > 0 {
                return .retrying
            } else {
                return .sent
            }
        }
    }
}

// MARK: - Supporting Types

struct DeliveryAck: Codable {
    let id: String
    let messageID: String
    let senderID: String
    let senderNickname: String
    let timestamp: Date
}

struct ReadReceipt: Codable {
    let id: String
    let messageID: String
    let readerID: String
    let readerNickname: String
    let timestamp: Date
}