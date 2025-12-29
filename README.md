# DiscordLite

A native macOS Discord client built with SwiftUI, featuring OAuth 2.0 authentication and a clean 3-layer MVVM architecture.

## Overview

DiscordLite is a lightweight, native Discord application for macOS that provides a streamlined Discord experience. Phase 1 implements secure OAuth authentication with Discord's backend services.

## Architecture

### 3-Layer MVVM Structure

```
View Layer (Features/)     - Views + ViewModels
    ↓ depends on
Repo Layer (Repo/)         - Domain logic + Data sources
    ↓ depends on
Lib Layer (Lib/)           - Low-level utilities
```

**Key Principles:**
- ✅ Unidirectional dependency flow: View → Repo → Lib
- ✅ No horizontal dependencies (no Lib→Lib, Repo→Repo, or ViewModel→ViewModel)
- ✅ Dependency injection via FactoryKit
- ✅ Result-based error handling (no throws)

### Project Structure

```
DiscordLite/
├── Core/
│   ├── DI/
│   │   └── Container+Injection.swift          # FactoryKit DI container
│   └── Config/
│       └── AppConfig.swift                    # App configuration
│
├── Models/
│   └── AuthSession.swift                      # Session model
│
├── Lib/                                       # LAYER 1: Utilities
│   ├── Keychain/
│   │   ├── KeychainService.swift              # Secure storage protocol
│   │   └── KeychainServiceImpl.swift          # Keychain implementation
│   └── Logger/
│       ├── LoggerService.swift                # Logging protocol
│       └── LoggerServiceImpl.swift            # OSLog implementation
│
├── Repo/                                      # LAYER 2: Domain logic
│   └── Auth/
│       ├── AuthRepository.swift               # Auth protocol
│       ├── AuthRepositoryImpl.swift           # Auth implementation
│       └── Datasource/
│           ├── AuthGRPCDatasource.swift       # gRPC protocol
│           └── AuthGRPCDatasourceImpl.swift   # gRPC implementation
│
├── Features/                                  # LAYER 3: UI
│   ├── Auth/
│   │   ├── ViewModels/
│   │   │   ├── AuthViewModel.swift            # Auth state management
│   │   │   └── AuthViewModelState.swift       # State enum
│   │   └── Views/
│   │       ├── LoginView.swift                # Login screen
│   │       ├── AuthLoadingView.swift          # Polling UI
│   │       └── AuthErrorView.swift            # Error display
│   └── Home/
│       └── Views/
│           └── HomeView.swift                 # Authenticated home
│
├── ContentView.swift                          # Root router
└── DiscordLiteApp.swift                       # App entry point
```

## Features

### Phase 1 (Current)
- ✅ OAuth 2.0 authentication with Discord
- ✅ Browser-based OAuth flow
- ✅ Secure session storage in macOS Keychain
- ✅ Session persistence across app launches
- ✅ Automatic session restoration
- ✅ Clean logout with session revocation

### Phase 2 (Planned)
- Server/channel browsing
- Real-time messaging
- User profiles
- Notifications

## Requirements

- **macOS:** 26.1+
- **Xcode:** 16.2+
- **Swift:** 5.0+

## Dependencies

The project uses Swift Package Manager with the following packages:

1. **FactoryKit** - Dependency injection framework
   - URL: `https://github.com/hmlongco/Factory`
   - Version: 2.3.0+

2. **DiscordLiteAPI** - gRPC client for Discord backend
   - URL: `https://github.com/TheRogue76/DiscordLiteServer`
   - Branch: main

## Setup

### 1. Clone the Repository

```bash
git clone <repository-url>
cd DiscordLite
```

### 2. Install Dependencies

Dependencies are managed via Swift Package Manager and should resolve automatically when you open the project in Xcode.

Alternatively, resolve them via command line:

```bash
xcodebuild -resolvePackageDependencies
```

### 3. Configure Backend

The app requires the DiscordLiteServer backend to be running. Follow the setup instructions at:
https://github.com/TheRogue76/DiscordLiteServer

By default, the app connects to:
- **Host:** localhost
- **Port:** 50051

### 4. Build and Run

```bash
# Build the project
xcodebuild -project DiscordLite.xcodeproj -scheme DiscordLite -configuration Debug build

# Or open in Xcode and press Cmd+R
open DiscordLite.xcodeproj
```

## Usage

### Authentication Flow

1. Launch the app
2. Click "Sign in with Discord"
3. Browser opens with Discord OAuth page
4. Authorize the application
5. App automatically detects authentication and navigates to home screen

### Session Management

- Sessions are stored securely in macOS Keychain
- App checks for existing sessions on launch
- Sessions persist across app restarts
- Click "Logout" to revoke session and clear storage

## Architecture Details

### Dependency Injection

Services are registered in `Container+Injection.swift` using FactoryKit:

```swift
extension Container {
    var appConfig: Factory<AppConfig> {
        self { AppConfig.default }.singleton
    }

    var authRepository: Factory<AuthRepository> {
        self {
            AuthRepositoryImpl(
                authGRPCDataSource: self.authGRPCDatasource(),
                keychain: self.keychainService(),
                logger: self.logger()
            )
        }.singleton
    }
}
```

ViewModels inject dependencies using `@Injected`:

```swift
@Injected(\.authRepository) private var authRepository
```

### Error Handling

The project uses Result types instead of throwing errors:

```swift
func initAuth() async -> Result<(authURL: URL, sessionID: String), AuthRepositoryError>
```

This provides:
- Explicit error handling
- Type-safe error types
- Better control flow visibility

### State Management

Authentication state is managed by `AuthViewModel`:

```swift
enum AuthViewModelState: Equatable {
    case unauthenticated
    case authenticating
    case authenticated(session: AuthSession)
    case error(LocalizedStringKey)
}
```

The root `ContentView` switches views based on state:

```swift
switch authViewModel.state {
case .unauthenticated:
    LoginView(viewModel: authViewModel)
case .authenticating:
    AuthLoadingView(viewModel: authViewModel)
case .authenticated:
    HomeView(viewModel: authViewModel)
case .error(let message):
    AuthErrorView(viewModel: authViewModel, error: message)
}
```

### Polling Mechanism

The app polls the backend every 2 seconds (configurable) for OAuth completion:

```swift
while Date().timeIntervalSince(startTime) < timeout {
    let result = await authGRPCDataSource.getAuthStatus(sessionId: sessionID)
    // Handle result...
    try? await Task.sleep(nanoseconds: UInt64(pollInterval * 1_000_000_000))
}
```

Timeout is set to 60 seconds by default.

## Build Commands

```bash
# Debug build
xcodebuild -project DiscordLite.xcodeproj -scheme DiscordLite -configuration Debug build

# Release build
xcodebuild -project DiscordLite.xcodeproj -scheme DiscordLite -configuration Release build

# Clean
xcodebuild -project DiscordLite.xcodeproj -scheme DiscordLite clean

# Run tests
xcodebuild -project DiscordLite.xcodeproj -scheme DiscordLite -destination 'platform=macOS' test
```

## Configuration

### App Configuration

Edit `Core/Config/AppConfig.swift` to customize:

```swift
struct AppConfig {
    let grpcHost: String              // Default: "localhost"
    let grpcPort: Int                 // Default: 50051
    let authPollingInterval: TimeInterval  // Default: 2.0 seconds
    let authTimeout: TimeInterval     // Default: 60.0 seconds
}
```

### Keychain Configuration

Session storage uses:
- **Service Name:** com.nasirimehr.DiscordLite
- **Key:** discord_session_id
- **Accessibility:** After first unlock

## Security

- **Keychain Storage:** Sessions stored in macOS Keychain with restricted access
- **Sandbox:** App runs in sandbox mode for enhanced security
- **Hardened Runtime:** Enabled for additional protection
- **No Plaintext Storage:** No sensitive data in UserDefaults or files

## Troubleshooting

### Backend Connection Issues

**Problem:** "Network Error: Connection refused"

**Solution:**
- Ensure DiscordLiteServer is running on port 50051
- Check `AppConfig` for correct host/port
- Verify firewall settings

### Authentication Timeout

**Problem:** "Authentication timed out"

**Solution:**
- Complete OAuth flow within 60 seconds
- Check browser didn't block popup
- Verify backend is responding to status checks

### Keychain Access Denied

**Problem:** Keychain operations fail

**Solution:**
- Check app entitlements in Xcode
- Verify Keychain Access is enabled for the app
- Reset Keychain if corrupted (cautiously)

### Session Not Persisting

**Problem:** App forgets session after restart

**Solution:**
- Verify Keychain save succeeded (check logs)
- Check app has Keychain entitlements
- Ensure session wasn't revoked on backend

## Logging

The app uses OSLog for structured logging:

```swift
logger.info("Authentication successful")
logger.debug("Auth status: pending")
logger.error("Network error", error: error)
```

**View logs:**
```bash
# All logs
log stream --predicate 'subsystem == "com.nasirimehr.DiscordLite"'

# Auth-specific logs
log stream --predicate 'subsystem == "com.nasirimehr.DiscordLite" AND category == "Auth"'
```

## Contributing

This is a personal project, but suggestions and feedback are welcome!

### Development Guidelines

1. **Follow the 3-layer architecture** - No horizontal dependencies
2. **Use Result types** - Avoid throwing errors
3. **Dependency injection** - Register services in Container
4. **SwiftUI best practices** - Use `@StateObject`, `@ObservedObject` appropriately
5. **Logging** - Log important state changes and errors

## License

[Add your license here]

## Acknowledgments

- **FactoryKit** by Michael Long for dependency injection
- **DiscordLiteServer** backend for gRPC API
- Discord for the OAuth API

## Contact

[Add your contact information]

---

**Built with ❤️ using SwiftUI and modern Swift concurrency**
