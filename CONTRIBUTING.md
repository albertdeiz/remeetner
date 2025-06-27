# Contributing to Remeetner

Thank you for your interest in contributing to Remeetner! This document provides guidelines and information for contributors.

## 🤝 Code of Conduct

By participating in this project, you agree to abide by our Code of Conduct:
- Be respectful and inclusive
- Use welcoming and inclusive language
- Focus on what is best for the community
- Show empathy towards other community members

## 🚀 Getting Started

### Prerequisites
- macOS 12.0 or later
- Xcode 14.0 or later
- Git
- Familiarity with Swift and SwiftUI

### Setting Up Development Environment

1. **Fork the repository**
   ```bash
   # Fork on GitHub, then clone your fork
   git clone https://github.com/YOUR_USERNAME/remeetner.git
   cd remeetner
   ```

2. **Add upstream remote**
   ```bash
   git remote add upstream https://github.com/albertdeiz/remeetner.git
   ```

3. **Install dependencies**
   ```bash
   # Dependencies are managed through Swift Package Manager
   # They will be automatically resolved when you open the project
   open remeetner.xcodeproj
   ```

## 📋 Types of Contributions

### 🐛 Bug Reports
- Use the issue tracker to report bugs
- Include system information (macOS version, app version)
- Provide clear steps to reproduce
- Include logs if available

### 💡 Feature Requests
- Check existing issues first
- Clearly describe the use case
- Explain why this would be useful
- Consider implementation complexity

### 🔧 Code Contributions
- Follow the existing code style
- Add tests for new functionality
- Update documentation as needed
- Keep changes focused and atomic

### 📚 Documentation
- Improve existing documentation
- Add code comments for complex logic
- Update README or ARCHITECTURE.md
- Fix typos and grammar

## 🏗️ Development Workflow

### 1. Create a Feature Branch
```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/your-bug-fix
```

### 2. Make Your Changes
- Follow the architecture patterns established in the codebase
- Use dependency injection where appropriate
- Maintain separation of concerns
- Write meaningful commit messages

### 3. Test Your Changes
```bash
# Build and run the app
⌘ + R

# Run unit tests (when available)
⌘ + U

# Test manually with different scenarios
```

### 4. Commit Your Changes
```bash
git add .
git commit -m "feat: add new feature description"

# Use conventional commit format:
# feat: new feature
# fix: bug fix
# docs: documentation
# style: formatting
# refactor: code restructuring
# test: adding tests
# chore: maintenance
```

### 5. Push and Create Pull Request
```bash
git push origin feature/your-feature-name
```

Then create a Pull Request on GitHub with:
- Clear title and description
- Reference any related issues
- Screenshots if UI changes
- Test instructions

## 📝 Code Style Guidelines

### Swift Style
- Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use meaningful variable and function names
- Prefer `let` over `var` when possible
- Use type inference where appropriate

### Architecture
- Follow the established architecture patterns
- Use protocols for testability
- Implement proper error handling
- Maintain single responsibility principle

### Comments
```swift
/// Brief description of what this function does
/// - Parameter value: Description of the parameter
/// - Returns: Description of return value
func processValue(_ value: String) -> Result<Data, RemeetnerError> {
    // Implementation comments for complex logic
}
```

### SwiftUI
- Use `@State` for local view state
- Use `@ObservedObject` for external models
- Extract complex views into separate structs
- Use preview providers for development

## 🧪 Testing

### Manual Testing Checklist
- [ ] App launches successfully
- [ ] Google Calendar authentication works
- [ ] Events are fetched and displayed
- [ ] Break overlays appear at correct times
- [ ] Settings are saved and applied
- [ ] Menu bar updates correctly
- [ ] App handles network issues gracefully

### Future Automated Testing
We plan to add:
- Unit tests for managers and utilities
- Integration tests for event scheduling
- UI tests for critical user flows

## 🚀 Release Process

### Version Numbering
We use [Semantic Versioning](https://semver.org/):
- `MAJOR.MINOR.PATCH`
- Major: Breaking changes
- Minor: New features (backward compatible)
- Patch: Bug fixes

### Release Checklist
- [ ] Update version number
- [ ] Update CHANGELOG.md
- [ ] Test on multiple macOS versions
- [ ] Update documentation if needed
- [ ] Create release notes
- [ ] Tag release in Git

## 🆘 Getting Help

### Before Asking for Help
1. Check the [README](README.md) and [ARCHITECTURE](ARCHITECTURE.md)
2. Search existing issues
3. Try debugging with logging

### Where to Get Help
- **GitHub Issues** - For bugs and feature requests
- **GitHub Discussions** - For questions and community support
- **Code Review** - Comment on Pull Requests

## 📚 Resources

### Learning Resources
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)
- [Combine Framework](https://developer.apple.com/documentation/combine)
- [Google Calendar API](https://developers.google.com/calendar)
- [AppAuth for iOS/macOS](https://github.com/openid/AppAuth-iOS)

### Development Tools
- **Xcode** - Primary IDE
- **Instruments** - Performance profiling
- **Console.app** - Viewing app logs
- **Activity Monitor** - System resource monitoring

## 🎉 Recognition

Contributors will be:
- Listed in the CONTRIBUTORS.md file
- Mentioned in release notes for significant contributions
- Given credit in the app's About section

Thank you for contributing to Remeetner! 🙏
