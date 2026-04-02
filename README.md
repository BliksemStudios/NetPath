# NetPath

[![Build & Test](https://github.com/BliksemStudios/NetPath/actions/workflows/build.yml/badge.svg)](https://github.com/BliksemStudios/NetPath/actions/workflows/build.yml)
[![Release](https://img.shields.io/github/v/release/BliksemStudios/NetPath)](https://github.com/BliksemStudios/NetPath/releases/latest)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform: macOS 14+](https://img.shields.io/badge/Platform-macOS%2014+-black.svg)](https://developer.apple.com/macos/)

**Browse Windows network shares on macOS. Just paste the path.**

NetPath lets you type familiar UNC paths (`\\server\share\folder`) and instantly browse SMB shares — no `smb://` ceremony required. Built for Mac users in Windows-dominant corporate environments who constantly receive UNC paths from colleagues.

---

## Screenshots

### Launcher

Summon with `Cmd+Shift+\` from anywhere. Type or paste a UNC path.

<p align="center">
  <img src="docs/screenshots/launcher-empty.png" alt="NetPath Launcher" width="600">
</p>

### Authentication

Credentials are stored in macOS Keychain. Kerberos is used automatically when available.

<p align="center">
  <img src="docs/screenshots/launcher-credentials.png" alt="Credential Entry" width="500">
</p>

### File Browser

Browse shares with a tree sidebar, sortable columns, and grid view.

<p align="center">
  <img src="docs/screenshots/browser-list-view.png" alt="Browser - List View" width="700">
</p>

<p align="center">
  <img src="docs/screenshots/browser-grid-view.png" alt="Browser - Grid View" width="700">
</p>

### Settings

<p align="center">
  <img src="docs/screenshots/settings-general.png" alt="Settings" width="400">
</p>

---

## Features

- **Spotlight-style launcher** — Press `Cmd+Shift+\` to summon a floating search bar. Paste or type a UNC path and hit Enter.
- **Automatic path conversion** — `\\server\share\path` is silently converted to `smb://server/share/path`
- **Smart authentication** — Uses Kerberos when available, stores credentials in macOS Keychain, shows an in-app credential form as fallback
- **Full file browser** — Address bar with clickable breadcrumbs, sortable list/grid views, context menus, tree sidebar
- **Keyboard-first** — Arrow keys navigate suggestions, Enter connects, Escape dismisses. Global hotkeys work from any app.
- **History** — Recently visited paths appear instantly in the launcher
- **Open Last Session** — Press `Cmd+Shift+L` to reconnect to your last browsed path
- **Menu bar app** — Lives in the menu bar, no dock clutter
- **Copy & Paste** — Copy files, folders, UNC paths, SMB URLs. Paste files into shares.
- **Rich context menu** — Open With, Get Info, Copy, Paste, Reveal in Finder, New Folder, Move to Trash

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Cmd+Shift+\` | Open/close launcher |
| `Cmd+Shift+L` | Open last session |
| `Arrow Up/Down` | Navigate suggestions in launcher |
| `Enter` | Connect to path / open selected suggestion |
| `Escape` | Dismiss launcher |
| `Cmd+Shift+C` | Copy UNC path (in browser) |
| `Opt+Cmd+C` | Copy SMB URL (in browser) |
| `Space` | Quick Look preview (in browser) |

## Installation

### Build from Source

Requires Xcode 16+ and macOS 14 (Sonoma) or later.

```bash
git clone https://github.com/BliksemStudios/NetPath.git
cd NetPath
# Install XcodeGen if needed
brew install xcodegen
# Generate Xcode project
xcodegen generate
# Build
xcodebuild -scheme NetPath -configuration Release build
```

The built app will be in `DerivedData/NetPath-*/Build/Products/Release/NetPath.app`.

### Download

Download the latest DMG from [GitHub Releases](https://github.com/BliksemStudios/NetPath/releases). A new release is automatically built when a version tag (`v*`) is pushed.

## Usage

1. Launch NetPath — it appears as a menu bar icon
2. Press `Cmd+Shift+\` to open the launcher
3. Type or paste a UNC path: `\\server\share\folder`
4. Press Enter — NetPath mounts the share and opens the file browser
5. Browse, open files, copy paths, navigate with breadcrumbs

## Architecture

NetPath is a three-target Xcode project:

- **NetPath.app** — Main SwiftUI app
- **NetPathHelper** — XPC service for privileged NetFS mount operations
- **NetPathShared** — Shared XPC protocol

Built with Swift 6, SwiftUI, SwiftData, and the NetFS framework.

## Design Language

NetPath follows the **Voltaic Precision** design system by Bliksem Studios:

- Primary accent: Electric Blue `#0066FF`
- Dark mode is the hero mode
- SF Pro for UI, SF Mono for all path text
- Translucent material launcher panel
- Subtle, fast spring animations

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests: `xcodebuild test -scheme NetPath -destination 'platform=macOS'`
5. Open a pull request

## License

MIT License. See [LICENSE](LICENSE) for details.

---

**A [Bliksem Studios](https://github.com/BliksemStudios) project.**
