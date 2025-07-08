# Security Policy

## Supported Versions

We actively support the following versions of bitchat with security updates:

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

We take security seriously. If you discover a security vulnerability in bitchat, please help us by reporting it responsibly.

### For Non-Critical Issues
For general security concerns or low-risk vulnerabilities, you can:
- Open a GitHub issue using the Security Issue template
- Start a discussion in GitHub Discussions

### For Critical Vulnerabilities
For serious security vulnerabilities that could compromise user privacy or security, please:

**DO NOT** create a public GitHub issue. Instead:

1. **Email us privately** at: [Your email address - you'll need to add this]
2. **Include the following information**:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if you have one)
   - Your contact information

### Response Timeline
- **Acknowledgment**: We'll acknowledge receipt within 24 hours
- **Initial Assessment**: We'll provide an initial assessment within 72 hours
- **Regular Updates**: We'll provide updates every 7 days until resolved
- **Resolution**: We aim to resolve critical issues within 30 days

### Disclosure Policy
- We follow responsible disclosure practices
- We'll work with you to understand and resolve the issue
- We'll credit you in our security advisories (unless you prefer to remain anonymous)
- We'll coordinate public disclosure after the issue is resolved

## Security Features

bitchat implements several security measures:

### Cryptographic Security
- **End-to-End Encryption**: X25519 key exchange + AES-256-GCM
- **Forward Secrecy**: New key pairs generated each session
- **Digital Signatures**: Ed25519 for message authenticity
- **Password-Based Encryption**: Argon2id for channel passwords
- **Secure Random**: Uses system cryptographically secure random number generation

### Privacy Protection
- **No Persistent Identifiers**: Ephemeral peer IDs generated each session
- **No Registration**: No accounts, emails, or phone numbers required
- **Local-First**: No data sent to external servers
- **Cover Traffic**: Timing obfuscation and dummy messages
- **Emergency Wipe**: Triple-tap to instantly clear all data

### Network Security
- **Bluetooth LE Only**: Uses short-range, low-energy Bluetooth
- **Message Deduplication**: Prevents replay attacks
- **TTL Limits**: Messages expire after maximum hop count
- **Peer Blocking**: Users can block malicious peers

### Code Security
- **Memory Safety**: Written in Swift with automatic memory management
- **Input Validation**: All network input is validated
- **Error Handling**: Comprehensive error handling prevents crashes
- **Sandboxing**: Runs in iOS/macOS app sandbox

## Security Best Practices for Users

### Device Security
- Keep your device updated with the latest OS security patches
- Use device lock screen protection (PIN, password, biometrics)
- Don't leave bitchat running unattended in public spaces
- Use the emergency wipe feature (triple-tap logo) if needed

### Network Security
- Be aware that Bluetooth has limited range (~100m)
- Messages can be relayed through multiple hops
- Consider your physical environment when using bitchat
- Use password-protected channels for sensitive discussions

### Privacy Practices
- Choose nicknames that don't reveal your identity
- Be cautious about sharing personal information
- Remember that messages are ephemeral by default
- Use the blocking feature for unwanted contacts

## Known Security Considerations

### Bluetooth LE Limitations
- Bluetooth LE can be monitored by nearby devices
- Physical proximity is required for communication
- Bluetooth vulnerabilities in the OS could affect bitchat

### Mesh Network Considerations
- Messages may be relayed through untrusted peers
- Network topology can reveal communication patterns
- Timing analysis might be possible in some scenarios

### Device Compromise
- If your device is compromised, bitchat data may be accessible
- Keychain data could be extracted from compromised devices
- Physical access to unlocked devices poses risks

## Security Audits

We welcome security audits and penetration testing:
- **Code Review**: The source code is publicly available for review
- **Protocol Analysis**: Our protocol documentation is available
- **Responsible Testing**: Please test responsibly and report findings
- **Coordinated Disclosure**: We prefer coordinated disclosure for vulnerabilities

## Cryptographic Implementation

### Libraries Used
- **CryptoKit**: Apple's cryptographic framework
- **System Random**: iOS/macOS secure random number generation
- **Keychain Services**: Secure storage for sensitive data

### Algorithms
- **Key Exchange**: X25519 Elliptic Curve Diffie-Hellman
- **Symmetric Encryption**: AES-256-GCM
- **Digital Signatures**: Ed25519
- **Key Derivation**: Argon2id for password-based keys
- **Hashing**: SHA-256 for integrity checks

### Key Management
- **Ephemeral Keys**: New key pairs generated each session
- **Perfect Forward Secrecy**: Past communications remain secure
- **Secure Storage**: Keys stored in iOS/macOS Keychain
- **Key Rotation**: Automatic key rotation for long-running sessions

## Compliance and Standards

bitchat follows industry best practices:
- **NIST Guidelines**: Cryptographic implementations follow NIST recommendations
- **OWASP**: Mobile security practices based on OWASP guidelines
- **Apple Security**: Follows Apple's security guidelines for iOS/macOS apps
- **RFC Standards**: Network protocols follow relevant RFC standards

## Updates and Patches

Security updates are distributed through:
- **App Store**: iOS and macOS app updates
- **GitHub Releases**: Source code updates and security advisories
- **Security Advisories**: Published for significant security issues

## Contact

For security-related questions or concerns:
- **General Questions**: GitHub Discussions
- **Vulnerability Reports**: [Your private email - you'll need to add this]
- **Security Audits**: Contact us before beginning large-scale testing

---

Thank you for helping keep bitchat secure! 🔒
