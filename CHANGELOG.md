# Changelog

All notable changes to Remeetner will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Comprehensive architecture documentation
- Scalable modular design with managers
- Protocol-oriented programming for testability
- Centralized configuration system
- Advanced logging with different levels
- Error handling with typed errors
- **Secure configuration management system**
- **Environment-specific configurations (dev/staging/prod)**
- **Template file for Google OAuth setup**
- **Git security with .gitignore for sensitive files**

### Changed
- Complete refactor of AppDelegate for better separation of concerns
- Improved event scheduling with precision timing
- Enhanced date parsing with multiple format support
- Better window management with centralized control
- **Migrated OAuth credentials to secure configuration files**
- **Implemented SecureConfiguration.swift for credential management**

### Security
- **Separated sensitive configuration from source code**
- **Added validation for required configuration keys**
- **Implemented fallback mechanisms for missing configurations**
- **Excluded GoogleService-Info.plist from version control**
- **Added configuration template for developers**

### Technical
- Implemented Coordinator pattern
- Added dependency injection
- Created specialized managers for different responsibilities
- Improved code organization and modularity
- **Enhanced configuration architecture following Apple's best practices**
- **Added environment detection and API endpoint management**

## [1.0.0] - 2025-06-27

### Added
- Initial release of Remeetner
- Google Calendar integration with OAuth 2.0
- Automatic break reminders before meetings
- Google Meet link detection
- Configurable break duration and refresh intervals
- Native macOS status bar integration
- Full-screen break overlay with countdown
- Audio notifications for break start/end
- Settings window for customization
- Events view to see upcoming meetings

### Features
- Smart event detection with configurable timing tolerance
- De-duplication to prevent multiple triggers for same event
- Automatic authentication state management
- Support for today's events with future expansion capability
- Clean SwiftUI interface with native macOS design

### Technical
- Built with SwiftUI and Combine
- Uses AppAuth for secure OAuth 2.0 authentication
- Modular architecture for maintainability
- Efficient timer management for precise timing
- Robust error handling and recovery

---

## Legend

- **Added** for new features
- **Changed** for changes in existing functionality
- **Deprecated** for soon-to-be removed features
- **Removed** for now removed features
- **Fixed** for any bug fixes
- **Security** for vulnerability fixes
- **Technical** for internal improvements
