# 🌙 Remeetner

> **Smart Break Reminder for Google Calendar Meetings**

Remeetner is a macOS status bar application that automatically triggers break reminders before your Google Calendar meetings. Take a moment to breathe, stretch, or prepare before your next video call.

## ✨ Features

- 🔗 **Google Calendar Integration** - Seamlessly connects with your Google Calendar
- ⏰ **Smart Timing** - Precise event detection with configurable tolerance
- 🌐 **Google Meet Detection** - Only triggers for meetings with Google Meet links
- 🎯 **Break Overlay** - Full-screen break reminder with countdown timer
- 🔧 **Configurable Settings** - Customize break duration and refresh intervals
- 📱 **Native macOS** - Built with SwiftUI for optimal performance
- 🎵 **Audio Feedback** - Sound notifications for break start/end

## 🖼️ Screenshots

### Status Bar Integration
The app lives quietly in your menu bar, showing your connection status and upcoming events.

### Break Overlay
When it's time for a break, a gentle overlay appears with a countdown timer.

### Events View
See your upcoming meetings and their Google Meet status.

## 🚀 Getting Started

### Prerequisites

- macOS 12.0 or later
- Xcode 14.0 or later (for building from source)
- Google Calendar account

### Installation

#### Option 1: Download Release (Recommended)
1. Download the latest release from [Releases](../../releases)
2. Move `Remeetner.app` to your Applications folder
3. Launch the app and grant necessary permissions

#### Option 2: Build from Source
```bash
git clone https://github.com/albertdeiz/remeetner.git
cd remeetner
open remeetner.xcodeproj
```

### First Setup

1. **Launch Remeetner** - The app will appear in your menu bar
2. **Connect Google Calendar** - Click "Connect Google Calendar" in the menu
3. **Grant Permissions** - Authorize calendar access in your browser
4. **Configure Settings** - Adjust break duration and refresh intervals

## ⚙️ Configuration

### Break Settings
- **Duration**: How long your break reminder lasts (default: 30 seconds)
- **Refresh Interval**: How often to check for new events (default: 15 minutes)

### Event Detection
- Only triggers for events with Google Meet/Hangouts links
- Configurable timing tolerance for precise activation
- Automatic de-duplication prevents multiple triggers

## 🏗️ Architecture

Remeetner is built with a scalable, modular architecture following Apple's best practices:

### Design Patterns
- **Coordinator Pattern** - Centralized navigation and flow control
- **Protocol-Oriented Programming** - Enhanced testability and flexibility
- **Dependency Injection** - Loose coupling and better testing
- **Observer Pattern** - Reactive updates with Combine

### Key Components
```
AppCoordinator (Main coordinator)
├── WindowManager (Window management)
├── MenuBarManager (Status bar interface)
├── EventScheduler (Calendar event tracking)
├── BreakManager (Break functionality)
└── AudioManager (Sound notifications)
```

For detailed architecture documentation, see [ARCHITECTURE.md](ARCHITECTURE.md).

## 🔧 Development

### Project Structure
```
remeetner/
├── Coordinators/          # App coordination logic
├── Managers/              # Feature-specific managers
├── Utils/                 # Utilities and helpers
├── Views/                 # SwiftUI views
└── Resources/             # Assets and configurations
```

### Building
```bash
# Clone the repository
git clone https://github.com/albertdeiz/remeetner.git
cd remeetner

# Open in Xcode
open remeetner.xcodeproj

# Build and run
⌘ + R
```

### Dependencies
- **AppAuth** - OAuth 2.0 authentication for Google Calendar
- **SwiftUI** - Modern UI framework
- **Combine** - Reactive programming

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Development Setup
1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes
4. Add tests if applicable
5. Commit your changes: `git commit -m 'Add amazing feature'`
6. Push to the branch: `git push origin feature/amazing-feature`
7. Open a Pull Request

### Code Style
- Follow Swift API Design Guidelines
- Use SwiftLint for consistency
- Maintain high test coverage
- Document public APIs

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙋‍♂️ Support

### Common Issues

**Q: The app doesn't detect my meetings**
- Ensure you've granted calendar permissions
- Check that your meetings have Google Meet links
- Verify your Google Calendar connection

**Q: Break reminders don't appear**
- Check System Preferences > Security & Privacy > Accessibility
- Ensure Remeetner has screen recording permissions if needed

**Q: The app seems to use too much battery**
- Adjust the refresh interval in settings
- The app is optimized for minimal battery usage

### Getting Help
- 📋 [Open an Issue](../../issues) for bugs or feature requests
- 💬 [Discussions](../../discussions) for questions and community support
- 📧 Email: [your-email@example.com](mailto:your-email@example.com)

## 🎯 Roadmap

- [ ] **Multi-calendar support** - Support for multiple Google accounts
- [ ] **Custom break activities** - Guided breathing, stretching exercises
- [ ] **Meeting preparation** - Pre-meeting checklists and reminders
- [ ] **Analytics** - Break tracking and wellness insights
- [ ] **Team features** - Shared break schedules for teams
- [ ] **Integration** - Slack, Microsoft Teams support

## 🏆 Acknowledgments

- **Google Calendar API** - For providing excellent calendar integration
- **AppAuth library** - For robust OAuth 2.0 implementation
- **SwiftUI community** - For inspiration and best practices
- **Beta testers** - For valuable feedback and bug reports

---

<div align="center">

**Made with ❤️ by [Alberto Díaz](https://github.com/albertdeiz)**

[⭐ Star this repo](../../stargazers) | [🐛 Report bug](../../issues) | [💡 Request feature](../../issues)

</div>
