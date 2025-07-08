//
// OfflineMessageQueue.swift
// bitchat
//
// This is free and unencumbered software released into the public domain.
// For more information, see <https://unlicense.org>
//

import Foundation
import Combine

struct QueuedMessage {
    let id: String
    let message: BitchatMessage
    let recipientID: String
    let recipientNickname: String
    let queuedAt: Date
    let priority: MessagePriority
    let retryCount: Int
    let maxRetries: Int
    
    enum MessagePriority: Int, CaseIterable {
        case low = 0
        case normal = 1
        case high = 2
        case urgent = 3
        
        var displayName: String {
            switch self {
            case .low: return "Low"
            case .normal: return "Normal"
            case .high: return "High"
            case .urgent: return "Urgent"
            }
        }
    }
    
    var isExpired: Bool {
        let maxAge: TimeInterval = priority == .urgent ? 3600 : 1800 // 1 hour for urgent, 30 min for others
        return Date().timeIntervalSince(queuedAt) > maxAge
    }
    
    var shouldRetry: Bool {
        return retryCount < maxRetries && !isExpired
    }
}

class OfflineMessageQueue {
    static let shared = OfflineMessageQueue()
    
    // Queue configuration
    private let maxQueueSize = 500
    private let maxMessageAge: TimeInterval = 3600 // 1 hour
    private let maxFavoriteMessageAge: TimeInterval = 86400 // 24 hours for favorites
    
    // Message queues by priority
    private var urgentQueue: [QueuedMessage] = []
    private var highQueue: [QueuedMessage] = []
    private var normalQueue: [QueuedMessage] = []
    private var lowQueue: [QueuedMessage] = []
    
    // Thread safety
    private let queueLock = NSLock()
    
    // Cleanup timer
    private var cleanupTimer: Timer?
    
    // Publishers for UI updates
    let queueSizeChanged = PassthroughSubject<Int, Never>()
    let messageQueued = PassthroughSubject<QueuedMessage, Never>()
    let messageDequeued = PassthroughSubject<String, Never>()
    
    // Weak reference to mesh service
    weak var meshService: BluetoothMeshService?
    
    private init() {
        startCleanupTimer()
    }
    
    deinit {
        cleanupTimer?.invalidate()
    }
    
    // MARK: - Public Methods
    
    func queueMessage(_ message: BitchatMessage, recipientID: String, recipientNickname: String, priority: QueuedMessage.MessagePriority = .normal, isFavorite: Bool = false) {
        queueLock.lock()
        defer { queueLock.unlock() }
        
        // Check if we're at capacity
        let currentSize = getTotalQueueSize()
        if currentSize >= maxQueueSize {
            // Remove oldest low priority messages to make room
            removeOldestLowPriorityMessages(count: 10)
        }
        
        let queuedMessage = QueuedMessage(
            id: UUID().uuidString,
            message: message,
            recipientID: recipientID,
            recipientNickname: recipientNickname,
            queuedAt: Date(),
            priority: priority,
            retryCount: 0,
            maxRetries: isFavorite ? 5 : 3
        )
        
        // Add to appropriate queue
        switch priority {
        case .urgent:
            urgentQueue.append(queuedMessage)
        case .high:
            highQueue.append(queuedMessage)
        case .normal:
            normalQueue.append(queuedMessage)
        case .low:
            lowQueue.append(queuedMessage)
        }
        
        // Sort queues by timestamp (oldest first)
        sortQueues()
        
        // Notify observers
        DispatchQueue.main.async { [weak self] in
            self?.queueSizeChanged.send(currentSize + 1)
            self?.messageQueued.send(queuedMessage)
        }
        
        print("[OfflineQueue] Queued message for \(recipientNickname) (priority: \(priority.displayName), queue size: \(currentSize + 1))")
    }
    
    func dequeueMessagesForPeer(_ peerID: String) -> [QueuedMessage] {
        queueLock.lock()
        defer { queueLock.unlock() }
        
        var dequeuedMessages: [QueuedMessage] = []
        
        // Dequeue from all priority queues
        let allQueues = [urgentQueue, highQueue, normalQueue, lowQueue]
        var newQueues: [[QueuedMessage]] = []
        
        for queue in allQueues {
            let (remaining, dequeued) = queue.partition { $0.recipientID != peerID }
            newQueues.append(Array(remaining))
            dequeuedMessages.append(contentsOf: dequeued)
        }
        
        // Update queues
        urgentQueue = newQueues[0]
        highQueue = newQueues[1]
        normalQueue = newQueues[2]
        lowQueue = newQueues[3]
        
        // Sort by priority and timestamp
        dequeuedMessages.sort { lhs, rhs in
            if lhs.priority.rawValue != rhs.priority.rawValue {
                return lhs.priority.rawValue > rhs.priority.rawValue
            }
            return lhs.queuedAt < rhs.queuedAt
        }
        
        // Notify observers
        let newSize = getTotalQueueSize()
        DispatchQueue.main.async { [weak self] in
            self?.queueSizeChanged.send(newSize)
            for message in dequeuedMessages {
                self?.messageDequeued.send(message.id)
            }
        }
        
        if !dequeuedMessages.isEmpty {
            print("[OfflineQueue] Dequeued \(dequeuedMessages.count) messages for peer \(peerID)")
        }
        
        return dequeuedMessages
    }
    
    func getQueuedMessagesForPeer(_ peerID: String) -> [QueuedMessage] {
        queueLock.lock()
        defer { queueLock.unlock() }
        
        let allMessages = urgentQueue + highQueue + normalQueue + lowQueue
        return allMessages.filter { $0.recipientID == peerID }
    }
    
    func getQueueStatistics() -> QueueStatistics {
        queueLock.lock()
        defer { queueLock.unlock() }
        
        return QueueStatistics(
            totalMessages: getTotalQueueSize(),
            urgentCount: urgentQueue.count,
            highCount: highQueue.count,
            normalCount: normalQueue.count,
            lowCount: lowQueue.count,
            oldestMessageAge: getOldestMessageAge(),
            averageMessageAge: getAverageMessageAge(),
            uniqueRecipients: getUniqueRecipientCount()
        )
    }
    
    func clearQueue() {
        queueLock.lock()
        defer { queueLock.unlock() }
        
        urgentQueue.removeAll()
        highQueue.removeAll()
        normalQueue.removeAll()
        lowQueue.removeAll()
        
        DispatchQueue.main.async { [weak self] in
            self?.queueSizeChanged.send(0)
        }
        
        print("[OfflineQueue] Queue cleared")
    }
    
    func clearQueueForPeer(_ peerID: String) {
        queueLock.lock()
        defer { queueLock.unlock() }
        
        let originalSize = getTotalQueueSize()
        
        urgentQueue.removeAll { $0.recipientID == peerID }
        highQueue.removeAll { $0.recipientID == peerID }
        normalQueue.removeAll { $0.recipientID == peerID }
        lowQueue.removeAll { $0.recipientID == peerID }
        
        let newSize = getTotalQueueSize()
        let removedCount = originalSize - newSize
        
        if removedCount > 0 {
            DispatchQueue.main.async { [weak self] in
                self?.queueSizeChanged.send(newSize)
            }
            
            print("[OfflineQueue] Cleared \(removedCount) messages for peer \(peerID)")
        }
    }
    
    func processQueue() {
        guard let meshService = meshService else { return }
        
        queueLock.lock()
        let connectedPeers = Set(meshService.getAllConnectedPeerIDs())
        queueLock.unlock()
        
        for peerID in connectedPeers {
            let messages = dequeueMessagesForPeer(peerID)
            
            for queuedMessage in messages {
                // Send the message
                if queuedMessage.message.isPrivate {
                    meshService.sendPrivateMessage(
                        queuedMessage.message.content,
                        to: queuedMessage.recipientID,
                        recipientNickname: queuedMessage.recipientNickname
                    )
                } else if let channel = queuedMessage.message.channel {
                    meshService.sendMessage(
                        queuedMessage.message.content,
                        mentions: queuedMessage.message.mentions,
                        channel: channel
                    )
                }
                
                // Small delay between messages to avoid overwhelming
                Thread.sleep(forTimeInterval: 0.1)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func getTotalQueueSize() -> Int {
        return urgentQueue.count + highQueue.count + normalQueue.count + lowQueue.count
    }
    
    private func sortQueues() {
        urgentQueue.sort { $0.queuedAt < $1.queuedAt }
        highQueue.sort { $0.queuedAt < $1.queuedAt }
        normalQueue.sort { $0.queuedAt < $1.queuedAt }
        lowQueue.sort { $0.queuedAt < $1.queuedAt }
    }
    
    private func removeOldestLowPriorityMessages(count: Int) {
        let toRemove = min(count, lowQueue.count)
        if toRemove > 0 {
            lowQueue.removeFirst(toRemove)
            print("[OfflineQueue] Removed \(toRemove) old low-priority messages to make room")
        }
        
        // If still need more room, remove from normal priority
        let stillNeed = count - toRemove
        if stillNeed > 0 {
            let normalToRemove = min(stillNeed, normalQueue.count)
            if normalToRemove > 0 {
                normalQueue.removeFirst(normalToRemove)
                print("[OfflineQueue] Removed \(normalToRemove) old normal-priority messages to make room")
            }
        }
    }
    
    private func getOldestMessageAge() -> TimeInterval? {
        let allMessages = urgentQueue + highQueue + normalQueue + lowQueue
        guard let oldest = allMessages.min(by: { $0.queuedAt < $1.queuedAt }) else { return nil }
        return Date().timeIntervalSince(oldest.queuedAt)
    }
    
    private func getAverageMessageAge() -> TimeInterval {
        let allMessages = urgentQueue + highQueue + normalQueue + lowQueue
        guard !allMessages.isEmpty else { return 0 }
        
        let totalAge = allMessages.reduce(0) { sum, message in
            sum + Date().timeIntervalSince(message.queuedAt)
        }
        
        return totalAge / Double(allMessages.count)
    }
    
    private func getUniqueRecipientCount() -> Int {
        let allMessages = urgentQueue + highQueue + normalQueue + lowQueue
        let uniqueRecipients = Set(allMessages.map { $0.recipientID })
        return uniqueRecipients.count
    }
    
    private func startCleanupTimer() {
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.cleanupExpiredMessages()
        }
    }
    
    private func cleanupExpiredMessages() {
        queueLock.lock()
        defer { queueLock.unlock() }
        
        let originalSize = getTotalQueueSize()
        
        urgentQueue.removeAll { $0.isExpired }
        highQueue.removeAll { $0.isExpired }
        normalQueue.removeAll { $0.isExpired }
        lowQueue.removeAll { $0.isExpired }
        
        let newSize = getTotalQueueSize()
        let removedCount = originalSize - newSize
        
        if removedCount > 0 {
            DispatchQueue.main.async { [weak self] in
                self?.queueSizeChanged.send(newSize)
            }
            
            print("[OfflineQueue] Cleaned up \(removedCount) expired messages")
        }
    }
}

// MARK: - Supporting Types

struct QueueStatistics {
    let totalMessages: Int
    let urgentCount: Int
    let highCount: Int
    let normalCount: Int
    let lowCount: Int
    let oldestMessageAge: TimeInterval?
    let averageMessageAge: TimeInterval
    let uniqueRecipients: Int
    
    var formattedOldestAge: String {
        guard let age = oldestMessageAge else { return "N/A" }
        return formatTimeInterval(age)
    }
    
    var formattedAverageAge: String {
        return formatTimeInterval(averageMessageAge)
    }
    
    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
}

// Extension to help with partitioning arrays
extension Array {
    func partition(by predicate: (Element) -> Bool) -> (matching: [Element], nonMatching: [Element]) {
        var matching: [Element] = []
        var nonMatching: [Element] = []
        
        for element in self {
            if predicate(element) {
                matching.append(element)
            } else {
                nonMatching.append(element)
            }
        }
        
        return (matching, nonMatching)
    }
}
