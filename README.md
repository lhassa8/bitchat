# bitchat

![bitchat Logo](https://github.com/user-attachments/assets/2660f828-49c7-444d-beca-d8b01854667a)

A secure, decentralized, peer-to-peer messaging app that works over Bluetooth mesh networks. No internet required, no servers, no phone numbers - just pure encrypted communication.

[![Swift](https://img.shields.io/badge/Swift-5.0-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20macOS-lightgrey.svg)](https://developer.apple.com)
[![License](https://img.shields.io/badge/License-Public%20Domain-blue.svg)](LICENSE)

## 🚀 Features

### Core Functionality
- **🌐 Decentralized Mesh Network**: Automatic peer discovery and multi-hop message relay over Bluetooth LE
- **🔐 End-to-End Encryption**: X25519 key exchange + AES-256-GCM for private messages
- **📢 Channel-Based Chats**: Topic-based group messaging with optional password protection
- **📦 Store & Forward**: Messages cached for offline peers and delivered when they reconnect
- **🔒 Privacy First**: No accounts, no phone numbers, no persistent identifiers
- **💬 IRC-Style Commands**: Familiar `/join`, `/msg`, `/who` style interface

### Advanced Features
- **📱 Universal App**: Native support for iOS and macOS
- **🎭 Cover Traffic**: Timing obfuscation and dummy messages for enhanced privacy
- **🚨 Emergency Wipe**: Triple-tap to instantly clear all data
- **⚡ Performance Optimizations**: LZ4 message compression, adaptive battery modes
- **✅ Message Delivery**: Confirmations with intelligent retry logic
- **📋 Offline Queuing**: Messages queued when recipients are offline
- **📊 Network Health**: Real-time connection quality indicators

## 🛠 Setup

### Prerequisites
- Xcode 15.0 or later
- iOS 16.0+ / macOS 13.0+
- Bluetooth LE capable device

### Option 1: Using XcodeGen (Recommended)

1. **Install XcodeGen**:
   ```bash
   brew install xcodegen
   ```

2. **Clone and setup**:
   ```bash
   git clone https://github.com/lhassa8/bitchat.git
   cd bitchat
   xcodegen generate
   ```

3. **Open project**:
   ```bash
   open bitchat.xcodeproj
   ```

### Option 2: Using Swift Package Manager

1. **Clone repository**:
   ```bash
   git clone https://github.com/lhassa8/bitchat.git
   cd bitchat
   ```

2. **Open in Xcode**:
   ```bash
   open Package.swift
   ```

3. Select your target device and run

### Option 3: Manual Xcode Project

1. Open Xcode and create a new iOS/macOS App
2. Copy all Swift files from the `bitchat` directory into your project
3. Update Info.plist with Bluetooth permissions
4. Set deployment target to iOS 16.0 / macOS 13.0

## 📱 Usage

### Getting Started

1. **Launch bitchat** on your device
2. **Set your nickname** (or use the auto-generated one)
3. **Auto-connect** to nearby peers
4. **Join a channel** with `/j #general` or start chatting in public
5. **Messages relay** through the mesh network to reach distant peers

### Basic Commands

| Command | Description |
|---------|-------------|
| `/j #channel` | Join or create a channel |
| `/m @name message` | Send a private message |
| `/w` | List online users |
| `/channels` | Show all discovered channels |
| `/block @name` | Block a peer from messaging you |
| `/unblock @name` | Unblock a peer |
| `/clear` | Clear chat messages |
| `/pass [password]` | Set/change channel password (owner only) |
| `/transfer @name` | Transfer channel ownership |
| `/save` | Toggle message retention for channel (owner only) |

### Channel Features

- **🔐 Password Protection**: Channel owners can set passwords with `/pass`
- **💾 Message Retention**: Owners can enable mandatory message saving with `/save`
- **👤 @ Mentions**: Use `@nickname` to mention users (with autocomplete)
- **👑 Ownership Transfer**: Pass control to trusted users with `/transfer`

## 🔒 Security & Privacy

### Encryption
- **Private Messages**: X25519 key exchange + AES-256-GCM encryption
- **Channel Messages**: Argon2id password derivation + AES-256-GCM
- **Digital Signatures**: Ed25519 for message authenticity
- **Forward Secrecy**: New key pairs generated each session

### Privacy Features
- **No Registration**: No accounts, emails, or phone numbers required
- **Ephemeral by Default**: Messages exist only in device memory
- **Cover Traffic**: Random delays and dummy messages prevent traffic analysis
- **Emergency Wipe**: Triple-tap logo to instantly clear all data
- **Local-First**: Works completely offline, no servers involved

## ⚡ Performance & Efficiency

### Message Compression
- **LZ4 Compression**: Automatic compression for messages >100 bytes
- **30-70% bandwidth savings** on typical text messages
- **Smart compression**: Skips already-compressed data

### Battery Optimization
- **Adaptive Power Modes**: Automatically adjusts based on battery level
  - Performance mode: Full features when charging or >60% battery
  - Balanced mode: Default operation (30-60% battery)
  - Power saver: Reduced scanning when <30% battery
  - Ultra-low power: Emergency mode when <10% battery
- **Background efficiency**: Automatic power saving when app backgrounded
- **Configurable scanning**: Duty cycle adapts to battery state

### Network Efficiency
- **Optimized Bloom filters**: Faster duplicate detection with less memory
- **Message aggregation**: Batches small messages to reduce transmissions
- **Adaptive connection limits**: Adjusts peer connections based on power mode

## 🏗 Technical Architecture

### Binary Protocol
bitchat uses an efficient binary protocol optimized for Bluetooth LE:
- Compact packet format with 1-byte type field
- TTL-based message routing (max 7 hops)
- Automatic fragmentation for large messages
- Message deduplication via unique IDs

### Mesh Networking
- Each device acts as both client and peripheral
- Automatic peer discovery and connection management
- Store-and-forward for offline message delivery
- Adaptive duty cycling for battery optimization

### Reliability Features
- **Message Delivery Confirmations**: Track delivery status with retry logic
- **Offline Message Queuing**: Queue messages when recipients are offline
- **Network Health Monitoring**: Real-time connection quality indicators
- **Automatic Recovery**: Bluetooth state recovery and reconnection

For detailed protocol documentation, see the [Technical Whitepaper](WHITEPAPER.md).

## 📊 Network Health

bitchat includes comprehensive network health monitoring:

- **🟢 Excellent**: Optimal performance, strong connections
- **🟡 Good**: Good performance with minor issues
- **🟠 Fair**: Acceptable performance with some problems
- **🔴 Poor**: Significant connectivity issues
- **⚫ Disconnected**: No Bluetooth or peers

The health indicator provides real-time feedback and actionable recommendations for improving connectivity.

## 🔧 Building for Production

1. Set your development team in project settings
2. Configure code signing
3. Archive and distribute through App Store or TestFlight

## 🤖 Android Compatibility

The protocol is designed to be platform-agnostic. An Android client can be built using:
- Bluetooth LE APIs
- Same packet structure and encryption
- Compatible service/characteristic UUIDs

## 🛣 Roadmap

### Planned Features
- **WiFi Direct Integration**: Higher bandwidth alternative transport
- **Voice Messages**: Audio message support
- **File Sharing**: Secure file transfer over mesh
- **Group Voice Chat**: Real-time voice communication
- **Advanced Routing**: Improved mesh routing algorithms

### Transport Expansion
- **WiFi Direct**: 250+ Mbps, 100-200m range
- **Ultrasonic**: Covert communication through sound
- **LoRa**: Long-range, low-power communication
- **USB-C Direct**: Ultra-high bandwidth peer connections

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Development Setup
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

### Areas for Contribution
- Protocol improvements
- UI/UX enhancements
- Platform ports (Android, Linux, Windows)
- Documentation improvements
- Security audits

## 📄 License

This project is released into the **public domain**. See the [LICENSE](LICENSE) file for details.

You are free to:
- Use the code for any purpose
- Modify and distribute
- Create commercial applications
- No attribution required (but appreciated!)

## 🙏 Acknowledgments

- Built with Swift and SwiftUI
- Uses CryptoKit for encryption
- Inspired by IRC and mesh networking protocols
- Thanks to the open source community

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/lhassa8/bitchat/issues)
- **Discussions**: [GitHub Discussions](https://github.com/lhassa8/bitchat/discussions)
- **Security**: For security issues, please email privately

## 🏷 Tags

`bluetooth` `mesh-networking` `privacy` `encryption` `decentralized` `p2p` `messaging` `ios` `macos` `swift` `offline-first` `no-servers`

---

**bitchat** - Secure mesh communication for the modern world 🌐🔒
