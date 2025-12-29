# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

DiscordLite is a native macOS Discord client built with SwiftUI, featuring OAuth 2.0 authentication and a clean 3-layer MVVM architecture.

**Bundle Identifier:** com.nasirimehr.DiscordLite
**Deployment Target:** macOS 26.1
**Swift Version:** 5.0
**Development Team ID:** 2Y9TDP52WY

## Architecture

### 3-Layer MVVM Pattern

```
View Layer (Features/)     - Views + ViewModels
    ↓ depends on
Repo Layer (Repo/)         - Domain logic + Data sources
    ↓ depends on
Lib Layer (Lib/)           - Low-level utilities (Keychain, Logger)
```

**Critical Rules:**
1. **No horizontal dependencies** - A layer can only depend on the layer below it
2. **Result-based error handling** - Use `Result<T, Error>` instead of `throws`
3. **Dependency injection** - All services injected via FactoryKit
4. **Protocol-first** - Every service has a protocol and implementation

### Layer Responsibilities

**Lib Layer:**
- KeychainService: Secure storage using macOS Keychain
- LoggerService: Structured logging with OSLog
- No business logic, pure utilities

**Repo Layer:**
- AuthRepository: OAuth flow orchestration, session management
- AuthGRPCDatasource: gRPC communication with backend
- Domain logic and data transformation

**View Layer:**
- AuthViewModel: Authentication state management
- Views: LoginView, AuthLoadingView, AuthErrorView, HomeView
- UI logic only, no business logic

## Key Files

### Core Infrastructure
- `Core/DI/Container+Injection.swift` - FactoryKit container registration
- `Core/Config/AppConfig.swift` - App configuration (gRPC host, polling settings)

### Models
- `Models/AuthSession.swift` - Session data model (sessionID only)
- `Features/Auth/ViewModels/AuthViewModelState.swift` - Auth state enum

### Authentication Flow
- `Repo/Auth/AuthRepository.swift` - Auth protocol
- `Repo/Auth/AuthRepositoryImpl.swift` - Auth implementation
- `Repo/Auth/Datasource/AuthGRPCDatasource.swift` - gRPC protocol
- `Repo/Auth/Datasource/AuthGRPCDatasourceImpl.swift` - gRPC implementation
- `Features/Auth/ViewModels/AuthViewModel.swift` - State management
- `ContentView.swift` - Root router (switches views based on auth state)

## Dependencies

### Swift Packages (SPM)
1. **FactoryKit** - `https://github.com/hmlongco/Factory` (v2.5.3+)
   - Dependency injection framework
   - Used for service registration and injection

2. **DiscordLiteAPI** - `https://github.com/TheRogue76/DiscordLiteServer`
   - Generated gRPC client code
   - Provides Discord backend communication

## Build Commands

### Build the project
```bash
xcodebuild -project DiscordLite.xcodeproj -scheme DiscordLite -configuration Debug build
```

### Build for release
```bash
xcodebuild -project DiscordLite.xcodeproj -scheme DiscordLite -configuration Release build
```

### Clean build artifacts
```bash
xcodebuild -project DiscordLite.xcodeproj -scheme DiscordLite clean
```

### Run tests
```bash
xcodebuild -project DiscordLite.xcodeproj -scheme DiscordLite -destination 'platform=macOS' test
```

### Run the app
```bash
open DiscordLite.xcodeproj
# Then use Xcode's run button (Cmd+R)
```

## Development Guidelines

### Error Handling

**Always use Result types, never throws:**

```swift
// ✅ Correct
func initAuth() async -> Result<(authURL: URL, sessionID: String), AuthRepositoryError>

// ❌ Wrong
func initAuth() async throws -> (authURL: URL, sessionID: String)
```

**Define error enums per service:**

```swift
enum KeychainServiceError: Error {
    case failedToEncodeData
    case failedToSaveItem
    case failedToFetchItem
    case failedToDecodeData
    case failedToDeleteItem
}
```

### Dependency Injection

**Register services in Container+Injection.swift:**

```swift
extension Container {
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

**Inject in ViewModels/Services:**

```swift
@Injected(\.authRepository) private var authRepository
```

### State Management

**AuthViewModel manages authentication state:**

```swift
enum AuthViewModelState: Equatable {
    case unauthenticated
    case authenticating
    case authenticated(session: AuthSession)
    case error(LocalizedStringKey)
}

@MainActor
class AuthViewModel: ObservableObject {
    @Published var state: AuthViewModelState = .unauthenticated
}
```

**ContentView switches views based on state:**

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

### Adding New Features

When adding new features:

1. **Create protocol in appropriate layer**
   ```swift
   protocol NewFeatureService {
       func doSomething() async -> Result<Data, NewFeatureError>
   }
   ```

2. **Create implementation**
   ```swift
   final class NewFeatureServiceImpl: NewFeatureService {
       func doSomething() async -> Result<Data, NewFeatureError> {
           // Implementation
       }
   }
   ```

3. **Register in Container**
   ```swift
   var newFeatureService: Factory<NewFeatureService> {
       self { NewFeatureServiceImpl() }.singleton
   }
   ```

4. **Inject where needed**
   ```swift
   @Injected(\.newFeatureService) private var service
   ```

### Logging

**Use LoggerService for all logging:**

```swift
logger.info("Operation started")
logger.debug("Debug information: \(value)")
logger.error("Operation failed", error: error)
```

**View logs in Console.app or Terminal:**

```bash
log stream --predicate 'subsystem == "com.nasirimehr.DiscordLite"'
```

### Testing

Tests are located in `DiscordLiteTests/` organized by layer:
- `LibTests/` - Keychain, Logger tests
- `RepoTests/` - Repository tests
- `ViewModelTests/` - ViewModel tests

### Project Configuration

The project uses Xcode's file system synchronized groups (PBXFileSystemSynchronizedRootGroup), which automatically tracks file additions/removals in the DiscordLite directory.

**Key Build Settings:**
- App Sandbox: Enabled
- Hardened Runtime: Enabled
- SwiftUI Previews: Enabled
- User Selected Files: Read-only access
- Swift Concurrency: Approachable concurrency enabled with MainActor default isolation

**Swift Settings:**
- `SWIFT_APPROACHABLE_CONCURRENCY = YES`
- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`
- Automatic asset symbol generation

## OAuth Authentication Flow

1. User clicks "Sign in with Discord"
2. `AuthViewModel.startAuth()` called
3. `AuthRepository.initAuth()` → calls gRPC InitAuth
4. Auth URL opened in Safari
5. `AuthViewModel.startPolling()` begins
6. Polls `AuthRepository.pollAuthStatus()` every 2 seconds
7. When status = "authenticated", session saved to Keychain
8. State updated to `.authenticated(session)`
9. ContentView switches to HomeView

**Polling Config (AppConfig.swift):**
- Interval: 2 seconds
- Timeout: 60 seconds

## Backend Requirements

The app requires DiscordLiteServer backend running:
- Host: localhost (configurable in AppConfig)
- Port: 50051 (configurable in AppConfig)
- gRPC API with: InitAuth, GetAuthStatus, RevokeAuth

## Common Tasks

### Update gRPC Host/Port
Edit `Core/Config/AppConfig.swift`:
```swift
static let `default` = AppConfig(
    grpcHost: "your-host",
    grpcPort: 50051,
    authPollingInterval: 2.0,
    authTimeout: 60.0
)
```

### Add New View
1. Create view in `Features/<Feature>/Views/`
2. Add to ViewModel if needed
3. Register route in ContentView if applicable

### Add New Repository
1. Create protocol in `Repo/<Feature>/<Feature>Repository.swift`
2. Create implementation in `Repo/<Feature>/<Feature>RepositoryImpl.swift`
3. Register in `Container+Injection.swift`
4. Inject in ViewModel with `@Injected(\.yourRepository)`

### Debug Authentication Issues
1. Check backend is running (port 50051)
2. View logs: `log stream --predicate 'subsystem == "com.nasirimehr.DiscordLite"'`
3. Verify OAuth URL opens in browser
4. Check polling succeeds (look for "authenticated" status)
5. Verify Keychain save succeeds

## Security Notes

- Sessions stored in macOS Keychain (service: com.nasirimehr.DiscordLite)
- App runs in sandbox mode
- Hardened runtime enabled
- No sensitive data in plaintext storage

## Future Development (Phase 2)

Planned features:
- Server/channel browsing
- Real-time messaging via WebSocket
- User profiles and presence
- Notifications
- Voice channel support
