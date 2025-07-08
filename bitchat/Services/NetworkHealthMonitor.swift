//
// NetworkHealthMonitor.swift
// bitchat
//
// This is free and unencumbered software released into the public domain.
// For more information, see <https://unlicense.org>
//

import Foundation
import Combine
import CoreBluetooth

enum NetworkHealthStatus {
    case excellent
    case good
    case fair
    case poor
    case disconnected
    
    var displayName: String {
        switch self {
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .fair: return "Fair"
        case .poor: return "Poor"
        case .disconnected: return "Disconnected"
        }
    }
    
    var emoji: String {
        switch self {
        case .excellent: return "🟢"
        case .good: return "🟡"
        case .fair: return "🟠"
        case .poor: return "🔴"
        case .disconnected: return "⚫"
        }
    }
    
    var color: String {
        switch self {
        case .excellent: return "green"
        case .good: return "yellow"
        case .fair: return "orange"
        case .poor: return "red"
        case .disconnected: return "gray"
        }
    }
}

struct NetworkHealthMetrics {
    let connectedPeers: Int
    let averageRSSI: Double
    let messageDeliveryRate: Double
    let bluetoothState: CBManagerState
    let lastMessageTime: Date?
    let networkLatency: TimeInterval?
    let queuedMessages: Int
    let failedMessages: Int
    let retryRate: Double
    
    var healthScore: Double {
        var score: Double = 0
        
        // Peer connectivity (40% of score)
        let peerScore = min(Double(connectedPeers) / 5.0, 1.0) * 0.4
        score += peerScore
        
        // Signal strength (25% of score)
        let rssiScore = max(0, (averageRSSI + 100) / 50.0) * 0.25
        score += rssiScore
        
        // Message delivery (25% of score)
        score += messageDeliveryRate * 0.25
        
        // Queue health (10% of score)
        let queueScore = max(0, 1.0 - (Double(queuedMessages) / 100.0)) * 0.1
        score += queueScore
        
        return min(score, 1.0)
    }
    
    var status: NetworkHealthStatus {
        if bluetoothState != .poweredOn {
            return .disconnected
        }
        
        if connectedPeers == 0 {
            return .disconnected
        }
        
        let score = healthScore
        
        if score >= 0.8 {
            return .excellent
        } else if score >= 0.6 {
            return .good
        } else if score >= 0.4 {
            return .fair
        } else {
            return .poor
        }
    }
}

class NetworkHealthMonitor {
    static let shared = NetworkHealthMonitor()
    
    // Health metrics
    @Published var currentMetrics = NetworkHealthMetrics(
        connectedPeers: 0,
        averageRSSI: -100,
        messageDeliveryRate: 0,
        bluetoothState: .unknown,
        lastMessageTime: nil,
        networkLatency: nil,
        queuedMessages: 0,
        failedMessages: 0,
        retryRate: 0
    )
    
    // Historical data for trends
    private var rssiHistory: [Double] = []
    private var deliveryHistory: [Bool] = []
    private var latencyHistory: [TimeInterval] = []
    private var peerCountHistory: [Int] = []
    
    // Tracking variables
    private var totalMessagesSent: Int = 0
    private var totalMessagesDelivered: Int = 0
    private var totalMessagesFailed: Int = 0
    private var totalRetries: Int = 0
    
    // Timers
    private var updateTimer: Timer?
    private var latencyTimer: Timer?
    
    // Publishers
    let healthStatusChanged = PassthroughSubject<NetworkHealthStatus, Never>()
    let metricsUpdated = PassthroughSubject<NetworkHealthMetrics, Never>()
    
    // Weak references
    weak var meshService: BluetoothMeshService?
    weak var deliveryTracker: DeliveryTracker?
    weak var offlineQueue: OfflineMessageQueue?
    
    private init() {
        startMonitoring()
        setupSubscriptions()
    }
    
    deinit {
        updateTimer?.invalidate()
        latencyTimer?.invalidate()
    }
    
    // MARK: - Public Methods
    
    func recordMessageSent() {
        totalMessagesSent += 1
        updateMetrics()
    }
    
    func recordMessageDelivered() {
        totalMessagesDelivered += 1
        deliveryHistory.append(true)
        if deliveryHistory.count > 100 {
            deliveryHistory.removeFirst()
        }
        updateMetrics()
    }
    
    func recordMessageFailed() {
        totalMessagesFailed += 1
        deliveryHistory.append(false)
        if deliveryHistory.count > 100 {
            deliveryHistory.removeFirst()
        }
        updateMetrics()
    }
    
    func recordRetry() {
        totalRetries += 1
        updateMetrics()
    }
    
    func recordRSSI(_ rssi: Double) {
        rssiHistory.append(rssi)
        if rssiHistory.count > 50 {
            rssiHistory.removeFirst()
        }
        updateMetrics()
    }
    
    func recordLatency(_ latency: TimeInterval) {
        latencyHistory.append(latency)
        if latencyHistory.count > 20 {
            latencyHistory.removeFirst()
        }
        updateMetrics()
    }
    
    func updateBluetoothState(_ state: CBManagerState) {
        let previousStatus = currentMetrics.status
        
        var newMetrics = currentMetrics
        newMetrics.bluetoothState = state
        currentMetrics = newMetrics
        
        let newStatus = currentMetrics.status
        if newStatus != previousStatus {
            healthStatusChanged.send(newStatus)
        }
        
        metricsUpdated.send(currentMetrics)
    }
    
    func updatePeerCount(_ count: Int) {
        peerCountHistory.append(count)
        if peerCountHistory.count > 50 {
            peerCountHistory.removeFirst()
        }
        updateMetrics()
    }
    
    func getHealthTrend() -> HealthTrend {
        guard peerCountHistory.count >= 10 else { return .stable }
        
        let recent = Array(peerCountHistory.suffix(5))
        let older = Array(peerCountHistory.suffix(10).prefix(5))
        
        let recentAvg = recent.reduce(0, +) / recent.count
        let olderAvg = older.reduce(0, +) / older.count
        
        let difference = Double(recentAvg - olderAvg)
        
        if difference > 1 {
            return .improving
        } else if difference < -1 {
            return .declining
        } else {
            return .stable
        }
    }
    
    func getDetailedReport() -> NetworkHealthReport {
        return NetworkHealthReport(
            metrics: currentMetrics,
            trend: getHealthTrend(),
            recommendations: generateRecommendations(),
            historicalData: HistoricalData(
                rssiHistory: rssiHistory,
                deliveryHistory: deliveryHistory,
                latencyHistory: latencyHistory,
                peerCountHistory: peerCountHistory
            )
        )
    }
    
    // MARK: - Private Methods
    
    private func startMonitoring() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.updateMetrics()
        }
        
        latencyTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.measureNetworkLatency()
        }
    }
    
    private func setupSubscriptions() {
        // Subscribe to delivery tracker updates
        DeliveryTracker.shared.deliveryStatusUpdated
            .sink { [weak self] (messageID, status) in
                switch status {
                case .delivered:
                    self?.recordMessageDelivered()
                case .failed:
                    self?.recordMessageFailed()
                case .retrying:
                    self?.recordRetry()
                default:
                    break
                }
            }
            .store(in: &cancellables)
        
        // Subscribe to offline queue updates
        OfflineMessageQueue.shared.queueSizeChanged
            .sink { [weak self] size in
                self?.updateQueuedMessages(size)
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    private func updateMetrics() {
        let connectedPeers = meshService?.getAllConnectedPeerIDs().count ?? 0
        let averageRSSI = rssiHistory.isEmpty ? -100 : rssiHistory.reduce(0, +) / Double(rssiHistory.count)
        let deliveryRate = deliveryHistory.isEmpty ? 0 : Double(deliveryHistory.filter { $0 }.count) / Double(deliveryHistory.count)
        let queuedMessages = offlineQueue?.getQueueStatistics().totalMessages ?? 0
        let retryRate = totalMessagesSent > 0 ? Double(totalRetries) / Double(totalMessagesSent) : 0
        let averageLatency = latencyHistory.isEmpty ? nil : latencyHistory.reduce(0, +) / Double(latencyHistory.count)
        
        let previousStatus = currentMetrics.status
        
        currentMetrics = NetworkHealthMetrics(
            connectedPeers: connectedPeers,
            averageRSSI: averageRSSI,
            messageDeliveryRate: deliveryRate,
            bluetoothState: currentMetrics.bluetoothState,
            lastMessageTime: currentMetrics.lastMessageTime,
            networkLatency: averageLatency,
            queuedMessages: queuedMessages,
            failedMessages: totalMessagesFailed,
            retryRate: retryRate
        )
        
        let newStatus = currentMetrics.status
        if newStatus != previousStatus {
            healthStatusChanged.send(newStatus)
        }
        
        metricsUpdated.send(currentMetrics)
    }
    
    private func updateQueuedMessages(_ count: Int) {
        var newMetrics = currentMetrics
        newMetrics.queuedMessages = count
        currentMetrics = newMetrics
        metricsUpdated.send(currentMetrics)
    }
    
    private func measureNetworkLatency() {
        // Simple ping-like measurement by sending a small test message
        // and measuring round-trip time
        guard let meshService = meshService,
              !meshService.getAllConnectedPeerIDs().isEmpty else { return }
        
        let startTime = Date()
        
        // Send a small test packet and measure response time
        // This would need to be implemented in the mesh service
        // For now, we'll simulate based on RSSI
        let simulatedLatency = max(0.1, (-averageRSSI - 50) / 100.0)
        recordLatency(simulatedLatency)
    }
    
    private var averageRSSI: Double {
        return rssiHistory.isEmpty ? -100 : rssiHistory.reduce(0, +) / Double(rssiHistory.count)
    }
    
    private func generateRecommendations() -> [String] {
        var recommendations: [String] = []
        
        if currentMetrics.connectedPeers == 0 {
            recommendations.append("No peers connected. Move closer to other bitchat users.")
        } else if currentMetrics.connectedPeers < 3 {
            recommendations.append("Low peer count. Consider moving to a more populated area.")
        }
        
        if currentMetrics.averageRSSI < -80 {
            recommendations.append("Weak signal strength. Move closer to other users or reduce interference.")
        }
        
        if currentMetrics.messageDeliveryRate < 0.7 {
            recommendations.append("Low message delivery rate. Check Bluetooth settings and reduce interference.")
        }
        
        if currentMetrics.queuedMessages > 50 {
            recommendations.append("High number of queued messages. Network congestion detected.")
        }
        
        if currentMetrics.retryRate > 0.3 {
            recommendations.append("High retry rate. Consider moving to improve connectivity.")
        }
        
        if currentMetrics.bluetoothState != .poweredOn {
            recommendations.append("Bluetooth is not enabled. Please turn on Bluetooth to connect.")
        }
        
        if recommendations.isEmpty {
            recommendations.append("Network health is good. No issues detected.")
        }
        
        return recommendations
    }
}

// MARK: - Supporting Types

enum HealthTrend {
    case improving
    case stable
    case declining
    
    var displayName: String {
        switch self {
        case .improving: return "Improving"
        case .stable: return "Stable"
        case .declining: return "Declining"
        }
    }
    
    var emoji: String {
        switch self {
        case .improving: return "📈"
        case .stable: return "➡️"
        case .declining: return "📉"
        }
    }
}

struct NetworkHealthReport {
    let metrics: NetworkHealthMetrics
    let trend: HealthTrend
    let recommendations: [String]
    let historicalData: HistoricalData
}

struct HistoricalData {
    let rssiHistory: [Double]
    let deliveryHistory: [Bool]
    let latencyHistory: [TimeInterval]
    let peerCountHistory: [Int]
}
