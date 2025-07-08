# Changelog

All notable changes to bitchat will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Comprehensive reliability features
- Network health monitoring and indicators
- Message delivery confirmations with retry logic
- Offline message queuing with size limits
- Automatic Bluetooth state recovery
- Enhanced documentation and GitHub setup

## [1.0.0] - 2025-01-08

### Added
- **Core Messaging Features**
  - Bluetooth LE mesh networking with automatic peer discovery
  - End-to-end encryption using X25519 key exchange + AES-256-GCM
  - Channel-based group messaging with IRC-style commands
  - Private messaging with encryption
  - Store & forward message delivery for offline peers
  - Message deduplication and TTL-based routing

- **Security & Privacy**
  - No registration, accounts, or phone numbers required
  - Ephemeral peer IDs generated each session
  - Forward secrecy with new key pairs per session
  - Digital signatures using Ed25519
  - Password-protected channels with Argon2id key derivation
  - Emergency wipe feature (triple-tap logo)
  - Cover traffic for timing obfuscation

- **User Interface**
  - Universal iOS and macOS app
  - SwiftUI-based modern interface
  - Dark/light mode support
  - @ mention autocomplete
  - Channel management and discovery
  - Peer blocking and favorites system
  - Message retention controls

- **Performance & Efficiency**
  - LZ4 message compression (30-70% bandwidth savings)
  - Adaptive battery optimization based on power level
  - Optimized Bloom filters for duplicate detection
  - Message aggregation and batching
  - Background efficiency modes

- **Advanced Features**
  - Multi-hop message relay (up to 7 hops)
  - Automatic fragmentation for large messages
  - Channel ownership and password management
  - Message retention for important channels
  - Peer nickname management
  - Connection quality indicators

- **Reliability Features**
  - **Message Delivery Confirmations**: Track delivery status with intelligent retry logic
    - Exponential backoff retry (2s to 30s with jitter)
    - Priority handling for favorite contacts
    - Partial delivery tracking for channel messages
    - 6 delivery states: pending, sent, delivered, failed, retrying, partial
  
  - **Offline Message Queuing**: Queue messages when recipients are offline
    - Priority-based queuing (urgent, high, normal, low)
    - Size limits (500 messages) with smart eviction
    - Automatic processing when peers reconnect
    - Message expiration based on priority and recipient status
  
  - **Network Health Monitoring**: Real-time connection quality indicators
    - 5-level health status with visual indicators
    - Comprehensive metrics (peer count, signal strength, delivery rates)
    - Smart recommendations for improving connectivity
    - Historical data tracking and trend analysis
    - Expandable UI panel with detailed metrics

- **Developer Features**
  - Comprehensive documentation and technical whitepaper
  - XcodeGen project generation
  - Swift Package Manager support
  - Public domain license
  - Contributing guidelines and issue templates

### Technical Details
- **Platform**: iOS 16.0+, macOS 13.0+
- **Language**: Swift 5.0+
- **Framework**: SwiftUI, CryptoKit, Core Bluetooth
- **Architecture**: MVVM with Combine publishers
- **Protocol**: Custom binary protocol over Bluetooth LE
- **Range**: ~100m direct, 300m+ with relay
- **Encryption**: X25519 + AES-256-GCM + Ed25519 signatures

### Security
- All cryptographic operations use Apple's CryptoKit
- No data transmitted to external servers
- Local-first architecture with optional message retention
- Comprehensive input validation and error handling
- Memory-safe Swift implementation

### Performance
- Optimized for battery life with adaptive power modes
- Efficient binary protocol with minimal overhead
- Smart connection management and duty cycling
- Automatic cleanup of stale data and connections

## [0.9.0] - Development Phase

### Added
- Initial Bluetooth LE mesh implementation
- Basic encryption and key exchange
- Simple messaging interface
- Channel support prototype

### Changed
- Refined protocol design
- Improved user interface
- Enhanced security model

### Fixed
- Connection stability issues
- Memory leaks in mesh service
- UI responsiveness problems

## [0.1.0] - Initial Prototype

### Added
- Basic Bluetooth LE communication
- Simple text messaging
- Proof of concept implementation

---

## Release Notes

### Version 1.0.0 - "Mesh Genesis"

This is the initial public release of bitchat, featuring a complete secure mesh messaging system. The app provides true peer-to-peer communication without requiring internet connectivity or centralized servers.

**Key Highlights:**
- **Privacy First**: No accounts, no phone numbers, no tracking
- **Mesh Networking**: Messages relay through multiple hops to reach distant peers
- **Strong Encryption**: Military-grade encryption with forward secrecy
- **Universal App**: Native support for both iOS and macOS
- **Reliability**: Advanced delivery confirmations and offline message queuing
- **Open Source**: Released into the public domain for everyone

**Perfect for:**
- Privacy-conscious users
- Emergency communication scenarios
- Areas with limited internet connectivity
- Secure group coordination
- Educational purposes and research

**Getting Started:**
1. Install bitchat on your iOS or macOS device
2. Set your nickname (or use the auto-generated one)
3. Start chatting with nearby peers automatically
4. Join channels with `/j #channelname`
5. Send private messages with `/m @nickname message`

For detailed setup instructions, see the [README](README.md).

---

## Migration Guide

### From Development Versions
If you're upgrading from a development version:
1. The app will automatically migrate your settings
2. Existing channels and favorites will be preserved
3. Message history is ephemeral and won't be migrated
4. You may need to rejoin password-protected channels

### Breaking Changes
- None in this initial release

### Deprecated Features
- None in this initial release

---

## Acknowledgments

Special thanks to:
- The Swift and iOS development community
- Contributors to cryptographic libraries and standards
- Beta testers who provided valuable feedback
- The open source community for inspiration and guidance

---

For more information, visit: https://github.com/lhassa8/bitchat
