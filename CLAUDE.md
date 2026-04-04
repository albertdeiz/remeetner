# CLAUDE.md — remeetner

macOS status bar app (SwiftUI) that shows a fullscreen break overlay exactly when a Google Meet meeting starts.

## Stack

- **Swift / SwiftUI** — macOS 15.5+
- **AppAuth** — OAuth 2.0 with Google Calendar API
- **Combine** — reactive state between managers

## Architecture

Coordinator pattern. `AppCoordinator` is the single entry point; it instantiates and wires all managers.

```
AppDelegate
  └── AppCoordinator
        ├── MenuBarManager     (status bar + menu)
        ├── EventScheduler     (event polling, precision timer)
        ├── BreakManager       (activates/deactivates the overlay)
        ├── WindowManager      (creates and destroys windows/panels)
        └── AudioManager       (start/end sounds)
```

Managers communicate downward via constructor dependency injection. Upward communication uses delegate protocols (see `MenuBarManagerDelegate`).

## Key files

| File | Responsibility |
|---|---|
| `Coordinators/AppCoordinator.swift` | Dependency wiring and entry point |
| `Managers/WindowManager.swift` | Overlay (`NSPanel`), settings and events windows |
| `Managers/EventScheduler.swift` | Refresh timer + precision timer to detect meeting start |
| `Managers/BreakManager.swift` | Starts/ends the break; orchestrates overlay and audio |
| `Utils/AppConfiguration.swift` | Global constants (duration, opacity, sounds, etc.) |
| `Utils/SecureConfiguration.swift` | Reads `GoogleService-Info.plist` from the bundle |
| `GoogleOAuthManager.swift` | Auth flow, token refresh, event fetching |

## Overlay

The overlay is an `NSPanel` with `.nonactivatingPanel` that appears above any app including fullscreen:

```swift
panel.level = .screenSaver
panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
panel.hidesOnDeactivate = false
panel.orderFrontRegardless()
```

The semi-transparent background is handled in SwiftUI (`Color.black.opacity(AppConfiguration.overlayOpacity)`), not at the window level, to avoid gray border artifacts.

## Credentials (not in git)

- `remeetner/GoogleService-Info.plist` — CLIENT_ID, REDIRECT_URI, ISSUER_URL
- Use `GoogleService-Info.plist.template` as a starting point
- Registered redirect URI: `com.albertdeiz.remeetner:/oauth2redirect`
- URL scheme declared in `remeetner/Info.plist` → `CFBundleURLTypes`

## Releases

Releases are generated automatically via GitHub Actions when a tag is pushed:

```bash
git tag v1.0.1
git push origin v1.0.1
```

The workflow (`.github/workflows/release.yml`) builds without signing, generates a DMG and ZIP in `dist/`, and publishes them as a GitHub Release.

**Required GitHub secret:**
- `GOOGLE_SERVICE_INFO_PLIST` — contents of `GoogleService-Info.plist` encoded in base64

```bash
base64 -i remeetner/GoogleService-Info.plist | pbcopy
```

## Commits

The user commits manually. When asked for a commit message, only provide the text — never run `git commit`.
