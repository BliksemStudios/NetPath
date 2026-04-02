# NetPath — Design Specification

**Project:** NetPath — Browse Windows/SMB shares on macOS via UNC paths
**Author:** Bliksem Studios
**Date:** 2026-04-02
**Status:** Approved

---

## Overview

NetPath is a native macOS SwiftUI application that lets users browse Windows/SMB network shares by typing familiar UNC paths (`\\server\share\folder`). It has two modes:

1. **Spotlight Mode** — A floating, translucent search bar summoned via global hotkey. User types/pastes a UNC path and hits Enter.
2. **Browser Mode** — A full file browser window with address bar, directory listing, and sidebar.

Target user: Mac users in Windows-dominant corporate environments (Active Directory, DFS shares) who constantly receive UNC paths from colleagues.

---

## Architecture

### Three-Target Xcode Project

1. **NetPath.app** (sandboxed) — Main SwiftUI app with launcher, browser, settings. Communicates with the helper via XPC. App Store compatible.
2. **NetPathHelper** (unsandboxed Login Item) — Small daemon that handles NetFS mounting/unmounting. Registered via `SMAppService.loginItem` (macOS 13+). Launches on-demand via XPC connection.
3. **NetPathShared** — Shared framework containing the XPC protocol definition used by both targets.

### Data Flow

```
User types \\server\share
  → PathConversionService parses to UNCPath model
  → App checks Keychain for stored credentials
  → XPC call to NetPathHelper with smb:// URL + credentials
  → Helper calls NetFSMountURLAsync → /Volumes/mount_point
  → Helper returns mount point path via XPC reply
  → App browses mounted path via FileManager
  → DirectoryListView/GridView renders file listing
```

### Why XPC Helper?

App Store distribution requires App Sandbox. The sandbox blocks direct `NetFSMountURLSync/Async` calls. The standard workaround (used by Transmit, Mountain Duck) is an unsandboxed Login Item helper that performs privileged operations on behalf of the sandboxed app.

### App Presence

- **Menu bar icon** for quick access and connection status
- **Dock icon** when browser windows are open
- Standard macOS pattern for utility apps

---

## Spotlight Launcher

### Window

- **NSPanel** subclass with `.nonactivatingPanel` style level
- Centered on screen, ~680px wide
- `.ultraThinMaterial` background for native translucency
- No title bar, rounded corners (12pt radius)
- Dismisses on Escape or click-outside

### Input Field

- Single text field with SF Mono font, 18px
- Placeholder: `Type or paste a UNC path... (\\server\share)`
- Accepts both `\\` UNC and `smb://` format
- Below the field: muted conversion preview showing the resolved `smb://` URL

### Autocomplete Dropdown

- Appears as the user types, showing matching entries from history
- Fuzzy matching on path components
- **Pinned entries** (starred, electric blue) always sort first
- **Recent entries** sorted by recency with relative timestamps
- Keyboard navigable (arrow keys + Enter)

### Connection Feedback

- On Enter: spinner replaces the preview line, shows "Connecting to server..."
- On success: launcher dismisses, browser window opens
- On failure: inline error message with retry option (never a blocking alert)
- On auth needed: credential sheet appears as a modal over the launcher

### Global Hotkey

- Default: `⌘⇧\` (configurable in settings)
- Native implementation using `NSEvent.addGlobalMonitorForEvents` + `addLocalMonitorForEvents`
- No third-party dependencies
- Requires Accessibility permission (standard macOS prompt)

---

## Browser Mode

### Address Bar (Toolbar)

- Back/forward navigation buttons (left side)
- Breadcrumb-style path display in SF Mono:
  - Each path segment is clickable (navigates to that level)
  - Segments styled in electric blue, current segment in white
  - Separator: `›` in muted gray
  - Entire bar is editable — click to type a new UNC path and press Enter
- List/Grid view toggle (right side)

### Sidebar (Collapsible)

Three sections:
- **Pinned** — Favorite paths with star icon (electric blue)
- **Recent** — Recently visited paths with relative timestamps
- **Mounted** — Currently active SMB connections with green status indicator

### File Listing

**List View (default):**
- Grid columns: Icon, Name, Date Modified, Size, Kind
- All columns sortable (click header)
- Folders sort above files
- Hover highlight in subtle electric blue
- SF Symbols for file type icons

**Grid View:**
- Icon grid with filename labels below
- Same sorting options via toolbar

**Interactions:**
- Double-click folder → navigate into it
- Double-click file → open with default app via `NSWorkspace.open()`
- Spacebar → Quick Look preview (QLPreviewPanel)
- Right-click → context menu

### Context Menu

- Open
- Open With ▸
- Copy UNC Path (`⌘⇧C`)
- Copy SMB URL (`⌥⌘C`)
- Reveal in Finder
- Quick Look (Space)

### Status Bar

- Left: item count
- Right: green/red connection dot + authenticated user + server hostname

---

## Path Conversion Engine

### UNCPath Model

```swift
struct UNCPath {
    let server: String        // "ggn.global"
    let share: String?        // "dfs" (nil if server-only)
    let components: [String]  // ["ICT", "DEV"]

    var smbURL: URL
    var uncString: String
    var displayPath: String
    var parentPath: UNCPath?

    init?(from input: String)
}
```

### Conversion Rules (UNC → SMB)

- `\\server\share\path` → `smb://server/share/path`
- Replace all `\` with `/`
- Strip leading `\\`, prepend `smb://`
- Trim trailing slashes
- Normalize double/triple backslashes to single separators
- Handle mixed slashes (`\\server/share\path`)

### Reverse Conversion (SMB → UNC)

- `smb://server/share/path` → `\\server\share\path`
- Used for display in address bar and sidebar

### Edge Cases

- `\\server\share` — no trailing path (valid)
- `\\server\share\` — trailing slash (strip)
- `\\server` — server only (attempt to list shares)
- `smb://server/share` — already SMB (accept as-is)
- Spaces in paths — preserved, URL-encoded internally
- IP addresses — `\\192.168.1.100\share` (valid)
- Rich text paste — strip invisible Unicode characters
- Surrounding quotes — strip `"\\server\share"`

---

## Credential Management

### Flow

1. User enters path → app checks Keychain for server hostname
2. **Found** → pass via XPC → mount silently
3. **Not found** → show credential sheet:
   - Domain (pre-filled from server hostname, e.g. `GGN` from `ggn.global`)
   - Username (accepts `DOMAIN\username` format)
   - Password (secure entry)
   - "Save to Keychain" checkbox (default: checked)
4. **Auth failure** → re-show sheet with inline error, fields preserved

### Keychain Storage

- Service: `com.bliksem.netpath`
- Account: server hostname (e.g. `ggn.global`)
- Data: JSON `{ "domain": "GGN", "username": "jduplessis", "password": "..." }`
- Uses Security framework directly

### Settings Management

- Table of stored servers with hostname, domain\username, last used
- Edit/delete per server (delete confirms first)
- Default domain field for pre-filling new connections

---

## XPC Helper Protocol

```swift
@objc protocol NetPathHelperProtocol {
    func mount(url: String, username: String?, password: String?,
               reply: @escaping (String?, Int32) -> Void)
    // reply: (mount point path or nil, error code)

    func unmount(path: String, reply: @escaping (Bool) -> Void)

    func listMountedShares(reply: @escaping ([String]) -> Void)

    func listSharesOnServer(host: String, username: String?, password: String?,
                            reply: @escaping ([String]?, Int32) -> Void)
    // reply: (array of share names or nil, error code)
}
```

- Registered as Login Item via `SMAppService.loginItem`
- Launches on-demand when app makes first XPC connection
- Stays alive while mounts are active
- Handles idle timeout: auto-unmounts after configurable period (default 30 min)
- Uses `NetFSMountURLAsync` for non-blocking mounts

---

## Data Model (SwiftData)

```swift
@Model class PathEntry {
    var uncPath: String       // "\\ggn.global\dfs\ICT\DEV"
    var server: String        // "ggn.global"
    var isPinned: Bool
    var visitCount: Int
    var lastVisited: Date
    var createdAt: Date
}

@Model class MountSession {
    var server: String
    var sharePath: String
    var mountPoint: String    // "/Volumes/NetPath_dfs"
    var connectedAs: String   // "GGN\\jduplessis"
    var connectedAt: Date
    var isActive: Bool
}

@Model class AppSettings {
    var defaultDomain: String?
    var maxHistoryItems: Int      // default 100
    var idleTimeoutMinutes: Int   // default 30
    var showHiddenFiles: Bool     // default false
    var defaultViewMode: String   // "list" or "grid"
}
```

- `PathEntry` drives autocomplete fuzzy search. `isPinned` entries sort first, then by `visitCount`.
- `MountSession` tracks active mounts for the sidebar and cleanup on quit.
- `AppSettings` is a singleton. Hotkey binding stored separately in UserDefaults (needed at launch before SwiftData is ready).

---

## Settings / Preferences

Three-tab SwiftUI `Settings` scene:

**General:**
- Global hotkey recorder
- Launch at login toggle (`SMAppService.mainApp`)
- Default view mode (list/grid)
- Show hidden files
- Idle disconnect timeout (15m / 30m / 1h / Never)

**Credentials:**
- Stored servers table (hostname, domain\username, last used)
- Edit/delete per entry
- Default domain field

**History:**
- Clear all history (with confirmation)
- Max history items (25 / 50 / 100 / 250)
- Individual path deletion

---

## Design Language — Voltaic Precision

- **Primary accent:** Electric Blue `#0066FF`
- **Dark mode** is the hero mode; light mode equally supported
- **Typography:** SF Pro (UI), SF Mono (all path text)
- **Launcher:** `.ultraThinMaterial`, 12pt corner radius, no title bar
- **Animations:** Subtle, fast spring animations — surgical, not bouncy
- **Icons:** SF Symbols throughout
- **Color adaptation:** `@Environment(\.colorScheme)` for all custom colors

---

## Project Structure

```
NetPath/
├── NetPath.xcodeproj
├── NetPath/                          # Main sandboxed app
│   ├── App/
│   │   ├── NetPathApp.swift
│   │   └── AppDelegate.swift
│   ├── Models/
│   │   ├── UNCPath.swift
│   │   ├── PathEntry.swift
│   │   ├── MountSession.swift
│   │   ├── AppSettings.swift
│   │   ├── FileItem.swift
│   │   └── ConnectionState.swift
│   ├── ViewModels/
│   │   ├── LauncherViewModel.swift
│   │   ├── BrowserViewModel.swift
│   │   └── SettingsViewModel.swift
│   ├── Views/
│   │   ├── Launcher/
│   │   │   ├── LauncherPanel.swift
│   │   │   ├── LauncherView.swift
│   │   │   └── PathSuggestionRow.swift
│   │   ├── Browser/
│   │   │   ├── BrowserView.swift
│   │   │   ├── AddressBar.swift
│   │   │   ├── DirectoryListView.swift
│   │   │   ├── DirectoryGridView.swift
│   │   │   ├── FileRowView.swift
│   │   │   ├── SidebarView.swift
│   │   │   └── StatusBarView.swift
│   │   ├── Settings/
│   │   │   ├── SettingsView.swift
│   │   │   ├── GeneralSettingsView.swift
│   │   │   ├── CredentialSettingsView.swift
│   │   │   └── HistorySettingsView.swift
│   │   └── Shared/
│   │       ├── CredentialSheet.swift
│   │       └── LoadingIndicator.swift
│   ├── Services/
│   │   ├── XPCClient.swift
│   │   ├── KeychainService.swift
│   │   ├── FileSystemService.swift
│   │   ├── PathConversionService.swift
│   │   └── HotkeyService.swift
│   ├── Utilities/
│   │   ├── Constants.swift
│   │   └── Extensions.swift
│   └── Resources/
│       ├── Assets.xcassets
│       └── NetPath.entitlements
├── NetPathHelper/
│   ├── main.swift
│   ├── HelperDelegate.swift
│   ├── MountService.swift
│   └── Info.plist
├── NetPathShared/
│   └── NetPathHelperProtocol.swift
├── NetPathTests/
├── README.md
├── LICENSE
└── .github/
    └── workflows/
        └── build.yml
```

---

## Tech Stack

- **Language:** Swift 6 / SwiftUI
- **Target:** macOS 14+ (Sonoma)
- **Architecture:** MVVM
- **Persistence:** SwiftData
- **Credentials:** Security framework (Keychain)
- **Mounting:** NetFS framework (via XPC helper)
- **Helper registration:** SMAppService (ServiceManagement)
- **Package manager:** Swift Package Manager (no external dependencies)
- **License:** MIT

---

## Out of Scope (MVP)

- File transfer progress (copy to/from shares)
- Drag and drop to/from Finder
- Homebrew cask distribution
- Tab support (multiple locations in one window)
- File search/filter within current directory
- SMB share discovery (network browser)
- Touch Bar support
- Menu bar quick-access mode
- Localization
