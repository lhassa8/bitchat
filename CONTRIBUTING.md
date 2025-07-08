# Contributing to bitchat

Thank you for your interest in contributing to bitchat! This document provides guidelines and information for contributors.

## 🤝 How to Contribute

### Reporting Issues

1. **Search existing issues** first to avoid duplicates
2. **Use the issue templates** when available
3. **Provide detailed information**:
   - Device and OS version
   - Steps to reproduce
   - Expected vs actual behavior
   - Screenshots if applicable

### Submitting Pull Requests

1. **Fork the repository**
2. **Create a feature branch** from `main`:
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. **Make your changes** following our coding standards
4. **Test thoroughly** on both iOS and macOS if applicable
5. **Update documentation** if needed
6. **Submit a pull request** with a clear description

## 🏗 Development Setup

### Prerequisites
- Xcode 15.0 or later
- iOS 16.0+ / macOS 13.0+ deployment targets
- Swift 5.0+

### Getting Started
1. Clone your fork:
   ```bash
   git clone https://github.com/yourusername/bitchat.git
   cd bitchat
   ```

2. Generate the Xcode project:
   ```bash
   brew install xcodegen
   xcodegen generate
   ```

3. Open in Xcode:
   ```bash
   open bitchat.xcodeproj
   ```

## 📝 Coding Standards

### Swift Style Guide
- Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use meaningful variable and function names
- Add documentation comments for public APIs
- Keep functions focused and concise

### Code Organization
```
bitchat/
├── Services/           # Core services (mesh, encryption, etc.)
├── ViewModels/         # MVVM view models
├── Views/              # SwiftUI views
├── Protocols/          # Protocol definitions
├── Utils/              # Utility functions
└── Assets.xcassets/    # App assets
```

### Naming Conventions
- **Classes**: PascalCase (`BluetoothMeshService`)
- **Functions/Variables**: camelCase (`sendMessage`)
- **Constants**: camelCase (`maxRetryAttempts`)
- **Enums**: PascalCase with camelCase cases (`NetworkStatus.connected`)

### Documentation
- Use `///` for documentation comments
- Document all public APIs
- Include parameter descriptions and return values
- Add usage examples for complex functions

```swift
/// Sends a message through the mesh network
/// - Parameters:
///   - content: The message content to send
///   - channel: Optional channel name for group messages
/// - Returns: Message ID for tracking delivery
func sendMessage(_ content: String, channel: String? = nil) -> String {
    // Implementation
}
```

## 🧪 Testing

### Testing Requirements
- Add unit tests for new functionality
- Test on both iOS and macOS when applicable
- Test with multiple devices for mesh functionality
- Verify Bluetooth permissions and error handling

### Test Categories
1. **Unit Tests**: Individual component testing
2. **Integration Tests**: Service interaction testing
3. **UI Tests**: User interface testing
4. **Mesh Tests**: Multi-device communication testing

### Running Tests
```bash
# Run all tests
xcodebuild test -scheme bitchat -destination 'platform=iOS Simulator,name=iPhone 15'

# Run specific test suite
xcodebuild test -scheme bitchat -only-testing:bitchatTests/BluetoothMeshServiceTests
```

## 🔒 Security Considerations

### Security Guidelines
- Never commit private keys or sensitive data
- Use secure coding practices for cryptographic operations
- Validate all input data
- Follow principle of least privilege
- Document security assumptions

### Cryptographic Standards
- Use only well-established cryptographic libraries
- Prefer CryptoKit over custom implementations
- Document all cryptographic choices
- Consider forward secrecy and key rotation

### Privacy Requirements
- Minimize data collection
- Implement data retention policies
- Provide clear privacy controls
- Document data flows

## 📋 Areas for Contribution

### High Priority
- **Android Port**: Implement Android client using same protocol
- **Protocol Improvements**: Enhance mesh routing algorithms
- **Performance Optimization**: Reduce battery usage and improve speed
- **Security Audits**: Review cryptographic implementations
- **Accessibility**: Improve VoiceOver and accessibility support

### Medium Priority
- **UI/UX Improvements**: Better user interface and experience
- **Documentation**: Improve guides and API documentation
- **Testing**: Expand test coverage
- **Localization**: Add support for multiple languages
- **Advanced Features**: Voice messages, file sharing, etc.

### Low Priority
- **Platform Ports**: Linux, Windows, web versions
- **Integration**: Third-party app integrations
- **Analytics**: Privacy-preserving usage analytics
- **Themes**: Custom UI themes and appearance options

## 🚀 Feature Development Process

### 1. Planning Phase
- Discuss feature in GitHub Issues or Discussions
- Create detailed specification
- Consider security and privacy implications
- Plan testing strategy

### 2. Implementation Phase
- Create feature branch
- Implement core functionality
- Add comprehensive tests
- Update documentation

### 3. Review Phase
- Submit pull request
- Address review feedback
- Ensure all tests pass
- Update changelog

### 4. Release Phase
- Merge to main branch
- Tag release if applicable
- Update documentation
- Announce new features

## 🐛 Bug Fix Process

### 1. Reproduction
- Confirm the bug exists
- Create minimal reproduction case
- Document affected versions
- Assess severity and impact

### 2. Investigation
- Identify root cause
- Consider security implications
- Plan fix approach
- Estimate effort required

### 3. Implementation
- Create fix branch
- Implement minimal fix
- Add regression tests
- Verify fix works

### 4. Validation
- Test fix thoroughly
- Verify no new issues introduced
- Update tests and documentation
- Submit pull request

## 📚 Documentation Guidelines

### Types of Documentation
1. **Code Comments**: Inline explanations
2. **API Documentation**: Function and class documentation
3. **User Guides**: How-to guides for users
4. **Technical Specs**: Detailed technical documentation
5. **Architecture Docs**: System design and architecture

### Documentation Standards
- Write clear, concise explanations
- Include code examples where helpful
- Keep documentation up-to-date with code changes
- Use proper markdown formatting
- Include diagrams for complex concepts

## 🎯 Pull Request Guidelines

### PR Title Format
```
type(scope): brief description

Examples:
feat(mesh): add message retry logic
fix(ui): resolve channel list crash
docs(readme): update installation instructions
```

### PR Description Template
```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests pass
- [ ] Manual testing completed

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] No new warnings introduced
```

### Review Process
1. **Automated Checks**: CI/CD pipeline runs tests
2. **Code Review**: Maintainers review code quality
3. **Testing**: Verify functionality works as expected
4. **Documentation**: Ensure docs are updated
5. **Approval**: Get approval from maintainers
6. **Merge**: Squash and merge to main

## 🏆 Recognition

### Contributors
All contributors are recognized in:
- GitHub contributors list
- Release notes for significant contributions
- Special mentions for major features

### Maintainers
Active contributors may be invited to become maintainers with:
- Commit access to repository
- Ability to review and merge PRs
- Participation in project direction decisions

## 📞 Getting Help

### Communication Channels
- **GitHub Issues**: Bug reports and feature requests
- **GitHub Discussions**: General questions and discussions
- **Pull Request Comments**: Code-specific discussions

### Response Times
- **Issues**: We aim to respond within 48 hours
- **Pull Requests**: Initial review within 1 week
- **Security Issues**: Response within 24 hours

## 📄 License

By contributing to bitchat, you agree that your contributions will be released into the public domain under the same terms as the project.

---

Thank you for contributing to bitchat! Together we're building a more private and decentralized communication future. 🚀
