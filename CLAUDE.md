# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

DiscordLite is a macOS application built with SwiftUI. It is configured as a native macOS app with sandboxing and hardened runtime enabled.

**Bundle Identifier:** com.nasirimehr.DiscordLite
**Deployment Target:** macOS 26.1
**Swift Version:** 5.0
**Development Team ID:** 2Y9TDP52WY

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

### Run the app (after building)
```bash
open DiscordLite.xcodeproj
# Then use Xcode's run button (Cmd+R) or:
xcodebuild -project DiscordLite.xcodeproj -scheme DiscordLite -configuration Debug
```

## Architecture

### Application Structure

- **DiscordLiteApp.swift** - Main app entry point using `@main` attribute. Defines the root `WindowGroup` scene that displays `ContentView`.
- **ContentView.swift** - Root view of the application. Currently displays a basic SwiftUI template view.

### Project Configuration

The project uses Xcode's file system synchronized groups (PBXFileSystemSynchronizedRootGroup), which automatically tracks file additions/removals in the DiscordLite directory.

**Key Build Settings:**
- App Sandbox: Enabled
- Hardened Runtime: Enabled
- SwiftUI Previews: Enabled
- User Selected Files: Read-only access
- Swift Concurrency: Approachable concurrency enabled with MainActor default isolation

The project follows modern Swift practices with:
- `SWIFT_APPROACHABLE_CONCURRENCY = YES`
- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`
- Automatic asset symbol generation

## Development Notes

This is a SwiftUI-based macOS application. When adding new views or features:
- Place new Swift files in the `DiscordLite/` directory
- Assets go in `DiscordLite/Assets.xcassets/`
- The project automatically syncs files added to the DiscordLite directory
- SwiftUI previews are enabled for rapid development
