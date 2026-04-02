# NetPath Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a native macOS SwiftUI app that lets users browse Windows/SMB shares by typing UNC paths, with a Spotlight-style launcher and full file browser.

**Architecture:** Three-target Xcode project — sandboxed main app (SwiftUI), unsandboxed XPC helper (NetFS mounting), and shared framework (XPC protocol). The app communicates mount requests via XPC; the helper performs privileged NetFS operations outside the sandbox.

**Tech Stack:** Swift 6, SwiftUI, SwiftData, NetFS framework, Security framework (Keychain), ServiceManagement (SMAppService), macOS 14+

**Spec:** `docs/superpowers/specs/2026-04-02-netpath-design.md`

---

## Task 1: Project Scaffolding with XcodeGen

**Files:**
- Create: `project.yml`
- Create: `NetPath/App/NetPathApp.swift`
- Create: `NetPath/App/AppDelegate.swift`
- Create: `NetPathHelper/main.swift`
- Create: `NetPathShared/NetPathHelperProtocol.swift`
- Create: `NetPath/Resources/NetPath.entitlements`
- Create: `NetPathHelper/Info.plist`
- Create: `NetPathHelper/NetPathHelper.entitlements`
- Create: `LICENSE`

- [ ] **Step 1: Create directory structure**

```bash
mkdir -p NetPath/App NetPath/Models NetPath/ViewModels \
  NetPath/Views/Launcher NetPath/Views/Browser NetPath/Views/Settings NetPath/Views/Shared \
  NetPath/Services NetPath/Utilities NetPath/Resources \
  NetPathHelper NetPathShared NetPathTests \
  .github/workflows
```

- [ ] **Step 2: Create the MIT LICENSE file**

```
MIT License

Copyright (c) 2026 Bliksem Studios

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

- [ ] **Step 3: Create entitlements for the main app**

Write `NetPath/Resources/NetPath.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.network.client</key>
    <true/>
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
    <key>com.apple.security.files.bookmarks.app-scope</key>
    <true/>
    <key>com.apple.security.temporary-exception.mach-lookup.global-name</key>
    <array>
        <string>com.bliksem.netpath.helper</string>
    </array>
</dict>
</plist>
```

- [ ] **Step 4: Create entitlements for the helper**

Write `NetPathHelper/NetPathHelper.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.network.client</key>
    <true/>
</dict>
</plist>
```

- [ ] **Step 5: Create Info.plist for the helper**

Write `NetPathHelper/Info.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.bliksem.netpath.helper</string>
    <key>CFBundleName</key>
    <string>NetPathHelper</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundlePackageType</key>
    <string>XPC!</string>
    <key>CFBundleExecutable</key>
    <string>NetPathHelper</string>
    <key>LSBackgroundOnly</key>
    <true/>
</dict>
</plist>
```

- [ ] **Step 6: Create minimal stub files so the project compiles**

Write `NetPathShared/NetPathHelperProtocol.swift`:

```swift
import Foundation

@objc public protocol NetPathHelperProtocol {
    func mount(url: String, username: String?, password: String?,
               reply: @escaping (String?, Int32) -> Void)
    func unmount(path: String, reply: @escaping (Bool) -> Void)
    func listMountedShares(reply: @escaping ([String]) -> Void)
    func listSharesOnServer(host: String, username: String?, password: String?,
                            reply: @escaping ([String]?, Int32) -> Void)
}
```

Write `NetPathHelper/main.swift`:

```swift
import Foundation

// Placeholder — implemented in Task 8
class HelperDelegate: NSObject, NSXPCListenerDelegate {
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        return true
    }
}

let delegate = HelperDelegate()
let listener = NSXPCListener(machServiceName: "com.bliksem.netpath.helper")
listener.delegate = delegate
listener.resume()
RunLoop.current.run()
```

Write `NetPath/App/NetPathApp.swift`:

```swift
import SwiftUI
import SwiftData

@main
struct NetPathApp: App {
    var body: some Scene {
        WindowGroup {
            Text("NetPath — Coming Soon")
                .frame(width: 400, height: 200)
        }
    }
}
```

- [ ] **Step 7: Create project.yml for XcodeGen**

Write `project.yml`:

```yaml
name: NetPath
options:
  bundleIdPrefix: com.bliksem
  deploymentTarget:
    macOS: "14.0"
  xcodeVersion: "16.0"
  minimumXcodeGenVersion: "2.38.0"

settings:
  base:
    SWIFT_VERSION: "6.0"
    MACOSX_DEPLOYMENT_TARGET: "14.0"

targets:
  NetPath:
    type: application
    platform: macOS
    sources:
      - path: NetPath
        excludes:
          - "**/.DS_Store"
      - path: NetPathShared
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.bliksem.netpath
        INFOPLIST_GENERATION_CLASS: ""
        GENERATE_INFOPLIST_FILE: true
        MARKETING_VERSION: "1.0.0"
        CURRENT_PROJECT_VERSION: 1
        CODE_SIGN_ENTITLEMENTS: NetPath/Resources/NetPath.entitlements
        PRODUCT_NAME: NetPath
        ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon
        COMBINE_HIDPI_IMAGES: true
        LD_RUNPATH_SEARCH_PATHS:
          - "$(inherited)"
          - "@executable_path/../Frameworks"
    entitlements:
      path: NetPath/Resources/NetPath.entitlements
    dependencies:
      - target: NetPathHelper
        embed: true
        codeSign: true
        copy:
          destination: loginItems

  NetPathHelper:
    type: xpc-service
    platform: macOS
    sources:
      - path: NetPathHelper
        excludes:
          - "**/.DS_Store"
      - path: NetPathShared
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.bliksem.netpath.helper
        INFOPLIST_FILE: NetPathHelper/Info.plist
        CODE_SIGN_ENTITLEMENTS: NetPathHelper/NetPathHelper.entitlements
        PRODUCT_NAME: NetPathHelper
        SKIP_INSTALL: true
        LD_RUNPATH_SEARCH_PATHS:
          - "$(inherited)"
          - "@executable_path/../Frameworks"
    info:
      path: NetPathHelper/Info.plist

  NetPathTests:
    type: bundle.unit-test
    platform: macOS
    sources:
      - path: NetPathTests
        excludes:
          - "**/.DS_Store"
      - path: NetPathShared
    dependencies:
      - target: NetPath
        embed: false
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.bliksem.netpath.tests
        GENERATE_INFOPLIST_FILE: true
        TEST_HOST: "$(BUILT_PRODUCTS_DIR)/NetPath.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/NetPath"
        BUNDLE_LOADER: "$(TEST_HOST)"

schemes:
  NetPath:
    build:
      targets:
        NetPath: all
        NetPathHelper: all
        NetPathTests: [test]
    run:
      config: Debug
    test:
      config: Debug
      targets:
        - NetPathTests
```

- [ ] **Step 8: Create an empty Assets.xcassets**

```bash
mkdir -p NetPath/Resources/Assets.xcassets/AppIcon.appiconset
```

Write `NetPath/Resources/Assets.xcassets/Contents.json`:

```json
{
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

Write `NetPath/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json`:

```json
{
  "images" : [
    {
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "16x16"
    },
    {
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "16x16"
    },
    {
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "32x32"
    },
    {
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "32x32"
    },
    {
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "128x128"
    },
    {
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "128x128"
    },
    {
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "256x256"
    },
    {
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "256x256"
    },
    {
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "512x512"
    },
    {
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "512x512"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

- [ ] **Step 9: Create a placeholder test file**

Write `NetPathTests/UNCPathTests.swift`:

```swift
import XCTest
@testable import NetPath

final class UNCPathTests: XCTestCase {
    func testPlaceholder() {
        XCTAssertTrue(true)
    }
}
```

- [ ] **Step 10: Install XcodeGen and generate project**

```bash
# Download xcodegen
curl -fsSL https://github.com/yonaskolb/XcodeGen/releases/latest/download/xcodegen.zip -o /tmp/xcodegen.zip
unzip -o /tmp/xcodegen.zip -d /tmp/xcodegen
chmod +x /tmp/xcodegen/bin/xcodegen

# Generate project
/tmp/xcodegen/bin/xcodegen generate
```

- [ ] **Step 11: Build to verify project compiles**

```bash
xcodebuild -scheme NetPath -configuration Debug build 2>&1 | tail -5
```

Expected: BUILD SUCCEEDED

- [ ] **Step 12: Commit**

```bash
git add project.yml NetPath/ NetPathHelper/ NetPathShared/ NetPathTests/ LICENSE .github/
git add NetPath.xcodeproj/  # generated
git commit -m "feat: scaffold NetPath project with three targets (app, XPC helper, tests)"
```

---

## Task 2: Constants and Design Tokens

**Files:**
- Create: `NetPath/Utilities/Constants.swift`

- [ ] **Step 1: Write the constants file**

```swift
import SwiftUI

enum Design {
    // MARK: - Colors
    static let electricBlue = Color(red: 0, green: 0.4, blue: 1) // #0066FF

    enum Colors {
        static let accent = Design.electricBlue
        static let connectedGreen = Color(red: 0.3, green: 0.69, blue: 0.31)
        static let errorRed = Color(red: 0.93, green: 0.26, blue: 0.21)
        static let mutedText = Color.secondary
        static let separator = Color(white: 1, opacity: 0.06)
        static let hoverHighlight = Design.electricBlue.opacity(0.08)
        static let selectedHighlight = Design.electricBlue.opacity(0.15)
    }

    // MARK: - Typography
    enum Fonts {
        static let pathMono = Font.system(size: 14, design: .monospaced)
        static let pathMonoLarge = Font.system(size: 18, design: .monospaced)
        static let pathMonoSmall = Font.system(size: 12, design: .monospaced)
        static let sectionHeader = Font.system(size: 10, weight: .semibold)
        static let statusBar = Font.system(size: 11)
    }

    // MARK: - Dimensions
    enum Launcher {
        static let width: CGFloat = 680
        static let cornerRadius: CGFloat = 12
        static let inputPadding: CGFloat = 16
    }

    enum Browser {
        static let sidebarWidth: CGFloat = 200
        static let minWindowWidth: CGFloat = 800
        static let minWindowHeight: CGFloat = 500
        static let addressBarHeight: CGFloat = 44
        static let statusBarHeight: CGFloat = 28
        static let rowHeight: CGFloat = 28
    }

    // MARK: - Animation
    static let fastSpring = Animation.spring(response: 0.25, dampingFraction: 0.9)
    static let subtleFade = Animation.easeInOut(duration: 0.15)
}

enum AppConstants {
    static let serviceName = "com.bliksem.netpath"
    static let helperMachService = "com.bliksem.netpath.helper"
    static let keychainService = "com.bliksem.netpath"

    enum Defaults {
        static let maxHistoryItems = 100
        static let idleTimeoutMinutes = 30
        static let defaultViewMode = "list"
        static let hotkeyKeyCode: UInt16 = 42 // backslash key
        static let hotkeyModifiers: NSEvent.ModifierFlags = [.command, .shift]
    }

    enum UserDefaultsKeys {
        static let hotkeyKeyCode = "hotkeyKeyCode"
        static let hotkeyModifiers = "hotkeyModifiers"
        static let launchAtLogin = "launchAtLogin"
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add NetPath/Utilities/Constants.swift
git commit -m "feat: add design tokens and app constants"
```

---

## Task 3: UNCPath Model with TDD

**Files:**
- Create: `NetPath/Models/UNCPath.swift`
- Modify: `NetPathTests/UNCPathTests.swift`

- [ ] **Step 1: Write failing tests for basic UNC parsing**

Replace `NetPathTests/UNCPathTests.swift`:

```swift
import XCTest
@testable import NetPath

final class UNCPathTests: XCTestCase {

    // MARK: - Basic UNC Parsing

    func testParseSimpleUNCPath() {
        let path = UNCPath(from: #"\\server\share\folder"#)
        XCTAssertNotNil(path)
        XCTAssertEqual(path?.server, "server")
        XCTAssertEqual(path?.share, "share")
        XCTAssertEqual(path?.components, ["folder"])
    }

    func testParseUNCPathWithMultipleComponents() {
        let path = UNCPath(from: #"\\ggn.global\dfs\ICT\DEV"#)
        XCTAssertNotNil(path)
        XCTAssertEqual(path?.server, "ggn.global")
        XCTAssertEqual(path?.share, "dfs")
        XCTAssertEqual(path?.components, ["ICT", "DEV"])
    }

    func testParseServerOnly() {
        let path = UNCPath(from: #"\\server"#)
        XCTAssertNotNil(path)
        XCTAssertEqual(path?.server, "server")
        XCTAssertNil(path?.share)
        XCTAssertEqual(path?.components, [])
    }

    func testParseServerAndShare() {
        let path = UNCPath(from: #"\\server\share"#)
        XCTAssertNotNil(path)
        XCTAssertEqual(path?.server, "server")
        XCTAssertEqual(path?.share, "share")
        XCTAssertEqual(path?.components, [])
    }

    // MARK: - SMB URL Output

    func testSMBURLFromUNC() {
        let path = UNCPath(from: #"\\ggn.global\dfs\ICT\DEV"#)!
        XCTAssertEqual(path.smbURL.absoluteString, "smb://ggn.global/dfs/ICT/DEV")
    }

    func testSMBURLServerAndShare() {
        let path = UNCPath(from: #"\\server\share"#)!
        XCTAssertEqual(path.smbURL.absoluteString, "smb://server/share")
    }

    func testSMBURLServerOnly() {
        let path = UNCPath(from: #"\\server"#)!
        XCTAssertEqual(path.smbURL.absoluteString, "smb://server")
    }

    // MARK: - UNC String Output

    func testUNCStringRoundTrip() {
        let path = UNCPath(from: #"\\ggn.global\dfs\ICT\DEV"#)!
        XCTAssertEqual(path.uncString, #"\\ggn.global\dfs\ICT\DEV"#)
    }

    // MARK: - SMB URL Input

    func testParseSMBURL() {
        let path = UNCPath(from: "smb://server/share/folder")
        XCTAssertNotNil(path)
        XCTAssertEqual(path?.server, "server")
        XCTAssertEqual(path?.share, "share")
        XCTAssertEqual(path?.components, ["folder"])
    }

    func testParseSMBURLServerOnly() {
        let path = UNCPath(from: "smb://server")
        XCTAssertNotNil(path)
        XCTAssertEqual(path?.server, "server")
        XCTAssertNil(path?.share)
    }

    // MARK: - Edge Cases

    func testTrailingSlashStripped() {
        let path = UNCPath(from: #"\\server\share\"#)
        XCTAssertNotNil(path)
        XCTAssertEqual(path?.share, "share")
        XCTAssertEqual(path?.components, [])
    }

    func testDoubleBackslashesNormalized() {
        let path = UNCPath(from: #"\\\\server\\share\\folder"#)
        XCTAssertNotNil(path)
        XCTAssertEqual(path?.server, "server")
        XCTAssertEqual(path?.share, "share")
        XCTAssertEqual(path?.components, ["folder"])
    }

    func testMixedSlashesNormalized() {
        let path = UNCPath(from: #"\\server/share\folder"#)
        XCTAssertNotNil(path)
        XCTAssertEqual(path?.server, "server")
        XCTAssertEqual(path?.share, "share")
        XCTAssertEqual(path?.components, ["folder"])
    }

    func testSpacesInPath() {
        let path = UNCPath(from: #"\\server\share\folder with spaces\file.txt"#)
        XCTAssertNotNil(path)
        XCTAssertEqual(path?.components, ["folder with spaces", "file.txt"])
        // SMB URL should percent-encode spaces
        XCTAssertTrue(path!.smbURL.absoluteString.contains("folder%20with%20spaces"))
    }

    func testIPAddress() {
        let path = UNCPath(from: #"\\192.168.1.100\share"#)
        XCTAssertNotNil(path)
        XCTAssertEqual(path?.server, "192.168.1.100")
    }

    func testSurroundingQuotesStripped() {
        let path = UNCPath(from: #""\\server\share""#)
        XCTAssertNotNil(path)
        XCTAssertEqual(path?.server, "server")
        XCTAssertEqual(path?.share, "share")
    }

    func testEmptyStringReturnsNil() {
        XCTAssertNil(UNCPath(from: ""))
    }

    func testGarbageStringReturnsNil() {
        XCTAssertNil(UNCPath(from: "not a path"))
    }

    // MARK: - Parent Path

    func testParentPath() {
        let path = UNCPath(from: #"\\server\share\a\b\c"#)!
        let parent = path.parentPath
        XCTAssertNotNil(parent)
        XCTAssertEqual(parent?.components, ["a", "b"])
        XCTAssertEqual(parent?.uncString, #"\\server\share\a\b"#)
    }

    func testParentPathAtShare() {
        let path = UNCPath(from: #"\\server\share"#)!
        let parent = path.parentPath
        XCTAssertNotNil(parent)
        XCTAssertEqual(parent?.server, "server")
        XCTAssertNil(parent?.share)
    }

    func testParentPathAtServerIsNil() {
        let path = UNCPath(from: #"\\server"#)!
        XCTAssertNil(path.parentPath)
    }

    // MARK: - Display Path

    func testDisplayPathEqualsUNCString() {
        let path = UNCPath(from: #"\\ggn.global\dfs\ICT"#)!
        XCTAssertEqual(path.displayPath, #"\\ggn.global\dfs\ICT"#)
    }

    // MARK: - Path by appending

    func testAppendingComponent() {
        let path = UNCPath(from: #"\\server\share"#)!
        let child = path.appending(component: "subfolder")
        XCTAssertEqual(child.components, ["subfolder"])
        XCTAssertEqual(child.uncString, #"\\server\share\subfolder"#)
    }

    // MARK: - Unicode stripping

    func testInvisibleUnicodeStripped() {
        // Zero-width space U+200B
        let path = UNCPath(from: "\u{200B}\\\\server\\share")
        XCTAssertNotNil(path)
        XCTAssertEqual(path?.server, "server")
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
xcodebuild test -scheme NetPath -destination 'platform=macOS' 2>&1 | grep -E '(Test Case|Failing|BUILD)'
```

Expected: compilation errors — `UNCPath` doesn't exist yet.

- [ ] **Step 3: Implement UNCPath**

Write `NetPath/Models/UNCPath.swift`:

```swift
import Foundation

struct UNCPath: Equatable, Hashable, Sendable {
    let server: String
    let share: String?
    let components: [String]

    var smbURL: URL {
        var pathString = "smb://\(server)"
        if let share {
            pathString += "/\(share)"
        }
        for component in components {
            pathString += "/\(component)"
        }
        // URL(string:) needs percent-encoding for spaces
        guard let url = URL(string: pathString.addingPercentEncoding(
            withAllowedCharacters: .urlPathAllowed.union(.urlHostAllowed).union(["/", ":"])
        ) ?? pathString) else {
            // Fallback: construct via components
            var comps = URLComponents()
            comps.scheme = "smb"
            comps.host = server
            var fullPath = ""
            if let share { fullPath += "/\(share)" }
            for component in components { fullPath += "/\(component)" }
            comps.path = fullPath
            return comps.url!
        }
        return url
    }

    var uncString: String {
        var result = "\\\\\(server)"
        if let share {
            result += "\\\(share)"
        }
        for component in components {
            result += "\\\(component)"
        }
        return result
    }

    var displayPath: String { uncString }

    var parentPath: UNCPath? {
        if !components.isEmpty {
            return UNCPath(server: server, share: share, components: Array(components.dropLast()))
        }
        if share != nil {
            return UNCPath(server: server, share: nil, components: [])
        }
        return nil
    }

    func appending(component: String) -> UNCPath {
        UNCPath(server: server, share: share, components: components + [component])
    }

    init(server: String, share: String?, components: [String]) {
        self.server = server
        self.share = share
        self.components = components
    }

    init?(from input: String) {
        var cleaned = input

        // Strip invisible Unicode characters (zero-width spaces, BOM, etc.)
        let invisibleScalars: [Unicode.Scalar] = [
            "\u{200B}", "\u{200C}", "\u{200D}", "\u{FEFF}",
            "\u{00AD}", "\u{200E}", "\u{200F}", "\u{202A}",
            "\u{202B}", "\u{202C}", "\u{202D}", "\u{202E}",
            "\u{2060}", "\u{2061}", "\u{2062}", "\u{2063}",
        ]
        for scalar in invisibleScalars {
            cleaned = cleaned.replacingOccurrences(of: String(scalar), with: "")
        }

        // Strip surrounding whitespace and quotes
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        cleaned = cleaned.trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleaned.isEmpty else { return nil }

        // Check if it's an SMB URL
        if cleaned.lowercased().hasPrefix("smb://") {
            guard let url = URL(string: cleaned) else { return nil }
            guard let host = url.host, !host.isEmpty else { return nil }
            self.server = host

            let pathComponents = url.pathComponents.filter { $0 != "/" }
            if pathComponents.isEmpty {
                self.share = nil
                self.components = []
            } else {
                self.share = pathComponents[0]
                self.components = Array(pathComponents.dropFirst())
            }
            return
        }

        // Normalize: replace forward slashes with backslashes
        cleaned = cleaned.replacingOccurrences(of: "/", with: "\\")

        // Must start with at least \\ (UNC prefix)
        guard cleaned.hasPrefix("\\\\") else { return nil }

        // Remove leading backslashes
        cleaned = String(cleaned.drop(while: { $0 == "\\" }))

        // Normalize multiple consecutive backslashes to single
        while cleaned.contains("\\\\") {
            cleaned = cleaned.replacingOccurrences(of: "\\\\", with: "\\")
        }

        // Trim trailing backslash
        if cleaned.hasSuffix("\\") {
            cleaned = String(cleaned.dropLast())
        }

        guard !cleaned.isEmpty else { return nil }

        let segments = cleaned.split(separator: "\\", omittingEmptySubsequences: true)
            .map(String.init)

        guard !segments.isEmpty else { return nil }

        self.server = segments[0]

        if segments.count > 1 {
            self.share = segments[1]
            self.components = Array(segments.dropFirst(2))
        } else {
            self.share = nil
            self.components = []
        }
    }
}
```

- [ ] **Step 4: Fix the smbURL computed property for proper percent-encoding**

The initial implementation has a flawed approach to URL encoding. Replace the `smbURL` property:

```swift
    var smbURL: URL {
        var comps = URLComponents()
        comps.scheme = "smb"
        comps.host = server
        var fullPath = ""
        if let share { fullPath += "/\(share)" }
        for component in components { fullPath += "/\(component)" }
        if !fullPath.isEmpty {
            comps.path = fullPath
        }
        return comps.url!
    }
```

- [ ] **Step 5: Run tests to verify they pass**

```bash
xcodebuild test -scheme NetPath -destination 'platform=macOS' 2>&1 | grep -E '(Test Case|Executed|BUILD)'
```

Expected: All tests pass, BUILD SUCCEEDED

- [ ] **Step 6: Commit**

```bash
git add NetPath/Models/UNCPath.swift NetPathTests/UNCPathTests.swift
git commit -m "feat: add UNCPath model with full parsing, conversion, and edge case handling"
```

---

## Task 4: ConnectionState and FileItem Models

**Files:**
- Create: `NetPath/Models/ConnectionState.swift`
- Create: `NetPath/Models/FileItem.swift`

- [ ] **Step 1: Write ConnectionState enum**

Write `NetPath/Models/ConnectionState.swift`:

```swift
import Foundation

enum ConnectionState: Equatable, Sendable {
    case idle
    case connecting(server: String)
    case connected(mountPoint: String)
    case error(message: String)
    case needsCredentials(server: String)

    var isConnecting: Bool {
        if case .connecting = self { return true }
        return false
    }

    var isConnected: Bool {
        if case .connected = self { return true }
        return false
    }

    var mountPoint: String? {
        if case .connected(let path) = self { return path }
        return nil
    }

    var errorMessage: String? {
        if case .error(let msg) = self { return msg }
        return nil
    }
}
```

- [ ] **Step 2: Write FileItem model**

Write `NetPath/Models/FileItem.swift`:

```swift
import Foundation
import UniformTypeIdentifiers

struct FileItem: Identifiable, Hashable, Sendable {
    let id: String // full path
    let name: String
    let path: URL
    let isDirectory: Bool
    let size: Int64?
    let dateModified: Date?
    let contentType: UTType?

    var icon: String {
        if isDirectory { return "folder.fill" }
        guard let contentType else { return "doc" }
        if contentType.conforms(to: .image) { return "photo" }
        if contentType.conforms(to: .movie) { return "film" }
        if contentType.conforms(to: .audio) { return "music.note" }
        if contentType.conforms(to: .pdf) { return "doc.richtext" }
        if contentType.conforms(to: .spreadsheet) { return "tablecells" }
        if contentType.conforms(to: .presentation) { return "slider.horizontal.below.rectangle" }
        if contentType.conforms(to: .sourceCode) { return "chevron.left.forwardslash.chevron.right" }
        if contentType.conforms(to: .archive) { return "doc.zipper" }
        if contentType.conforms(to: .text) { return "doc.text" }
        return "doc"
    }

    var kindDescription: String {
        if isDirectory { return "Folder" }
        guard let contentType else { return "Document" }
        return contentType.localizedDescription ?? contentType.preferredFilenameExtension?.uppercased() ?? "Document"
    }

    var formattedSize: String {
        guard let size, !isDirectory else { return "—" }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    var formattedDate: String {
        guard let dateModified else { return "—" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: dateModified, relativeTo: Date())
    }

    /// Sorts folders before files, then alphabetically
    static func defaultSort(_ a: FileItem, _ b: FileItem) -> Bool {
        if a.isDirectory != b.isDirectory { return a.isDirectory }
        return a.name.localizedStandardCompare(b.name) == .orderedAscending
    }
}
```

- [ ] **Step 3: Commit**

```bash
git add NetPath/Models/ConnectionState.swift NetPath/Models/FileItem.swift
git commit -m "feat: add ConnectionState enum and FileItem model"
```

---

## Task 5: SwiftData Models

**Files:**
- Create: `NetPath/Models/PathEntry.swift`
- Create: `NetPath/Models/MountSession.swift`
- Create: `NetPath/Models/AppSettings.swift`
- Create: `NetPathTests/PathEntryTests.swift`

- [ ] **Step 1: Write failing tests for PathEntry fuzzy matching**

Write `NetPathTests/PathEntryTests.swift`:

```swift
import XCTest
import SwiftData
@testable import NetPath

final class PathEntryTests: XCTestCase {

    func testFuzzyMatchExactPrefix() {
        let entry = PathEntry(uncPath: #"\\server\share\folder"#, server: "server")
        XCTAssertTrue(entry.fuzzyMatches(query: #"\\server"#))
    }

    func testFuzzyMatchCaseInsensitive() {
        let entry = PathEntry(uncPath: #"\\SERVER\Share"#, server: "SERVER")
        XCTAssertTrue(entry.fuzzyMatches(query: "server"))
    }

    func testFuzzyMatchPartialComponent() {
        let entry = PathEntry(uncPath: #"\\ggn.global\dfs\ICT\DEV"#, server: "ggn.global")
        XCTAssertTrue(entry.fuzzyMatches(query: "ICT"))
    }

    func testFuzzyMatchNoMatch() {
        let entry = PathEntry(uncPath: #"\\server\share"#, server: "server")
        XCTAssertFalse(entry.fuzzyMatches(query: "xyz"))
    }

    func testFuzzyMatchEmpty() {
        let entry = PathEntry(uncPath: #"\\server\share"#, server: "server")
        XCTAssertTrue(entry.fuzzyMatches(query: ""))
    }
}
```

- [ ] **Step 2: Write PathEntry model**

Write `NetPath/Models/PathEntry.swift`:

```swift
import Foundation
import SwiftData

@Model
final class PathEntry {
    var uncPath: String
    var server: String
    var isPinned: Bool
    var visitCount: Int
    var lastVisited: Date
    var createdAt: Date

    init(uncPath: String, server: String, isPinned: Bool = false) {
        self.uncPath = uncPath
        self.server = server
        self.isPinned = isPinned
        self.visitCount = 1
        self.lastVisited = Date()
        self.createdAt = Date()
    }

    func recordVisit() {
        visitCount += 1
        lastVisited = Date()
    }

    func fuzzyMatches(query: String) -> Bool {
        guard !query.isEmpty else { return true }
        return uncPath.localizedCaseInsensitiveContains(query)
    }
}
```

- [ ] **Step 3: Write MountSession model**

Write `NetPath/Models/MountSession.swift`:

```swift
import Foundation
import SwiftData

@Model
final class MountSession {
    var server: String
    var sharePath: String
    var mountPoint: String
    var connectedAs: String
    var connectedAt: Date
    var isActive: Bool

    init(server: String, sharePath: String, mountPoint: String, connectedAs: String) {
        self.server = server
        self.sharePath = sharePath
        self.mountPoint = mountPoint
        self.connectedAs = connectedAs
        self.connectedAt = Date()
        self.isActive = true
    }
}
```

- [ ] **Step 4: Write AppSettings model**

Write `NetPath/Models/AppSettings.swift`:

```swift
import Foundation
import SwiftData

@Model
final class AppSettings {
    var defaultDomain: String?
    var maxHistoryItems: Int
    var idleTimeoutMinutes: Int
    var showHiddenFiles: Bool
    var defaultViewMode: String

    init() {
        self.defaultDomain = nil
        self.maxHistoryItems = AppConstants.Defaults.maxHistoryItems
        self.idleTimeoutMinutes = AppConstants.Defaults.idleTimeoutMinutes
        self.showHiddenFiles = false
        self.defaultViewMode = AppConstants.Defaults.defaultViewMode
    }

    static func fetch(from context: ModelContext) -> AppSettings {
        let descriptor = FetchDescriptor<AppSettings>()
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        let settings = AppSettings()
        context.insert(settings)
        try? context.save()
        return settings
    }
}
```

- [ ] **Step 5: Run tests**

```bash
xcodebuild test -scheme NetPath -destination 'platform=macOS' 2>&1 | grep -E '(Test Case|Executed|BUILD)'
```

Expected: All tests pass

- [ ] **Step 6: Commit**

```bash
git add NetPath/Models/PathEntry.swift NetPath/Models/MountSession.swift \
  NetPath/Models/AppSettings.swift NetPathTests/PathEntryTests.swift
git commit -m "feat: add SwiftData models for history, mount sessions, and settings"
```

---

## Task 6: Extensions

**Files:**
- Create: `NetPath/Utilities/Extensions.swift`

- [ ] **Step 1: Write extensions**

```swift
import SwiftUI
import UniformTypeIdentifiers

extension URL {
    /// Extract the UTType for this file URL
    var utType: UTType? {
        guard let typeIdentifier = try? resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier else {
            return UTType(filenameExtension: pathExtension)
        }
        return UTType(typeIdentifier)
    }
}

extension String {
    /// Extract domain prefix from a hostname (e.g. "GGN" from "ggn.global")
    var domainPrefix: String {
        let parts = split(separator: ".")
        guard let first = parts.first else { return self }
        return first.uppercased()
    }
}

extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add NetPath/Utilities/Extensions.swift
git commit -m "feat: add URL, String, and View extensions"
```

---

## Task 7: KeychainService with TDD

**Files:**
- Create: `NetPath/Services/KeychainService.swift`
- Create: `NetPathTests/KeychainServiceTests.swift`

- [ ] **Step 1: Write failing tests**

Write `NetPathTests/KeychainServiceTests.swift`:

```swift
import XCTest
@testable import NetPath

final class KeychainServiceTests: XCTestCase {
    let service = KeychainService.shared
    let testServer = "test-server-\(UUID().uuidString).example.com"

    override func tearDown() {
        super.tearDown()
        try? service.deleteCredential(for: testServer)
    }

    func testSaveAndRetrieveCredential() throws {
        let cred = ServerCredential(domain: "TEST", username: "admin", password: "secret123")
        try service.saveCredential(cred, for: testServer)

        let retrieved = try service.getCredential(for: testServer)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.domain, "TEST")
        XCTAssertEqual(retrieved?.username, "admin")
        XCTAssertEqual(retrieved?.password, "secret123")
    }

    func testGetNonExistentCredential() throws {
        let result = try service.getCredential(for: "nonexistent-\(UUID()).example.com")
        XCTAssertNil(result)
    }

    func testUpdateCredential() throws {
        let cred1 = ServerCredential(domain: "OLD", username: "user1", password: "pass1")
        try service.saveCredential(cred1, for: testServer)

        let cred2 = ServerCredential(domain: "NEW", username: "user2", password: "pass2")
        try service.saveCredential(cred2, for: testServer)

        let retrieved = try service.getCredential(for: testServer)
        XCTAssertEqual(retrieved?.domain, "NEW")
        XCTAssertEqual(retrieved?.username, "user2")
    }

    func testDeleteCredential() throws {
        let cred = ServerCredential(domain: "DEL", username: "u", password: "p")
        try service.saveCredential(cred, for: testServer)
        try service.deleteCredential(for: testServer)

        let result = try service.getCredential(for: testServer)
        XCTAssertNil(result)
    }

    func testListServers() throws {
        let server1 = "list-test-1-\(UUID()).example.com"
        let server2 = "list-test-2-\(UUID()).example.com"
        defer {
            try? service.deleteCredential(for: server1)
            try? service.deleteCredential(for: server2)
        }

        try service.saveCredential(
            ServerCredential(domain: "D", username: "u", password: "p"), for: server1)
        try service.saveCredential(
            ServerCredential(domain: "D", username: "u", password: "p"), for: server2)

        let servers = try service.listServers()
        XCTAssertTrue(servers.contains(server1))
        XCTAssertTrue(servers.contains(server2))
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
xcodebuild test -scheme NetPath -destination 'platform=macOS' 2>&1 | grep -E '(error:|BUILD)'
```

Expected: compilation errors — `KeychainService` and `ServerCredential` don't exist.

- [ ] **Step 3: Implement KeychainService**

Write `NetPath/Services/KeychainService.swift`:

```swift
import Foundation
import Security

struct ServerCredential: Codable, Sendable {
    let domain: String
    let username: String
    let password: String
}

final class KeychainService: Sendable {
    static let shared = KeychainService()
    private let service = AppConstants.keychainService

    private init() {}

    func saveCredential(_ credential: ServerCredential, for server: String) throws {
        let data = try JSONEncoder().encode(credential)

        // Delete existing first (update pattern)
        try? deleteCredential(for: server)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: server,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked,
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status: status)
        }
    }

    func getCredential(for server: String) throws -> ServerCredential? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: server,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = result as? Data else {
            throw KeychainError.readFailed(status: status)
        }

        return try JSONDecoder().decode(ServerCredential.self, from: data)
    }

    func deleteCredential(for server: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: server,
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status: status)
        }
    }

    func listServers() throws -> [String] {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound { return [] }
        guard status == errSecSuccess, let items = result as? [[String: Any]] else {
            throw KeychainError.readFailed(status: status)
        }

        return items.compactMap { $0[kSecAttrAccount as String] as? String }
    }
}

enum KeychainError: Error, LocalizedError {
    case saveFailed(status: OSStatus)
    case readFailed(status: OSStatus)
    case deleteFailed(status: OSStatus)

    var errorDescription: String? {
        switch self {
        case .saveFailed(let s): return "Keychain save failed (OSStatus \(s))"
        case .readFailed(let s): return "Keychain read failed (OSStatus \(s))"
        case .deleteFailed(let s): return "Keychain delete failed (OSStatus \(s))"
        }
    }
}
```

- [ ] **Step 4: Run tests**

```bash
xcodebuild test -scheme NetPath -destination 'platform=macOS' 2>&1 | grep -E '(Test Case|Executed|BUILD)'
```

Expected: All tests pass (may require Keychain access prompt)

- [ ] **Step 5: Commit**

```bash
git add NetPath/Services/KeychainService.swift NetPathTests/KeychainServiceTests.swift
git commit -m "feat: add KeychainService for credential storage with Security framework"
```

---

## Task 8: XPC Helper — MountService and Listener

**Files:**
- Modify: `NetPathHelper/main.swift`
- Create: `NetPathHelper/HelperDelegate.swift`
- Create: `NetPathHelper/MountService.swift`

- [ ] **Step 1: Implement MountService (NetFS wrapper)**

Write `NetPathHelper/MountService.swift`:

```swift
import Foundation
import NetFS

final class MountService: NSObject, NetPathHelperProtocol {

    private var activeMounts: [String: Date] = [:] // mountPoint -> lastAccessed

    func mount(url: String, username: String?, password: String?,
               reply: @escaping (String?, Int32) -> Void) {
        guard let smbURL = URL(string: url) else {
            reply(nil, Int32(EINVAL))
            return
        }

        // Create mount point name from the share path
        let shareName = smbURL.pathComponents.filter { $0 != "/" }.joined(separator: "_")
        let mountName = "NetPath_\(shareName.isEmpty ? smbURL.host ?? "unknown" : shareName)"
        let mountPoint = "/Volumes/\(mountName)"

        // Create mount directory if needed
        try? FileManager.default.createDirectory(
            atPath: mountPoint, withIntermediateDirectories: true)

        let mountPointURL = URL(fileURLWithPath: mountPoint) as CFURL
        let smbCFURL = smbURL as CFURL

        var mountOptions = NSMutableDictionary()
        mountOptions[kNetFSSoftMountKey] = true

        var openOptions = NSMutableDictionary()
        if username == nil && password == nil {
            openOptions[kNetFSUseGuestKey] = true
        }
        openOptions[kNAUIOptionKey] = kNAUIOptionNoUI

        var mountpoints: Unmanaged<CFArray>?

        let status = NetFSMountURLSync(
            smbCFURL,
            mountPointURL,
            username as CFString?,
            password as CFString?,
            openOptions as CFMutableDictionary,
            mountOptions as CFMutableDictionary,
            &mountpoints
        )

        if status == 0 {
            // Get actual mount point from result
            let actualMountPoint: String
            if let points = mountpoints?.takeRetainedValue() as? [String], let first = points.first {
                actualMountPoint = first
            } else {
                actualMountPoint = mountPoint
            }
            activeMounts[actualMountPoint] = Date()
            reply(actualMountPoint, 0)
        } else {
            // Clean up empty mount directory on failure
            try? FileManager.default.removeItem(atPath: mountPoint)
            reply(nil, status)
        }
    }

    func unmount(path: String, reply: @escaping (Bool) -> Void) {
        let url = URL(fileURLWithPath: path)
        do {
            try FileManager.default.unmountVolume(at: url, options: [])
            activeMounts.removeValue(forKey: path)
            reply(true)
        } catch {
            reply(false)
        }
    }

    func listMountedShares(reply: @escaping ([String]) -> Void) {
        reply(Array(activeMounts.keys))
    }

    func listSharesOnServer(host: String, username: String?, password: String?,
                            reply: @escaping ([String]?, Int32) -> Void) {
        // Mount the server root to enumerate shares
        guard let url = URL(string: "smb://\(host)") else {
            reply(nil, Int32(EINVAL))
            return
        }

        var openOptions = NSMutableDictionary()
        if username == nil && password == nil {
            openOptions[kNetFSUseGuestKey] = true
        }
        openOptions[kNAUIOptionKey] = kNAUIOptionNoUI

        var mountpoints: Unmanaged<CFArray>?

        let status = NetFSMountURLSync(
            url as CFURL,
            nil,
            username as CFString?,
            password as CFString?,
            openOptions as CFMutableDictionary,
            nil,
            &mountpoints
        )

        if status == 0, let points = mountpoints?.takeRetainedValue() as? [String] {
            reply(points, 0)
        } else {
            reply(nil, status)
        }
    }
}
```

- [ ] **Step 2: Implement HelperDelegate**

Write `NetPathHelper/HelperDelegate.swift`:

```swift
import Foundation

final class HelperDelegate: NSObject, NSXPCListenerDelegate {
    private let mountService = MountService()

    func listener(_ listener: NSXPCListener,
                  shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        newConnection.exportedInterface = NSXPCInterface(with: NetPathHelperProtocol.self)
        newConnection.exportedObject = mountService

        newConnection.invalidationHandler = {
            // Connection lost — clean up if needed
        }

        newConnection.resume()
        return true
    }
}
```

- [ ] **Step 3: Update main.swift**

Replace `NetPathHelper/main.swift`:

```swift
import Foundation

let delegate = HelperDelegate()
let listener = NSXPCListener(machServiceName: "com.bliksem.netpath.helper")
listener.delegate = delegate
listener.resume()

// Keep the helper running
RunLoop.current.run()
```

- [ ] **Step 4: Build to verify compilation**

```bash
xcodebuild build -scheme NetPath -configuration Debug 2>&1 | tail -5
```

Expected: BUILD SUCCEEDED

- [ ] **Step 5: Commit**

```bash
git add NetPathHelper/
git commit -m "feat: implement XPC helper with NetFS mount/unmount service"
```

---

## Task 9: XPCClient (App-Side Connection)

**Files:**
- Create: `NetPath/Services/XPCClient.swift`

- [ ] **Step 1: Implement XPCClient**

Write `NetPath/Services/XPCClient.swift`:

```swift
import Foundation

@MainActor
final class XPCClient: ObservableObject {
    static let shared = XPCClient()

    @Published private(set) var isHelperConnected = false

    private var connection: NSXPCConnection?

    private init() {}

    private func getConnection() -> NSXPCConnection {
        if let existing = connection, existing.invalidationHandler != nil {
            return existing
        }

        let conn = NSXPCConnection(machServiceName: AppConstants.helperMachService,
                                    options: .privileged)
        conn.remoteObjectInterface = NSXPCInterface(with: NetPathHelperProtocol.self)

        conn.invalidationHandler = { [weak self] in
            Task { @MainActor in
                self?.isHelperConnected = false
                self?.connection = nil
            }
        }

        conn.interruptionHandler = { [weak self] in
            Task { @MainActor in
                self?.isHelperConnected = false
            }
        }

        conn.resume()
        self.connection = conn
        self.isHelperConnected = true
        return conn
    }

    private func getProxy() -> NetPathHelperProtocol? {
        let conn = getConnection()
        return conn.remoteObjectProxyWithErrorHandler { error in
            print("XPC proxy error: \(error)")
        } as? NetPathHelperProtocol
    }

    func mount(url: String, username: String?, password: String?) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            guard let proxy = getProxy() else {
                continuation.resume(throwing: XPCError.connectionFailed)
                return
            }
            proxy.mount(url: url, username: username, password: password) { mountPoint, status in
                if let mountPoint, status == 0 {
                    continuation.resume(returning: mountPoint)
                } else {
                    continuation.resume(throwing: XPCError.mountFailed(status: status))
                }
            }
        }
    }

    func unmount(path: String) async -> Bool {
        await withCheckedContinuation { continuation in
            guard let proxy = getProxy() else {
                continuation.resume(returning: false)
                return
            }
            proxy.unmount(path: path) { success in
                continuation.resume(returning: success)
            }
        }
    }

    func listMountedShares() async -> [String] {
        await withCheckedContinuation { continuation in
            guard let proxy = getProxy() else {
                continuation.resume(returning: [])
                return
            }
            proxy.listMountedShares { shares in
                continuation.resume(returning: shares)
            }
        }
    }
}

enum XPCError: Error, LocalizedError {
    case connectionFailed
    case mountFailed(status: Int32)

    var errorDescription: String? {
        switch self {
        case .connectionFailed:
            return "Could not connect to NetPath Helper. Make sure it is installed."
        case .mountFailed(let status):
            switch status {
            case Int32(EAUTH), -5045:
                return "Authentication failed. Please check your credentials."
            case Int32(ENOENT):
                return "Share not found. Check the path and try again."
            case Int32(ETIMEDOUT):
                return "Connection timed out. The server may be unreachable."
            default:
                return "Mount failed (error \(status)). Please try again."
            }
        }
    }

    var isAuthError: Bool {
        if case .mountFailed(let status) = self {
            return status == Int32(EAUTH) || status == -5045
        }
        return false
    }
}
```

- [ ] **Step 2: Build to verify**

```bash
xcodebuild build -scheme NetPath -configuration Debug 2>&1 | tail -5
```

Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add NetPath/Services/XPCClient.swift
git commit -m "feat: add XPCClient with async/await mount/unmount interface"
```

---

## Task 10: FileSystemService

**Files:**
- Create: `NetPath/Services/FileSystemService.swift`
- Create: `NetPathTests/FileSystemServiceTests.swift`

- [ ] **Step 1: Write tests for FileSystemService**

Write `NetPathTests/FileSystemServiceTests.swift`:

```swift
import XCTest
@testable import NetPath

final class FileSystemServiceTests: XCTestCase {

    func testListDirectoryAtTmp() throws {
        let service = FileSystemService()
        // /tmp always has contents on macOS
        let items = try service.listDirectory(at: URL(fileURLWithPath: NSTemporaryDirectory()))
        XCTAssertFalse(items.isEmpty)
    }

    func testListDirectoryItemsHaveNames() throws {
        let service = FileSystemService()
        let items = try service.listDirectory(at: URL(fileURLWithPath: NSTemporaryDirectory()))
        for item in items {
            XCTAssertFalse(item.name.isEmpty)
        }
    }

    func testListDirectoryHidesHiddenByDefault() throws {
        let service = FileSystemService()
        let items = try service.listDirectory(at: URL(fileURLWithPath: "/"),
                                               showHidden: false)
        let hiddenItems = items.filter { $0.name.hasPrefix(".") }
        XCTAssertTrue(hiddenItems.isEmpty)
    }

    func testListDirectoryShowsHiddenWhenRequested() throws {
        let service = FileSystemService()
        let items = try service.listDirectory(at: URL(fileURLWithPath: "/"),
                                               showHidden: true)
        let hiddenItems = items.filter { $0.name.hasPrefix(".") }
        XCTAssertFalse(hiddenItems.isEmpty)
    }

    func testListNonExistentDirectoryThrows() {
        let service = FileSystemService()
        XCTAssertThrowsError(
            try service.listDirectory(at: URL(fileURLWithPath: "/nonexistent_\(UUID())"))
        )
    }
}
```

- [ ] **Step 2: Implement FileSystemService**

Write `NetPath/Services/FileSystemService.swift`:

```swift
import Foundation
import UniformTypeIdentifiers

final class FileSystemService: Sendable {

    func listDirectory(at url: URL, showHidden: Bool = false) throws -> [FileItem] {
        let keys: [URLResourceKey] = [
            .nameKey, .isDirectoryKey, .fileSizeKey,
            .contentModificationDateKey, .typeIdentifierKey,
            .isHiddenKey,
        ]

        let contents = try FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: keys,
            options: showHidden ? [] : [.skipsHiddenFiles]
        )

        return contents.compactMap { fileURL -> FileItem? in
            guard let values = try? fileURL.resourceValues(forKeys: Set(keys)) else {
                return nil
            }

            let isDir = values.isDirectory ?? false
            let size = isDir ? nil : Int64(values.fileSize ?? 0)

            return FileItem(
                id: fileURL.path,
                name: values.name ?? fileURL.lastPathComponent,
                path: fileURL,
                isDirectory: isDir,
                size: size,
                dateModified: values.contentModificationDate,
                contentType: fileURL.utType
            )
        }
        .sorted(by: FileItem.defaultSort)
    }
}
```

- [ ] **Step 3: Run tests**

```bash
xcodebuild test -scheme NetPath -destination 'platform=macOS' 2>&1 | grep -E '(Test Case|Executed|BUILD)'
```

Expected: All tests pass

- [ ] **Step 4: Commit**

```bash
git add NetPath/Services/FileSystemService.swift NetPathTests/FileSystemServiceTests.swift
git commit -m "feat: add FileSystemService for browsing mounted volumes"
```

---

## Task 11: PathConversionService

**Files:**
- Create: `NetPath/Services/PathConversionService.swift`

This is a thin wrapper around `UNCPath` that handles the credential-lookup integration.

- [ ] **Step 1: Implement PathConversionService**

Write `NetPath/Services/PathConversionService.swift`:

```swift
import Foundation

struct PathConversionService: Sendable {

    /// Parse any user input into a UNCPath
    func parse(_ input: String) -> UNCPath? {
        UNCPath(from: input)
    }

    /// Convert UNCPath to smb:// URL string
    func toSMBURL(_ path: UNCPath) -> String {
        path.smbURL.absoluteString
    }

    /// Convert smb:// URL string to UNC display string
    func toUNCDisplay(_ smbURL: String) -> String? {
        guard let path = UNCPath(from: smbURL) else { return nil }
        return path.uncString
    }

    /// Extract server hostname from any path input
    func extractServer(_ input: String) -> String? {
        UNCPath(from: input)?.server
    }

    /// Build credential username string from domain and username
    func buildCredentialString(domain: String?, username: String) -> String {
        if let domain, !domain.isEmpty {
            return "\(domain)\\\(username)"
        }
        return username
    }

    /// Parse "DOMAIN\username" into (domain, username)
    func parseCredentialString(_ input: String) -> (domain: String?, username: String) {
        if let backslashIndex = input.firstIndex(of: "\\") {
            let domain = String(input[input.startIndex..<backslashIndex])
            let username = String(input[input.index(after: backslashIndex)...])
            return (domain.isEmpty ? nil : domain, username)
        }
        return (nil, input)
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add NetPath/Services/PathConversionService.swift
git commit -m "feat: add PathConversionService as UNCPath convenience wrapper"
```

---

## Task 12: HotkeyService

**Files:**
- Create: `NetPath/Services/HotkeyService.swift`

- [ ] **Step 1: Implement HotkeyService**

Write `NetPath/Services/HotkeyService.swift`:

```swift
import AppKit
import Carbon.HIToolbox

@MainActor
final class HotkeyService: ObservableObject {
    static let shared = HotkeyService()

    @Published var isRegistered = false

    private var globalMonitor: Any?
    private var localMonitor: Any?

    var onHotkeyPressed: (() -> Void)?

    private var keyCode: UInt16 {
        UInt16(UserDefaults.standard.integer(forKey: AppConstants.UserDefaultsKeys.hotkeyKeyCode))
            .nonZero ?? AppConstants.Defaults.hotkeyKeyCode
    }

    private var modifierFlags: NSEvent.ModifierFlags {
        let raw = UserDefaults.standard.integer(forKey: AppConstants.UserDefaultsKeys.hotkeyModifiers)
        if raw == 0 { return AppConstants.Defaults.hotkeyModifiers }
        return NSEvent.ModifierFlags(rawValue: UInt(raw))
    }

    private init() {}

    func register() {
        unregister()

        let expectedKey = keyCode
        let expectedMods = modifierFlags.intersection(.deviceIndependentFlagsMask)

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == expectedKey &&
               event.modifierFlags.intersection(.deviceIndependentFlagsMask) == expectedMods {
                Task { @MainActor in
                    self?.onHotkeyPressed?()
                }
            }
        }

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == expectedKey &&
               event.modifierFlags.intersection(.deviceIndependentFlagsMask) == expectedMods {
                Task { @MainActor in
                    self?.onHotkeyPressed?()
                }
                return nil // consume the event
            }
            return event
        }

        isRegistered = true
    }

    func unregister() {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
        isRegistered = false
    }

    func updateHotkey(keyCode: UInt16, modifiers: NSEvent.ModifierFlags) {
        UserDefaults.standard.set(Int(keyCode), forKey: AppConstants.UserDefaultsKeys.hotkeyKeyCode)
        UserDefaults.standard.set(Int(modifiers.rawValue), forKey: AppConstants.UserDefaultsKeys.hotkeyModifiers)
        register() // re-register with new key
    }
}

private extension UInt16 {
    var nonZero: UInt16? {
        self == 0 ? nil : self
    }
}
```

- [ ] **Step 2: Build to verify**

```bash
xcodebuild build -scheme NetPath -configuration Debug 2>&1 | tail -5
```

Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add NetPath/Services/HotkeyService.swift
git commit -m "feat: add HotkeyService with global keyboard shortcut monitoring"
```

---

## Task 13: LauncherViewModel

**Files:**
- Create: `NetPath/ViewModels/LauncherViewModel.swift`
- Create: `NetPathTests/LauncherViewModelTests.swift`

- [ ] **Step 1: Write failing tests for LauncherViewModel**

Write `NetPathTests/LauncherViewModelTests.swift`:

```swift
import XCTest
import SwiftData
@testable import NetPath

@MainActor
final class LauncherViewModelTests: XCTestCase {
    var viewModel: LauncherViewModel!
    var container: ModelContainer!

    override func setUp() {
        super.setUp()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try! ModelContainer(
            for: PathEntry.self, MountSession.self, AppSettings.self,
            configurations: config
        )
        viewModel = LauncherViewModel(modelContext: container.mainContext)
    }

    func testInitialState() {
        XCTAssertEqual(viewModel.inputText, "")
        XCTAssertNil(viewModel.convertedPreview)
        XCTAssertEqual(viewModel.connectionState, .idle)
        XCTAssertTrue(viewModel.suggestions.isEmpty)
    }

    func testConvertedPreviewUpdatesOnInput() {
        viewModel.inputText = #"\\server\share"#
        XCTAssertEqual(viewModel.convertedPreview, "smb://server/share")
    }

    func testConvertedPreviewNilForInvalidInput() {
        viewModel.inputText = "garbage"
        XCTAssertNil(viewModel.convertedPreview)
    }

    func testConvertedPreviewNilForEmptyInput() {
        viewModel.inputText = ""
        XCTAssertNil(viewModel.convertedPreview)
    }

    func testSuggestionsFilteredByInput() {
        // Add history entries
        let ctx = container.mainContext
        ctx.insert(PathEntry(uncPath: #"\\server\share\alpha"#, server: "server"))
        ctx.insert(PathEntry(uncPath: #"\\server\share\beta"#, server: "server"))
        ctx.insert(PathEntry(uncPath: #"\\other\data"#, server: "other"))
        try! ctx.save()

        viewModel.inputText = "alpha"
        viewModel.updateSuggestions()

        XCTAssertEqual(viewModel.suggestions.count, 1)
        XCTAssertEqual(viewModel.suggestions.first?.uncPath, #"\\server\share\alpha"#)
    }

    func testSuggestionsShowAllWhenEmpty() {
        let ctx = container.mainContext
        ctx.insert(PathEntry(uncPath: #"\\a\b"#, server: "a"))
        ctx.insert(PathEntry(uncPath: #"\\c\d"#, server: "c"))
        try! ctx.save()

        viewModel.inputText = ""
        viewModel.updateSuggestions()

        XCTAssertEqual(viewModel.suggestions.count, 2)
    }

    func testPinnedSortFirst() {
        let ctx = container.mainContext
        let unpinned = PathEntry(uncPath: #"\\a\b"#, server: "a")
        let pinned = PathEntry(uncPath: #"\\c\d"#, server: "c", isPinned: true)
        ctx.insert(unpinned)
        ctx.insert(pinned)
        try! ctx.save()

        viewModel.inputText = ""
        viewModel.updateSuggestions()

        XCTAssertEqual(viewModel.suggestions.first?.uncPath, #"\\c\d"#)
    }
}
```

- [ ] **Step 2: Implement LauncherViewModel**

Write `NetPath/ViewModels/LauncherViewModel.swift`:

```swift
import SwiftUI
import SwiftData

@MainActor
@Observable
final class LauncherViewModel {
    var inputText: String = "" {
        didSet { onInputChanged() }
    }
    var convertedPreview: String?
    var connectionState: ConnectionState = .idle
    var suggestions: [PathEntry] = []
    var selectedSuggestionIndex: Int = -1

    private let conversionService = PathConversionService()
    private let modelContext: ModelContext
    private let xpcClient = XPCClient.shared

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    private func onInputChanged() {
        if inputText.isEmpty {
            convertedPreview = nil
        } else if let parsed = conversionService.parse(inputText) {
            convertedPreview = conversionService.toSMBURL(parsed)
        } else {
            convertedPreview = nil
        }
        updateSuggestions()
        selectedSuggestionIndex = -1
    }

    func updateSuggestions() {
        let query = inputText
        var descriptor = FetchDescriptor<PathEntry>(
            sortBy: [
                SortDescriptor(\.isPinned, order: .reverse),
                SortDescriptor(\.visitCount, order: .reverse),
                SortDescriptor(\.lastVisited, order: .reverse),
            ]
        )
        descriptor.fetchLimit = 10

        guard let entries = try? modelContext.fetch(descriptor) else {
            suggestions = []
            return
        }

        suggestions = entries.filter { $0.fuzzyMatches(query: query) }
    }

    func connect() async {
        guard let path = conversionService.parse(inputText) else { return }
        let smbURL = conversionService.toSMBURL(path)

        connectionState = .connecting(server: path.server)

        // Check keychain for credentials
        let credential = try? KeychainService.shared.getCredential(for: path.server)

        do {
            let username: String?
            let password: String?
            if let credential {
                username = conversionService.buildCredentialString(
                    domain: credential.domain, username: credential.username)
                password = credential.password
            } else {
                username = nil
                password = nil
            }

            let mountPoint = try await xpcClient.mount(
                url: smbURL, username: username, password: password)

            // Record in history
            recordVisit(path: path)

            connectionState = .connected(mountPoint: mountPoint)
        } catch let error as XPCError where error.isAuthError {
            connectionState = .needsCredentials(server: path.server)
        } catch {
            connectionState = .error(message: error.localizedDescription)
        }
    }

    func connectWithCredentials(domain: String, username: String,
                                 password: String, saveToKeychain: Bool) async {
        guard let path = conversionService.parse(inputText) else { return }
        let smbURL = conversionService.toSMBURL(path)

        connectionState = .connecting(server: path.server)

        let fullUsername = conversionService.buildCredentialString(
            domain: domain, username: username)

        do {
            let mountPoint = try await xpcClient.mount(
                url: smbURL, username: fullUsername, password: password)

            if saveToKeychain {
                try? KeychainService.shared.saveCredential(
                    ServerCredential(domain: domain, username: username, password: password),
                    for: path.server
                )
            }

            recordVisit(path: path)
            connectionState = .connected(mountPoint: mountPoint)
        } catch let error as XPCError where error.isAuthError {
            connectionState = .error(message: "Authentication failed. Check your credentials.")
        } catch {
            connectionState = .error(message: error.localizedDescription)
        }
    }

    func selectSuggestion(_ entry: PathEntry) {
        inputText = entry.uncPath
    }

    func moveSelectionUp() {
        if selectedSuggestionIndex > 0 {
            selectedSuggestionIndex -= 1
        }
    }

    func moveSelectionDown() {
        if selectedSuggestionIndex < suggestions.count - 1 {
            selectedSuggestionIndex += 1
        }
    }

    func confirmSelection() {
        if selectedSuggestionIndex >= 0 && selectedSuggestionIndex < suggestions.count {
            selectSuggestion(suggestions[selectedSuggestionIndex])
        }
    }

    func reset() {
        inputText = ""
        connectionState = .idle
        suggestions = []
        selectedSuggestionIndex = -1
    }

    private func recordVisit(path: UNCPath) {
        let uncString = path.uncString
        let descriptor = FetchDescriptor<PathEntry>(
            predicate: #Predicate { $0.uncPath == uncString }
        )

        if let existing = try? modelContext.fetch(descriptor).first {
            existing.recordVisit()
        } else {
            let entry = PathEntry(uncPath: uncString, server: path.server)
            modelContext.insert(entry)
        }
        try? modelContext.save()
    }
}
```

- [ ] **Step 3: Run tests**

```bash
xcodebuild test -scheme NetPath -destination 'platform=macOS' 2>&1 | grep -E '(Test Case|Executed|BUILD)'
```

Expected: All tests pass

- [ ] **Step 4: Commit**

```bash
git add NetPath/ViewModels/LauncherViewModel.swift NetPathTests/LauncherViewModelTests.swift
git commit -m "feat: add LauncherViewModel with path parsing, history, and connection logic"
```

---

## Task 14: Launcher UI — Panel and View

**Files:**
- Create: `NetPath/Views/Launcher/LauncherPanel.swift`
- Create: `NetPath/Views/Launcher/LauncherView.swift`
- Create: `NetPath/Views/Launcher/PathSuggestionRow.swift`
- Create: `NetPath/Views/Shared/CredentialSheet.swift`
- Create: `NetPath/Views/Shared/LoadingIndicator.swift`

- [ ] **Step 1: Create LauncherPanel (NSPanel subclass)**

Write `NetPath/Views/Launcher/LauncherPanel.swift`:

```swift
import AppKit
import SwiftUI

final class LauncherPanel: NSPanel {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0,
                                width: Design.Launcher.width, height: 80),
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        level = .floating
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isMovableByWindowBackground = true
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        animationBehavior = .utilityWindow

        // Center on screen
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - Design.Launcher.width / 2
            let y = screenFrame.midY + 100 // slightly above center
            setFrameOrigin(NSPoint(x: x, y: y))
        }
    }

    // Close on click outside
    override var canBecomeKey: Bool { true }

    override func resignKey() {
        super.resignKey()
        close()
    }

    // Allow Escape to close
    override func cancelOperation(_ sender: Any?) {
        close()
    }
}
```

- [ ] **Step 2: Create LoadingIndicator**

Write `NetPath/Views/Shared/LoadingIndicator.swift`:

```swift
import SwiftUI

struct LoadingIndicator: View {
    @State private var isAnimating = false

    var body: some View {
        Circle()
            .trim(from: 0, to: 0.7)
            .stroke(Design.Colors.accent, lineWidth: 2)
            .frame(width: 16, height: 16)
            .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
            .animation(
                .linear(duration: 0.8).repeatForever(autoreverses: false),
                value: isAnimating
            )
            .onAppear { isAnimating = true }
    }
}
```

- [ ] **Step 3: Create PathSuggestionRow**

Write `NetPath/Views/Launcher/PathSuggestionRow.swift`:

```swift
import SwiftUI

struct PathSuggestionRow: View {
    let entry: PathEntry
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: entry.isPinned ? "star.fill" : "clock.arrow.circlepath")
                .font(.system(size: 13))
                .foregroundStyle(entry.isPinned ? Design.Colors.accent : .secondary)
                .frame(width: 16)

            Text(entry.uncPath)
                .font(Design.Fonts.pathMono)
                .foregroundStyle(isSelected ? .white : .primary)
                .lineLimit(1)

            Spacer()

            if entry.isPinned {
                Text("Pinned")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            } else {
                Text(entry.lastVisited, style: .relative)
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Design.Colors.selectedHighlight : Color.clear)
        )
    }
}
```

- [ ] **Step 4: Create CredentialSheet**

Write `NetPath/Views/Shared/CredentialSheet.swift`:

```swift
import SwiftUI

struct CredentialSheet: View {
    let server: String
    let onSubmit: (String, String, String, Bool) async -> Void
    let onCancel: () -> Void

    @State private var domain: String
    @State private var username = ""
    @State private var password = ""
    @State private var saveToKeychain = true
    @State private var errorMessage: String?
    @State private var isSubmitting = false

    init(server: String,
         onSubmit: @escaping (String, String, String, Bool) async -> Void,
         onCancel: @escaping () -> Void) {
        self.server = server
        self.onSubmit = onSubmit
        self.onCancel = onCancel
        self._domain = State(initialValue: server.domainPrefix)
    }

    var body: some View {
        VStack(spacing: 16) {
            // Header
            VStack(spacing: 4) {
                Image(systemName: "lock.shield")
                    .font(.system(size: 32))
                    .foregroundStyle(Design.Colors.accent)
                Text("Connect to \(server)")
                    .font(.headline)
            }

            // Error message
            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(Design.Colors.errorRed)
                    .padding(.horizontal)
            }

            // Form
            Form {
                TextField("Domain", text: $domain)
                    .textFieldStyle(.roundedBorder)
                TextField("Username", text: $username)
                    .textFieldStyle(.roundedBorder)
                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
                Toggle("Save to Keychain", isOn: $saveToKeychain)
            }
            .formStyle(.grouped)

            // Actions
            HStack {
                Button("Cancel") { onCancel() }
                    .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Connect") {
                    isSubmitting = true
                    Task {
                        await onSubmit(domain, username, password, saveToKeychain)
                        isSubmitting = false
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(username.isEmpty || password.isEmpty || isSubmitting)
            }
        }
        .padding(20)
        .frame(width: 360)
    }
}
```

- [ ] **Step 5: Create LauncherView**

Write `NetPath/Views/Launcher/LauncherView.swift`:

```swift
import SwiftUI
import SwiftData

struct LauncherView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: LauncherViewModel?
    @State private var showCredentialSheet = false

    var onBrowse: ((String, UNCPath) -> Void)?
    var onDismiss: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            if let viewModel {
                // Input row
                HStack(spacing: 12) {
                    Image(systemName: "network")
                        .foregroundStyle(Design.Colors.accent)
                        .font(.system(size: 18))

                    TextField("Type or paste a UNC path... (\\\\server\\share)",
                              text: Binding(
                                get: { viewModel.inputText },
                                set: { viewModel.inputText = $0 }
                              ))
                        .font(Design.Fonts.pathMonoLarge)
                        .textFieldStyle(.plain)
                        .onSubmit { handleSubmit() }
                        .onKeyPress(.upArrow) {
                            viewModel.moveSelectionUp()
                            return .handled
                        }
                        .onKeyPress(.downArrow) {
                            viewModel.moveSelectionDown()
                            return .handled
                        }

                    if viewModel.connectionState.isConnecting {
                        LoadingIndicator()
                    } else {
                        Text("⏎")
                            .font(.system(size: 11, weight: .semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Design.Colors.accent)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
                .padding(Design.Launcher.inputPadding)

                // Converted preview / status
                previewSection(viewModel: viewModel)

                // Suggestions dropdown
                if !viewModel.suggestions.isEmpty {
                    Divider()
                        .padding(.horizontal, 8)
                        .opacity(0.3)

                    VStack(spacing: 0) {
                        ForEach(Array(viewModel.suggestions.enumerated()), id: \.element.id) { index, entry in
                            PathSuggestionRow(
                                entry: entry,
                                isSelected: index == viewModel.selectedSuggestionIndex
                            )
                            .onTapGesture {
                                viewModel.selectSuggestion(entry)
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)
                }
            }
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: Design.Launcher.cornerRadius))
        .frame(width: Design.Launcher.width)
        .shadow(color: .black.opacity(0.3), radius: 20, y: 8)
        .onAppear {
            if viewModel == nil {
                viewModel = LauncherViewModel(modelContext: modelContext)
            }
        }
        .sheet(isPresented: $showCredentialSheet) {
            if let viewModel, case .needsCredentials(let server) = viewModel.connectionState {
                CredentialSheet(
                    server: server,
                    onSubmit: { domain, user, pass, save in
                        await viewModel.connectWithCredentials(
                            domain: domain, username: user,
                            password: pass, saveToKeychain: save)
                        if viewModel.connectionState.isConnected {
                            showCredentialSheet = false
                            handleConnected()
                        }
                    },
                    onCancel: {
                        showCredentialSheet = false
                        viewModel.connectionState = .idle
                    }
                )
            }
        }
        .onChange(of: viewModel?.connectionState) { _, newState in
            if case .needsCredentials = newState {
                showCredentialSheet = true
            } else if case .connected = newState {
                handleConnected()
            }
        }
    }

    @ViewBuilder
    private func previewSection(viewModel: LauncherViewModel) -> some View {
        if let preview = viewModel.convertedPreview {
            HStack {
                Text("→ \(preview)")
                    .font(Design.Fonts.pathMonoSmall)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, Design.Launcher.inputPadding)
            .padding(.leading, 32)
            .padding(.bottom, 8)
        }

        if let error = viewModel.connectionState.errorMessage {
            HStack {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(Design.Colors.errorRed)
                Text(error)
                    .font(.system(size: 12))
                    .foregroundStyle(Design.Colors.errorRed)
                Spacer()
                Button("Retry") { handleSubmit() }
                    .buttonStyle(.plain)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Design.Colors.accent)
            }
            .padding(.horizontal, Design.Launcher.inputPadding)
            .padding(.bottom, 8)
        }

        if viewModel.connectionState.isConnecting {
            HStack {
                Text("Connecting to \(connectingServer(viewModel))...")
                    .font(Design.Fonts.pathMonoSmall)
                    .foregroundStyle(Design.Colors.accent)
                Spacer()
            }
            .padding(.horizontal, Design.Launcher.inputPadding)
            .padding(.leading, 32)
            .padding(.bottom, 8)
        }
    }

    private func connectingServer(_ viewModel: LauncherViewModel) -> String {
        if case .connecting(let server) = viewModel.connectionState {
            return server
        }
        return ""
    }

    private func handleSubmit() {
        guard let viewModel else { return }
        if viewModel.selectedSuggestionIndex >= 0 {
            viewModel.confirmSelection()
        }
        Task { await viewModel.connect() }
    }

    private func handleConnected() {
        guard let viewModel,
              let mountPoint = viewModel.connectionState.mountPoint,
              let path = PathConversionService().parse(viewModel.inputText) else { return }
        onBrowse?(mountPoint, path)
        viewModel.reset()
        onDismiss?()
    }
}
```

- [ ] **Step 6: Build to verify**

```bash
xcodebuild build -scheme NetPath -configuration Debug 2>&1 | tail -5
```

Expected: BUILD SUCCEEDED

- [ ] **Step 7: Commit**

```bash
git add NetPath/Views/Launcher/ NetPath/Views/Shared/
git commit -m "feat: add Spotlight launcher UI with panel, search bar, suggestions, and credential sheet"
```

---

## Task 15: BrowserViewModel

**Files:**
- Create: `NetPath/ViewModels/BrowserViewModel.swift`
- Create: `NetPathTests/BrowserViewModelTests.swift`

- [ ] **Step 1: Write failing tests**

Write `NetPathTests/BrowserViewModelTests.swift`:

```swift
import XCTest
import SwiftData
@testable import NetPath

@MainActor
final class BrowserViewModelTests: XCTestCase {
    var viewModel: BrowserViewModel!
    var container: ModelContainer!

    override func setUp() {
        super.setUp()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try! ModelContainer(
            for: PathEntry.self, MountSession.self, AppSettings.self,
            configurations: config
        )
        let path = UNCPath(from: #"\\server\share"#)!
        viewModel = BrowserViewModel(
            mountPoint: NSTemporaryDirectory(),
            uncPath: path,
            modelContext: container.mainContext
        )
    }

    func testInitialPathIsCorrect() {
        XCTAssertEqual(viewModel.currentPath.uncString, #"\\server\share"#)
    }

    func testAddressBarTextMatchesPath() {
        XCTAssertEqual(viewModel.addressBarText, #"\\server\share"#)
    }

    func testBreadcrumbs() {
        let path = UNCPath(from: #"\\server\share\a\b\c"#)!
        viewModel = BrowserViewModel(
            mountPoint: NSTemporaryDirectory(),
            uncPath: path,
            modelContext: container.mainContext
        )
        // Breadcrumbs: server, share, a, b, c
        XCTAssertEqual(viewModel.breadcrumbs.count, 5)
        XCTAssertEqual(viewModel.breadcrumbs[0].label, "server")
        XCTAssertEqual(viewModel.breadcrumbs[4].label, "c")
    }

    func testNavigationHistoryTracked() {
        let path2 = UNCPath(from: #"\\server\share\subfolder"#)!
        viewModel.navigateTo(path: path2)
        XCTAssertTrue(viewModel.canGoBack)
        XCTAssertFalse(viewModel.canGoForward)
    }

    func testGoBackRestoresPreviousPath() {
        let path2 = UNCPath(from: #"\\server\share\subfolder"#)!
        viewModel.navigateTo(path: path2)
        viewModel.goBack()
        XCTAssertEqual(viewModel.currentPath.uncString, #"\\server\share"#)
        XCTAssertTrue(viewModel.canGoForward)
    }

    func testViewModeToggle() {
        XCTAssertEqual(viewModel.viewMode, .list)
        viewModel.toggleViewMode()
        XCTAssertEqual(viewModel.viewMode, .grid)
        viewModel.toggleViewMode()
        XCTAssertEqual(viewModel.viewMode, .list)
    }

    func testSortByName() {
        viewModel.sortBy = .name
        XCTAssertEqual(viewModel.sortBy, .name)
    }
}
```

- [ ] **Step 2: Implement BrowserViewModel**

Write `NetPath/ViewModels/BrowserViewModel.swift`:

```swift
import SwiftUI
import SwiftData

enum ViewMode: String, Sendable {
    case list, grid
}

enum SortField: String, CaseIterable, Sendable {
    case name, dateModified, size, kind
}

struct Breadcrumb: Identifiable {
    let id = UUID()
    let label: String
    let path: UNCPath
}

@MainActor
@Observable
final class BrowserViewModel {
    var currentPath: UNCPath
    var items: [FileItem] = []
    var addressBarText: String
    var viewMode: ViewMode = .list
    var sortBy: SortField = .name
    var sortAscending: Bool = true
    var isLoading = false
    var errorMessage: String?
    var connectedAs: String = ""

    private(set) var canGoBack = false
    private(set) var canGoForward = false

    private var mountPoint: String
    private var navigationHistory: [UNCPath] = []
    private var historyIndex = -1
    private let fileService = FileSystemService()
    private let modelContext: ModelContext

    var breadcrumbs: [Breadcrumb] {
        var crumbs: [Breadcrumb] = []
        // Server
        let serverPath = UNCPath(server: currentPath.server, share: nil, components: [])
        crumbs.append(Breadcrumb(label: currentPath.server, path: serverPath))
        // Share
        if let share = currentPath.share {
            let sharePath = UNCPath(server: currentPath.server, share: share, components: [])
            crumbs.append(Breadcrumb(label: share, path: sharePath))
            // Components
            for (i, comp) in currentPath.components.enumerated() {
                let compPath = UNCPath(
                    server: currentPath.server,
                    share: share,
                    components: Array(currentPath.components.prefix(i + 1))
                )
                crumbs.append(Breadcrumb(label: comp, path: compPath))
            }
        }
        return crumbs
    }

    var sortedItems: [FileItem] {
        items.sorted { a, b in
            // Folders always first
            if a.isDirectory != b.isDirectory { return a.isDirectory }

            let result: Bool
            switch sortBy {
            case .name:
                result = a.name.localizedStandardCompare(b.name) == .orderedAscending
            case .dateModified:
                result = (a.dateModified ?? .distantPast) > (b.dateModified ?? .distantPast)
            case .size:
                result = (a.size ?? 0) < (b.size ?? 0)
            case .kind:
                result = a.kindDescription.localizedStandardCompare(b.kindDescription) == .orderedAscending
            }
            return sortAscending ? result : !result
        }
    }

    init(mountPoint: String, uncPath: UNCPath, modelContext: ModelContext) {
        self.mountPoint = mountPoint
        self.currentPath = uncPath
        self.addressBarText = uncPath.uncString
        self.modelContext = modelContext

        pushHistory(uncPath)
        loadDirectory()
    }

    func navigateTo(path: UNCPath) {
        // Trim forward history
        if historyIndex < navigationHistory.count - 1 {
            navigationHistory = Array(navigationHistory.prefix(historyIndex + 1))
        }
        pushHistory(path)
        currentPath = path
        addressBarText = path.uncString
        loadDirectory()
    }

    func navigateToAddressBar() {
        guard let path = UNCPath(from: addressBarText) else {
            errorMessage = "Invalid path"
            return
        }
        navigateTo(path: path)
    }

    func navigateIntoFolder(_ item: FileItem) {
        guard item.isDirectory else { return }
        let child = currentPath.appending(component: item.name)
        navigateTo(path: child)
    }

    func goBack() {
        guard canGoBack else { return }
        historyIndex -= 1
        let path = navigationHistory[historyIndex]
        currentPath = path
        addressBarText = path.uncString
        updateNavState()
        loadDirectory()
    }

    func goForward() {
        guard canGoForward else { return }
        historyIndex += 1
        let path = navigationHistory[historyIndex]
        currentPath = path
        addressBarText = path.uncString
        updateNavState()
        loadDirectory()
    }

    func goUp() {
        guard let parent = currentPath.parentPath else { return }
        navigateTo(path: parent)
    }

    func toggleViewMode() {
        viewMode = viewMode == .list ? .grid : .list
    }

    func toggleSort(_ field: SortField) {
        if sortBy == field {
            sortAscending.toggle()
        } else {
            sortBy = field
            sortAscending = true
        }
    }

    func openFile(_ item: FileItem) {
        NSWorkspace.shared.open(item.path)
    }

    func copyUNCPath(_ item: FileItem) {
        let itemPath = currentPath.appending(component: item.name)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(itemPath.uncString, forType: .string)
    }

    func copySMBURL(_ item: FileItem) {
        let itemPath = currentPath.appending(component: item.name)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(itemPath.smbURL.absoluteString, forType: .string)
    }

    func revealInFinder(_ item: FileItem) {
        NSWorkspace.shared.activateFileViewerSelecting([item.path])
    }

    func refresh() {
        loadDirectory()
    }

    // MARK: - Private

    private func pushHistory(_ path: UNCPath) {
        navigationHistory.append(path)
        historyIndex = navigationHistory.count - 1
        updateNavState()
    }

    private func updateNavState() {
        canGoBack = historyIndex > 0
        canGoForward = historyIndex < navigationHistory.count - 1
    }

    private func loadDirectory() {
        isLoading = true
        errorMessage = nil

        // Build the local filesystem path from mount point + relative path components
        var localPath = URL(fileURLWithPath: mountPoint)
        for component in currentPath.components {
            localPath.appendPathComponent(component)
        }

        // Fetch settings for showHidden
        let showHidden: Bool
        let settings = AppSettings.fetch(from: modelContext)
        showHidden = settings.showHiddenFiles

        do {
            items = try fileService.listDirectory(at: localPath, showHidden: showHidden)
            isLoading = false
        } catch {
            items = []
            errorMessage = "Could not read directory: \(error.localizedDescription)"
            isLoading = false
        }
    }
}
```

- [ ] **Step 3: Run tests**

```bash
xcodebuild test -scheme NetPath -destination 'platform=macOS' 2>&1 | grep -E '(Test Case|Executed|BUILD)'
```

Expected: All tests pass

- [ ] **Step 4: Commit**

```bash
git add NetPath/ViewModels/BrowserViewModel.swift NetPathTests/BrowserViewModelTests.swift
git commit -m "feat: add BrowserViewModel with navigation, sorting, and file operations"
```

---

## Task 16: Browser UI — Address Bar and Status Bar

**Files:**
- Create: `NetPath/Views/Browser/AddressBar.swift`
- Create: `NetPath/Views/Browser/StatusBarView.swift`

- [ ] **Step 1: Create AddressBar**

Write `NetPath/Views/Browser/AddressBar.swift`:

```swift
import SwiftUI

struct AddressBar: View {
    @Bindable var viewModel: BrowserViewModel
    @State private var isEditing = false

    var body: some View {
        HStack(spacing: 8) {
            // Navigation buttons
            HStack(spacing: 4) {
                Button(action: { viewModel.goBack() }) {
                    Image(systemName: "chevron.left")
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.canGoBack)
                .foregroundStyle(viewModel.canGoBack ? .primary : .tertiary)

                Button(action: { viewModel.goForward() }) {
                    Image(systemName: "chevron.right")
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.canGoForward)
                .foregroundStyle(viewModel.canGoForward ? .primary : .tertiary)
            }

            // Path bar
            if isEditing {
                TextField("Path", text: $viewModel.addressBarText)
                    .font(Design.Fonts.pathMono)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        viewModel.navigateToAddressBar()
                        isEditing = false
                    }
                    .onExitCommand { isEditing = false }
            } else {
                // Breadcrumbs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 2) {
                        Text("\\\\")
                            .font(Design.Fonts.pathMono)
                            .foregroundStyle(.secondary)

                        ForEach(Array(viewModel.breadcrumbs.enumerated()), id: \.element.id) { index, crumb in
                            if index > 0 {
                                Text("›")
                                    .font(Design.Fonts.pathMono)
                                    .foregroundStyle(.tertiary)
                                    .padding(.horizontal, 2)
                            }

                            Button(crumb.label) {
                                viewModel.navigateTo(path: crumb.path)
                            }
                            .buttonStyle(.plain)
                            .font(Design.Fonts.pathMono)
                            .foregroundStyle(
                                index == viewModel.breadcrumbs.count - 1
                                    ? .primary
                                    : Design.Colors.accent
                            )
                        }
                    }
                }
                .onTapGesture(count: 2) { isEditing = true }
                .contentShape(Rectangle())
            }

            Spacer()

            // View mode toggle
            HStack(spacing: 2) {
                Button(action: { viewModel.viewMode = .list }) {
                    Image(systemName: "list.bullet")
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .foregroundStyle(viewModel.viewMode == .list ? Design.Colors.accent : .secondary)

                Button(action: { viewModel.viewMode = .grid }) {
                    Image(systemName: "square.grid.2x2")
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .foregroundStyle(viewModel.viewMode == .grid ? Design.Colors.accent : .secondary)
            }
            .padding(2)
            .background(RoundedRectangle(cornerRadius: 6).fill(.quaternary))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.bar)
    }
}
```

- [ ] **Step 2: Create StatusBarView**

Write `NetPath/Views/Browser/StatusBarView.swift`:

```swift
import SwiftUI

struct StatusBarView: View {
    let itemCount: Int
    let server: String
    let username: String
    let isConnected: Bool

    var body: some View {
        HStack {
            Text("\(itemCount) items")
                .font(Design.Fonts.statusBar)
                .foregroundStyle(.secondary)

            Spacer()

            HStack(spacing: 6) {
                Circle()
                    .fill(isConnected ? Design.Colors.connectedGreen : Design.Colors.errorRed)
                    .frame(width: 6, height: 6)

                Text("\(username) — \(server)")
                    .font(Design.Fonts.statusBar)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: Design.Browser.statusBarHeight)
        .background(.bar)
    }
}
```

- [ ] **Step 3: Commit**

```bash
git add NetPath/Views/Browser/AddressBar.swift NetPath/Views/Browser/StatusBarView.swift
git commit -m "feat: add AddressBar with breadcrumbs and StatusBarView"
```

---

## Task 17: Browser UI — Directory List and Grid Views

**Files:**
- Create: `NetPath/Views/Browser/FileRowView.swift`
- Create: `NetPath/Views/Browser/DirectoryListView.swift`
- Create: `NetPath/Views/Browser/DirectoryGridView.swift`

- [ ] **Step 1: Create FileRowView**

Write `NetPath/Views/Browser/FileRowView.swift`:

```swift
import SwiftUI

struct FileRowView: View {
    let item: FileItem
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 0) {
            Image(systemName: item.icon)
                .foregroundStyle(item.isDirectory ? Design.Colors.accent : .secondary)
                .frame(width: 24)

            Text(item.name)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 8)

            Text(item.formattedDate)
                .foregroundStyle(.secondary)
                .frame(width: 150, alignment: .leading)

            Text(item.formattedSize)
                .foregroundStyle(.secondary)
                .frame(width: 80, alignment: .trailing)

            Text(item.kindDescription)
                .foregroundStyle(.secondary)
                .frame(width: 100, alignment: .leading)
                .padding(.leading, 16)
        }
        .font(.system(size: 13))
        .padding(.horizontal, 16)
        .frame(height: Design.Browser.rowHeight)
        .background(isHovered ? Design.Colors.hoverHighlight : Color.clear)
        .onHover { isHovered = $0 }
    }
}
```

- [ ] **Step 2: Create DirectoryListView**

Write `NetPath/Views/Browser/DirectoryListView.swift`:

```swift
import SwiftUI

struct DirectoryListView: View {
    @Bindable var viewModel: BrowserViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Column headers
            HStack(spacing: 0) {
                Spacer().frame(width: 24) // icon column

                sortableHeader("Name", field: .name)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 8)

                sortableHeader("Date Modified", field: .dateModified)
                    .frame(width: 150, alignment: .leading)

                sortableHeader("Size", field: .size)
                    .frame(width: 80, alignment: .trailing)

                sortableHeader("Kind", field: .kind)
                    .frame(width: 100, alignment: .leading)
                    .padding(.leading, 16)
            }
            .font(.system(size: 11, weight: .semibold))
            .textCase(.uppercase)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 16)
            .frame(height: 28)
            .background(.bar)

            Divider()

            // File rows
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.sortedItems) { item in
                        FileRowView(item: item)
                            .onTapGesture(count: 2) {
                                if item.isDirectory {
                                    viewModel.navigateIntoFolder(item)
                                } else {
                                    viewModel.openFile(item)
                                }
                            }
                            .contextMenu { contextMenu(for: item) }
                    }
                }
            }
        }
    }

    private func sortableHeader(_ title: String, field: SortField) -> some View {
        Button(action: { viewModel.toggleSort(field) }) {
            HStack(spacing: 4) {
                Text(title)
                if viewModel.sortBy == field {
                    Image(systemName: viewModel.sortAscending ? "chevron.up" : "chevron.down")
                        .font(.system(size: 8))
                }
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func contextMenu(for item: FileItem) -> some View {
        Button("Open") {
            if item.isDirectory {
                viewModel.navigateIntoFolder(item)
            } else {
                viewModel.openFile(item)
            }
        }

        Divider()

        Button("Copy UNC Path") { viewModel.copyUNCPath(item) }
            .keyboardShortcut("C", modifiers: [.command, .shift])

        Button("Copy SMB URL") { viewModel.copySMBURL(item) }
            .keyboardShortcut("C", modifiers: [.command, .option])

        Divider()

        Button("Reveal in Finder") { viewModel.revealInFinder(item) }
    }
}
```

- [ ] **Step 3: Create DirectoryGridView**

Write `NetPath/Views/Browser/DirectoryGridView.swift`:

```swift
import SwiftUI

struct DirectoryGridView: View {
    @Bindable var viewModel: BrowserViewModel

    private let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 120), spacing: 16)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(viewModel.sortedItems) { item in
                    VStack(spacing: 8) {
                        Image(systemName: item.icon)
                            .font(.system(size: 36))
                            .foregroundStyle(item.isDirectory ? Design.Colors.accent : .secondary)
                            .frame(height: 44)

                        Text(item.name)
                            .font(.system(size: 12))
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                    }
                    .frame(width: 100, height: 90)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.clear)
                    )
                    .onTapGesture(count: 2) {
                        if item.isDirectory {
                            viewModel.navigateIntoFolder(item)
                        } else {
                            viewModel.openFile(item)
                        }
                    }
                    .contextMenu {
                        Button("Open") {
                            if item.isDirectory {
                                viewModel.navigateIntoFolder(item)
                            } else {
                                viewModel.openFile(item)
                            }
                        }
                        Divider()
                        Button("Copy UNC Path") { viewModel.copyUNCPath(item) }
                        Button("Copy SMB URL") { viewModel.copySMBURL(item) }
                        Divider()
                        Button("Reveal in Finder") { viewModel.revealInFinder(item) }
                    }
                }
            }
            .padding(16)
        }
    }
}
```

- [ ] **Step 4: Build to verify**

```bash
xcodebuild build -scheme NetPath -configuration Debug 2>&1 | tail -5
```

Expected: BUILD SUCCEEDED

- [ ] **Step 5: Commit**

```bash
git add NetPath/Views/Browser/FileRowView.swift NetPath/Views/Browser/DirectoryListView.swift \
  NetPath/Views/Browser/DirectoryGridView.swift
git commit -m "feat: add directory list view, grid view, and file row components"
```

---

## Task 18: Browser UI — Sidebar and Main BrowserView

**Files:**
- Create: `NetPath/Views/Browser/SidebarView.swift`
- Create: `NetPath/Views/Browser/BrowserView.swift`

- [ ] **Step 1: Create SidebarView**

Write `NetPath/Views/Browser/SidebarView.swift`:

```swift
import SwiftUI
import SwiftData

struct SidebarView: View {
    @Query(
        filter: #Predicate<PathEntry> { $0.isPinned },
        sort: \PathEntry.uncPath
    ) private var pinnedPaths: [PathEntry]

    @Query(
        filter: #Predicate<PathEntry> { !$0.isPinned },
        sort: \PathEntry.lastVisited,
        order: .reverse
    ) private var recentPaths: [PathEntry]

    @Query(
        filter: #Predicate<MountSession> { $0.isActive }
    ) private var activeMounts: [MountSession]

    var onNavigate: ((String) -> Void)?

    var body: some View {
        List {
            // Pinned
            Section {
                ForEach(pinnedPaths) { entry in
                    sidebarRow(
                        icon: "star.fill",
                        iconColor: Design.Colors.accent,
                        label: shortLabel(entry.uncPath),
                        fullPath: entry.uncPath
                    )
                }
            } header: {
                Text("Pinned")
                    .font(Design.Fonts.sectionHeader)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }

            // Recent
            Section {
                ForEach(recentPaths.prefix(10)) { entry in
                    sidebarRow(
                        icon: "clock.arrow.circlepath",
                        iconColor: .secondary,
                        label: shortLabel(entry.uncPath),
                        fullPath: entry.uncPath
                    )
                }
            } header: {
                Text("Recent")
                    .font(Design.Fonts.sectionHeader)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }

            // Mounted
            Section {
                ForEach(activeMounts) { session in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Design.Colors.connectedGreen)
                            .frame(width: 6, height: 6)
                        Text("\(session.server)/\(session.sharePath)")
                            .font(.system(size: 13))
                            .lineLimit(1)
                    }
                }
            } header: {
                Text("Mounted")
                    .font(Design.Fonts.sectionHeader)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: Design.Browser.sidebarWidth)
    }

    private func sidebarRow(icon: String, iconColor: Color, label: String, fullPath: String) -> some View {
        Button(action: { onNavigate?(fullPath) }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
                    .font(.system(size: 13))
                Text(label)
                    .font(.system(size: 13))
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
        .help(fullPath)
    }

    private func shortLabel(_ uncPath: String) -> String {
        // Show last two components: "ICT\DEV" from "\\server\share\ICT\DEV"
        let parts = uncPath.replacingOccurrences(of: "\\\\", with: "")
            .split(separator: "\\")
        if parts.count <= 2 {
            return parts.joined(separator: "\\")
        }
        return parts.suffix(2).joined(separator: "\\")
    }
}
```

- [ ] **Step 2: Create BrowserView**

Write `NetPath/Views/Browser/BrowserView.swift`:

```swift
import SwiftUI
import SwiftData

struct BrowserView: View {
    @Bindable var viewModel: BrowserViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Address bar
            AddressBar(viewModel: viewModel)

            Divider()

            // Main content
            NavigationSplitView {
                SidebarView { uncPath in
                    if let path = UNCPath(from: uncPath) {
                        viewModel.navigateTo(path: path)
                    }
                }
            } detail: {
                ZStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let error = viewModel.errorMessage {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 32))
                                .foregroundStyle(Design.Colors.errorRed)
                            Text(error)
                                .foregroundStyle(.secondary)
                            Button("Retry") { viewModel.refresh() }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if viewModel.items.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "folder")
                                .font(.system(size: 32))
                                .foregroundStyle(.tertiary)
                            Text("This folder is empty")
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        switch viewModel.viewMode {
                        case .list:
                            DirectoryListView(viewModel: viewModel)
                        case .grid:
                            DirectoryGridView(viewModel: viewModel)
                        }
                    }
                }
            }

            Divider()

            // Status bar
            StatusBarView(
                itemCount: viewModel.items.count,
                server: viewModel.currentPath.server,
                username: viewModel.connectedAs,
                isConnected: true
            )
        }
        .frame(
            minWidth: Design.Browser.minWindowWidth,
            minHeight: Design.Browser.minWindowHeight
        )
    }
}
```

- [ ] **Step 3: Build to verify**

```bash
xcodebuild build -scheme NetPath -configuration Debug 2>&1 | tail -5
```

Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add NetPath/Views/Browser/SidebarView.swift NetPath/Views/Browser/BrowserView.swift
git commit -m "feat: add SidebarView and BrowserView composing the full file browser"
```

---

## Task 19: Settings Views

**Files:**
- Create: `NetPath/ViewModels/SettingsViewModel.swift`
- Create: `NetPath/Views/Settings/SettingsView.swift`
- Create: `NetPath/Views/Settings/GeneralSettingsView.swift`
- Create: `NetPath/Views/Settings/CredentialSettingsView.swift`
- Create: `NetPath/Views/Settings/HistorySettingsView.swift`

- [ ] **Step 1: Create SettingsViewModel**

Write `NetPath/ViewModels/SettingsViewModel.swift`:

```swift
import SwiftUI
import SwiftData
import ServiceManagement

@MainActor
@Observable
final class SettingsViewModel {
    var settings: AppSettings
    var storedServers: [(server: String, credential: ServerCredential)] = []
    var launchAtLogin: Bool {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: AppConstants.UserDefaultsKeys.launchAtLogin)
            updateLoginItem()
        }
    }

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.settings = AppSettings.fetch(from: modelContext)
        self.launchAtLogin = UserDefaults.standard.bool(forKey: AppConstants.UserDefaultsKeys.launchAtLogin)
        loadStoredServers()
    }

    func loadStoredServers() {
        guard let servers = try? KeychainService.shared.listServers() else {
            storedServers = []
            return
        }
        storedServers = servers.compactMap { server in
            guard let cred = try? KeychainService.shared.getCredential(for: server) else { return nil }
            return (server: server, credential: cred)
        }
    }

    func deleteCredential(for server: String) {
        try? KeychainService.shared.deleteCredential(for: server)
        loadStoredServers()
    }

    func saveSettings() {
        try? modelContext.save()
    }

    func clearHistory() {
        let descriptor = FetchDescriptor<PathEntry>(
            predicate: #Predicate { !$0.isPinned }
        )
        if let entries = try? modelContext.fetch(descriptor) {
            for entry in entries {
                modelContext.delete(entry)
            }
        }
        try? modelContext.save()
    }

    private func updateLoginItem() {
        let service = SMAppService.mainApp
        do {
            if launchAtLogin {
                try service.register()
            } else {
                try service.unregister()
            }
        } catch {
            print("Failed to update login item: \(error)")
        }
    }
}
```

- [ ] **Step 2: Create GeneralSettingsView**

Write `NetPath/Views/Settings/GeneralSettingsView.swift`:

```swift
import SwiftUI

struct GeneralSettingsView: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        Form {
            Section("Hotkey") {
                HStack {
                    Text("Global Shortcut")
                    Spacer()
                    Text("⌘⇧\\")
                        .font(Design.Fonts.pathMono)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(RoundedRectangle(cornerRadius: 4).fill(.quaternary))
                }
            }

            Section("Startup") {
                Toggle("Launch at Login", isOn: Binding(
                    get: { viewModel.launchAtLogin },
                    set: { viewModel.launchAtLogin = $0 }
                ))
            }

            Section("File Browser") {
                Picker("Default View", selection: Binding(
                    get: { viewModel.settings.defaultViewMode },
                    set: {
                        viewModel.settings.defaultViewMode = $0
                        viewModel.saveSettings()
                    }
                )) {
                    Text("List").tag("list")
                    Text("Grid").tag("grid")
                }

                Toggle("Show Hidden Files", isOn: Binding(
                    get: { viewModel.settings.showHiddenFiles },
                    set: {
                        viewModel.settings.showHiddenFiles = $0
                        viewModel.saveSettings()
                    }
                ))
            }

            Section("Connection") {
                Picker("Idle Disconnect", selection: Binding(
                    get: { viewModel.settings.idleTimeoutMinutes },
                    set: {
                        viewModel.settings.idleTimeoutMinutes = $0
                        viewModel.saveSettings()
                    }
                )) {
                    Text("15 minutes").tag(15)
                    Text("30 minutes").tag(30)
                    Text("1 hour").tag(60)
                    Text("Never").tag(0)
                }
            }
        }
        .formStyle(.grouped)
    }
}
```

- [ ] **Step 3: Create CredentialSettingsView**

Write `NetPath/Views/Settings/CredentialSettingsView.swift`:

```swift
import SwiftUI

struct CredentialSettingsView: View {
    @Bindable var viewModel: SettingsViewModel
    @State private var serverToDelete: String?

    var body: some View {
        Form {
            Section("Default Domain") {
                TextField("Domain (e.g. GGN)", text: Binding(
                    get: { viewModel.settings.defaultDomain ?? "" },
                    set: {
                        viewModel.settings.defaultDomain = $0.isEmpty ? nil : $0
                        viewModel.saveSettings()
                    }
                ))
            }

            Section("Stored Credentials") {
                if viewModel.storedServers.isEmpty {
                    Text("No stored credentials")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.storedServers, id: \.server) { entry in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.server)
                                    .font(.system(size: 13, weight: .medium))
                                Text("\(entry.credential.domain)\\\(entry.credential.username)")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Button(role: .destructive) {
                                serverToDelete = entry.server
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .alert("Delete Credential?", isPresented: Binding(
            get: { serverToDelete != nil },
            set: { if !$0 { serverToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) { serverToDelete = nil }
            Button("Delete", role: .destructive) {
                if let server = serverToDelete {
                    viewModel.deleteCredential(for: server)
                    serverToDelete = nil
                }
            }
        } message: {
            Text("Remove stored credentials for \(serverToDelete ?? "")?")
        }
    }
}
```

- [ ] **Step 4: Create HistorySettingsView**

Write `NetPath/Views/Settings/HistorySettingsView.swift`:

```swift
import SwiftUI
import SwiftData

struct HistorySettingsView: View {
    @Bindable var viewModel: SettingsViewModel
    @State private var showClearConfirmation = false
    @Query(sort: \PathEntry.lastVisited, order: .reverse) private var allEntries: [PathEntry]

    var body: some View {
        Form {
            Section("History Size") {
                Picker("Maximum Items", selection: Binding(
                    get: { viewModel.settings.maxHistoryItems },
                    set: {
                        viewModel.settings.maxHistoryItems = $0
                        viewModel.saveSettings()
                    }
                )) {
                    Text("25").tag(25)
                    Text("50").tag(50)
                    Text("100").tag(100)
                    Text("250").tag(250)
                }
            }

            Section("Actions") {
                Button("Clear All History", role: .destructive) {
                    showClearConfirmation = true
                }
            }

            Section("Recent Paths") {
                let unpinned = allEntries.filter { !$0.isPinned }
                if unpinned.isEmpty {
                    Text("No history")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(unpinned.prefix(20)) { entry in
                        HStack {
                            Text(entry.uncPath)
                                .font(Design.Fonts.pathMonoSmall)
                                .lineLimit(1)
                            Spacer()
                            Text(entry.lastVisited, style: .relative)
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .alert("Clear History?", isPresented: $showClearConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                viewModel.clearHistory()
            }
        } message: {
            Text("This will remove all non-pinned path history. Pinned paths will be kept.")
        }
    }
}
```

- [ ] **Step 5: Create SettingsView (tab container)**

Write `NetPath/Views/Settings/SettingsView.swift`:

```swift
import SwiftUI

struct SettingsView: View {
    @State private var viewModel: SettingsViewModel?
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Group {
            if let viewModel {
                TabView {
                    GeneralSettingsView(viewModel: viewModel)
                        .tabItem {
                            Label("General", systemImage: "gear")
                        }

                    CredentialSettingsView(viewModel: viewModel)
                        .tabItem {
                            Label("Credentials", systemImage: "key")
                        }

                    HistorySettingsView(viewModel: viewModel)
                        .tabItem {
                            Label("History", systemImage: "clock")
                        }
                }
                .frame(width: 500, height: 400)
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = SettingsViewModel(modelContext: modelContext)
            }
        }
    }
}
```

- [ ] **Step 6: Build to verify**

```bash
xcodebuild build -scheme NetPath -configuration Debug 2>&1 | tail -5
```

Expected: BUILD SUCCEEDED

- [ ] **Step 7: Commit**

```bash
git add NetPath/ViewModels/SettingsViewModel.swift NetPath/Views/Settings/
git commit -m "feat: add Settings views with General, Credentials, and History tabs"
```

---

## Task 20: AppDelegate and Menu Bar

**Files:**
- Modify: `NetPath/App/AppDelegate.swift`

- [ ] **Step 1: Implement AppDelegate**

Write `NetPath/App/AppDelegate.swift`:

```swift
import AppKit
import SwiftUI
import SwiftData

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var launcherPanel: LauncherPanel?
    private let hotkeyService = HotkeyService.shared

    var modelContainer: ModelContainer?
    var onBrowse: ((String, UNCPath) -> Void)?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupHotkey()
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotkeyService.unregister()
    }

    // MARK: - Status Bar

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "externaldrive.connected.to.line.below",
                                   accessibilityDescription: "NetPath")
            button.action = #selector(statusItemClicked)
            button.target = self
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Open NetPath", action: #selector(showLauncher), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit NetPath", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem?.menu = menu
    }

    @objc private func statusItemClicked() {
        showLauncher()
    }

    // MARK: - Hotkey

    private func setupHotkey() {
        hotkeyService.onHotkeyPressed = { [weak self] in
            self?.toggleLauncher()
        }
        hotkeyService.register()
    }

    // MARK: - Launcher

    @objc func showLauncher() {
        if launcherPanel == nil {
            launcherPanel = LauncherPanel()
        }

        guard let panel = launcherPanel, let container = modelContainer else { return }

        let launcherView = LauncherView(
            onBrowse: { [weak self] mountPoint, path in
                self?.onBrowse?(mountPoint, path)
            },
            onDismiss: { [weak self] in
                self?.hideLauncher()
            }
        )
        .modelContainer(container)

        panel.contentView = NSHostingView(rootView: launcherView)
        panel.makeKeyAndOrderFront(nil)

        // Re-center
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let panelFrame = panel.frame
            let x = screenFrame.midX - panelFrame.width / 2
            let y = screenFrame.midY + 100
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }
    }

    func hideLauncher() {
        launcherPanel?.close()
    }

    private func toggleLauncher() {
        if launcherPanel?.isVisible == true {
            hideLauncher()
        } else {
            showLauncher()
        }
    }

    @objc private func openSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add NetPath/App/AppDelegate.swift
git commit -m "feat: add AppDelegate with menu bar icon and hotkey integration"
```

---

## Task 21: NetPathApp Entry Point (Wire Everything Together)

**Files:**
- Modify: `NetPath/App/NetPathApp.swift`

- [ ] **Step 1: Update NetPathApp**

Replace `NetPath/App/NetPathApp.swift`:

```swift
import SwiftUI
import SwiftData

@main
struct NetPathApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var browserWindows: [BrowserWindowState] = []

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([PathEntry.self, MountSession.self, AppSettings.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        // Browser windows
        WindowGroup("NetPath Browser", for: BrowserWindowState.ID.self) { $id in
            if let state = browserWindows.first(where: { $0.id == id }) {
                BrowserView(
                    viewModel: BrowserViewModel(
                        mountPoint: state.mountPoint,
                        uncPath: state.uncPath,
                        modelContext: sharedModelContainer.mainContext
                    )
                )
                .navigationTitle(state.uncPath.displayPath)
            }
        }
        .modelContainer(sharedModelContainer)
        .defaultSize(
            width: Design.Browser.minWindowWidth,
            height: Design.Browser.minWindowHeight
        )

        // Settings
        Settings {
            SettingsView()
                .modelContainer(sharedModelContainer)
        }
    }

    init() {
        // Wire up the app delegate after init
        DispatchQueue.main.async { [self] in
            appDelegate.modelContainer = sharedModelContainer
            appDelegate.onBrowse = { [self] mountPoint, path in
                openBrowserWindow(mountPoint: mountPoint, uncPath: path)
            }
        }
    }

    private func openBrowserWindow(mountPoint: String, uncPath: UNCPath) {
        let state = BrowserWindowState(mountPoint: mountPoint, uncPath: uncPath)
        browserWindows.append(state)
        // Open the window
        if let url = URL(string: "netpath://browser/\(state.id.uuidString)") {
            NSWorkspace.shared.open(url)
        }
    }
}

struct BrowserWindowState: Identifiable {
    let id = UUID()
    let mountPoint: String
    let uncPath: UNCPath
}
```

- [ ] **Step 2: Build to verify full app compiles**

```bash
xcodebuild build -scheme NetPath -configuration Debug 2>&1 | tail -10
```

Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add NetPath/App/NetPathApp.swift
git commit -m "feat: wire up NetPathApp entry point with SwiftData, browser windows, and settings"
```

---

## Task 22: Run All Tests and Fix Issues

- [ ] **Step 1: Run the full test suite**

```bash
xcodebuild test -scheme NetPath -destination 'platform=macOS' 2>&1 | grep -E '(Test Case|Executed|BUILD|error:)'
```

Expected: All tests pass, BUILD SUCCEEDED

- [ ] **Step 2: Fix any compilation errors or test failures**

Address each issue individually. Common issues to watch for:
- Swift 6 strict concurrency warnings (add `@Sendable` or `@MainActor` as needed)
- SwiftData `@Model` requirements
- Missing imports

- [ ] **Step 3: Commit fixes if any**

```bash
git add -A
git commit -m "fix: resolve compilation and test issues"
```

---

## Task 23: GitHub Actions CI

**Files:**
- Create: `.github/workflows/build.yml`

- [ ] **Step 1: Create build workflow**

Write `.github/workflows/build.yml`:

```yaml
name: Build & Test

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4

      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_16.0.app

      - name: Build
        run: xcodebuild build -scheme NetPath -destination 'platform=macOS' -configuration Debug

      - name: Test
        run: xcodebuild test -scheme NetPath -destination 'platform=macOS' -configuration Debug
```

- [ ] **Step 2: Commit**

```bash
git add .github/workflows/build.yml
git commit -m "ci: add GitHub Actions build and test workflow"
```

---

## Task 24: Final Integration Verification

- [ ] **Step 1: Clean build**

```bash
xcodebuild clean build -scheme NetPath -configuration Debug 2>&1 | tail -5
```

Expected: BUILD SUCCEEDED

- [ ] **Step 2: Run all tests**

```bash
xcodebuild test -scheme NetPath -destination 'platform=macOS' 2>&1 | grep -E '(Test Suite|Test Case|Executed|BUILD)'
```

Expected: All test suites pass

- [ ] **Step 3: Verify project structure matches spec**

```bash
find NetPath NetPathHelper NetPathShared NetPathTests -name "*.swift" | sort
```

Verify all files from the spec exist.

- [ ] **Step 4: Commit any final adjustments**

```bash
git add -A
git status
# Only commit if there are changes
git diff --cached --quiet || git commit -m "chore: final adjustments after integration verification"
```
