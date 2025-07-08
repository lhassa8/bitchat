//
// NetworkHealthView.swift
// bitchat
//
// This is free and unencumbered software released into the public domain.
// For more information, see <https://unlicense.org>
//

import SwiftUI

struct NetworkHealthView: View {
    @EnvironmentObject var viewModel: ChatViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var showDetails = false
    
    private var textColor: Color {
        colorScheme == .dark ? Color.green : Color(red: 0, green: 0.5, blue: 0)
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black : Color.white
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Compact health indicator
            HStack(spacing: 8) {
                // Health status indicator
                HStack(spacing: 4) {
                    Text(viewModel.networkHealth.emoji)
                        .font(.system(size: 12))
                    
                    Text(viewModel.networkHealth.displayName)
                        .font(.system(size: 11, family: .monospaced))
                        .foregroundColor(textColor.opacity(0.8))
                }
                
                Spacer()
                
                // Peer count
                HStack(spacing: 2) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 10))
                        .foregroundColor(textColor.opacity(0.6))
                    
                    Text("\(viewModel.networkMetrics.connectedPeers)")
                        .font(.system(size: 11, family: .monospaced))
                        .foregroundColor(textColor.opacity(0.8))
                }
                
                // Queued messages indicator
                if viewModel.queuedMessageCount > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "tray.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.orange)
                        
                        Text("\(viewModel.queuedMessageCount)")
                            .font(.system(size: 11, family: .monospaced))
                            .foregroundColor(.orange)
                    }
                }
                
                // Signal strength indicator
                SignalStrengthView(rssi: viewModel.networkMetrics.averageRSSI)
                
                // Expand/collapse button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showDetails.toggle()
                    }
                }) {
                    Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10))
                        .foregroundColor(textColor.opacity(0.6))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(backgroundColor.opacity(0.8))
            
            // Detailed health information
            if showDetails {
                VStack(spacing: 8) {
                    Divider()
                        .background(textColor.opacity(0.3))
                    
                    // Metrics grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 8) {
                        MetricView(
                            title: "Delivery Rate",
                            value: String(format: "%.1f%%", viewModel.networkMetrics.messageDeliveryRate * 100),
                            icon: "checkmark.circle.fill",
                            color: deliveryRateColor
                        )
                        
                        MetricView(
                            title: "Avg RSSI",
                            value: String(format: "%.0f dBm", viewModel.networkMetrics.averageRSSI),
                            icon: "antenna.radiowaves.left.and.right",
                            color: rssiColor
                        )
                        
                        if let latency = viewModel.networkMetrics.networkLatency {
                            MetricView(
                                title: "Latency",
                                value: String(format: "%.0f ms", latency * 1000),
                                icon: "timer",
                                color: latencyColor(latency)
                            )
                        }
                        
                        MetricView(
                            title: "Failed",
                            value: "\(viewModel.networkMetrics.failedMessages)",
                            icon: "xmark.circle.fill",
                            color: .red
                        )
                    }
                    .padding(.horizontal, 12)
                    
                    // Health recommendations
                    if !healthRecommendations.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Recommendations:")
                                .font(.system(size: 11, family: .monospaced, weight: .semibold))
                                .foregroundColor(textColor.opacity(0.8))
                            
                            ForEach(healthRecommendations.prefix(2), id: \.self) { recommendation in
                                Text("• \(recommendation)")
                                    .font(.system(size: 10, family: .monospaced))
                                    .foregroundColor(textColor.opacity(0.6))
                                    .multilineTextAlignment(.leading)
                            }
                        }
                        .padding(.horizontal, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.bottom, 8)
                .background(backgroundColor.opacity(0.8))
            }
        }
        .background(backgroundColor.opacity(0.9))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(textColor.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var deliveryRateColor: Color {
        let rate = viewModel.networkMetrics.messageDeliveryRate
        if rate >= 0.9 { return .green }
        else if rate >= 0.7 { return .yellow }
        else { return .red }
    }
    
    private var rssiColor: Color {
        let rssi = viewModel.networkMetrics.averageRSSI
        if rssi >= -50 { return .green }
        else if rssi >= -70 { return .yellow }
        else { return .red }
    }
    
    private func latencyColor(_ latency: TimeInterval) -> Color {
        if latency <= 0.1 { return .green }
        else if latency <= 0.5 { return .yellow }
        else { return .red }
    }
    
    private var healthRecommendations: [String] {
        NetworkHealthMonitor.shared.getDetailedReport().recommendations
    }
}

struct SignalStrengthView: View {
    let rssi: Double
    @Environment(\.colorScheme) var colorScheme
    
    private var textColor: Color {
        colorScheme == .dark ? Color.green : Color(red: 0, green: 0.5, blue: 0)
    }
    
    private var signalStrength: Int {
        // Convert RSSI to 0-4 bars
        if rssi >= -50 { return 4 }
        else if rssi >= -60 { return 3 }
        else if rssi >= -70 { return 2 }
        else if rssi >= -80 { return 1 }
        else { return 0 }
    }
    
    private var signalColor: Color {
        switch signalStrength {
        case 4: return .green
        case 3: return .green
        case 2: return .yellow
        case 1: return .orange
        default: return .red
        }
    }
    
    var body: some View {
        HStack(spacing: 1) {
            ForEach(0..<4, id: \.self) { index in
                Rectangle()
                    .fill(index < signalStrength ? signalColor : textColor.opacity(0.2))
                    .frame(width: 2, height: CGFloat(4 + index * 2))
            }
        }
        .frame(width: 12, height: 10)
    }
}

struct MetricView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    @Environment(\.colorScheme) var colorScheme
    
    private var textColor: Color {
        colorScheme == .dark ? Color.green : Color(red: 0, green: 0.5, blue: 0)
    }
    
    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 9, family: .monospaced))
                    .foregroundColor(textColor.opacity(0.6))
            }
            
            Text(value)
                .font(.system(size: 11, family: .monospaced, weight: .semibold))
                .foregroundColor(textColor.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .background(color.opacity(0.1))
        .cornerRadius(4)
    }
}

#Preview {
    NetworkHealthView()
        .environmentObject(ChatViewModel())
        .padding()
}
