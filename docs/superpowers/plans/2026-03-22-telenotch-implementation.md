# Telenotch Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build Telenotch — a macOS menu bar teleprompter app with a floating panel, 60fps auto-scroll, 5 themes, mirror mode, keyboard shortcuts, and .txt file import.

**Architecture:** AppDelegate-first (no `@main` SwiftUI App struct). `NSStatusItem` in menu bar toggles a reusable `NSPanel` subclass. All state in a single `PrompterState` ObservableObject. SwiftUI views hosted via `NSHostingController`. Timer-driven 60fps scrolling with manual `offset` (no ScrollView).

**Tech Stack:** Swift 5.9+, SwiftUI, AppKit, macOS 13.0+, xcodegen (project scaffolding), xcodebuild (compile verification), no third-party runtime dependencies.

---

## Files to Create

| File | Responsibility |
|------|---------------|
| `project.yml` | xcodegen project spec — generates Telenotch.xcodeproj |
| `Telenotch/main.swift` | `NSApplication` entry point, delegates to `AppDelegate` |
| `Telenotch/AppDelegate.swift` | `NSStatusItem`, panel lifecycle, keyboard monitor |
| `Telenotch/TelenotchPanel.swift` | `NSPanel` subclass — borderless, floating, clear bg, corner radius |
| `Telenotch/PrompterState.swift` | `ObservableObject` — all `@Published` state, Timer, UserDefaults |
| `Telenotch/Theme.swift` | `enum Theme` — 5 cases with `background`, `textColor`, `accentColor`, `next()` |
| `Telenotch/TeleprompterView.swift` | Root SwiftUI view hosted in panel — wires ControlBar + ScrollingTextView |
| `Telenotch/ControlBar.swift` | Top control strip — all buttons, sliders, labels |
| `Telenotch/ScrollingTextView.swift` | Clipped text + offset scrolling + PreferenceKey height measurement + gradients |
| `Telenotch/Info.plist` | `LSUIElement=YES`, bundle ID, app name |
| `CLAUDE.md` | Project docs — tech, architecture, conventions |
| `TODO.md` | Feature checklist |
| `.gitignore` | Swift/Xcode ignores |

---

## Task 1: Project Scaffolding

**Files:**
- Create: `.gitignore`
- Create: `CLAUDE.md`
- Create: `TODO.md`
- Create: `project.yml`
- Create: `Telenotch/Info.plist`
- Create: `Telenotch/main.swift` (minimal)
- Generate: `Telenotch.xcodeproj` via xcodegen

- [ ] **Step 1: Configure git identity**

```bash
cd /Users/raajpatkar/Code/Open-source101/telenotch
git config user.name "Raaj Patkar"
git config user.email "raajpatkar@gmail.com"
```

- [ ] **Step 2: Create .gitignore**

Create `/Users/raajpatkar/Code/Open-source101/telenotch/.gitignore`:

```
# Xcode
*.xcuserstate
xcuserdata/
DerivedData/
*.moved-aside
*.hmap
*.ipa

# Swift
.build/
.swiftpm/

# macOS
.DS_Store

# CocoaPods (unused but safe)
Pods/

# XcodeGen
# (project.yml is committed, xcodeproj is generated)
```

- [ ] **Step 3: Install xcodegen**

```bash
brew install xcodegen
```

Expected: xcodegen installed (or already installed — no error).

- [ ] **Step 4: Create project.yml**

Create `/Users/raajpatkar/Code/Open-source101/telenotch/project.yml`:

```yaml
name: Telenotch
options:
  bundleIdPrefix: com.raajpatkar
  deploymentTarget:
    macOS: "13.0"
  xcodeVersion: "15.0"

targets:
  Telenotch:
    type: application
    platform: macOS
    sources:
      - path: Telenotch
    info:
      path: Telenotch/Info.plist
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.raajpatkar.telenotch
        MACOSX_DEPLOYMENT_TARGET: "13.0"
        SWIFT_VERSION: "5.9"
        CODE_SIGN_STYLE: Automatic
        DEVELOPMENT_TEAM: ""
        ENABLE_HARDENED_RUNTIME: YES
        INFOPLIST_FILE: Telenotch/Info.plist
```

- [ ] **Step 5: Create Telenotch/Info.plist**

Create `/Users/raajpatkar/Code/Open-source101/telenotch/Telenotch/Info.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.raajpatkar.telenotch</string>
    <key>CFBundleName</key>
    <string>Telenotch</string>
    <key>CFBundleDisplayName</key>
    <string>Telenotch</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
```

- [ ] **Step 6: Create minimal main.swift**

Create `/Users/raajpatkar/Code/Open-source101/telenotch/Telenotch/main.swift`:

```swift
import AppKit

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
```

- [ ] **Step 7: Create minimal AppDelegate.swift**

Create `/Users/raajpatkar/Code/Open-source101/telenotch/Telenotch/AppDelegate.swift`:

```swift
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Phase 2 will fill this in
    }
}
```

- [ ] **Step 8: Create Assets.xcassets**

```bash
mkdir -p /Users/raajpatkar/Code/Open-source101/telenotch/Telenotch/Assets.xcassets
cat > /Users/raajpatkar/Code/Open-source101/telenotch/Telenotch/Assets.xcassets/Contents.json << 'EOF'
{
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF
```

- [ ] **Step 9: Generate Xcode project**

```bash
cd /Users/raajpatkar/Code/Open-source101/telenotch
xcodegen generate
```

Expected output: `Generating project Telenotch` — creates `Telenotch.xcodeproj/`.

- [ ] **Step 10: Verify it compiles**

```bash
cd /Users/raajpatkar/Code/Open-source101/telenotch
xcodebuild -project Telenotch.xcodeproj -scheme Telenotch -destination "platform=macOS" build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

If it fails with signing errors, add `CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" CODE_SIGNING_ALLOWED=NO` to the build command.

- [ ] **Step 11: Create CLAUDE.md**

Create `/Users/raajpatkar/Code/Open-source101/telenotch/CLAUDE.md`:

```markdown
# Telenotch — Notch Teleprompter

A macOS menu bar teleprompter app that lives near the notch. Clicking the menu bar icon reveals a floating panel with smooth auto-scrolling text, 5 color themes, mirror mode, and keyboard shortcuts.

## Tech Stack

- Swift 5.9+
- SwiftUI (views inside the panel)
- AppKit (NSStatusItem, NSPanel, NSEvent)
- macOS 13.0+ deployment target
- No third-party dependencies

## Build

1. Open `Telenotch.xcodeproj` in Xcode
2. Select the `Telenotch` scheme
3. Press Cmd+R to build and run
4. The app will appear in your menu bar (no Dock icon — LSUIElement=YES)

To regenerate the Xcode project after editing `project.yml`:
```bash
xcodegen generate
```

To build from command line:
```bash
xcodebuild -project Telenotch.xcodeproj -scheme Telenotch build
```

## Project Structure

| File | Role |
|------|------|
| `main.swift` | `NSApplication` entry point |
| `AppDelegate.swift` | `NSStatusItem` creation, `NSPanel` lifecycle, keyboard event monitor |
| `TelenotchPanel.swift` | `NSPanel` subclass — borderless, floating, always-on-top, clear background |
| `PrompterState.swift` | `ObservableObject` — all app state, 60fps Timer, UserDefaults persistence |
| `Theme.swift` | `enum Theme` — 5 color themes with background/text/accent colors |
| `TeleprompterView.swift` | Root SwiftUI view hosted inside the panel |
| `ControlBar.swift` | Top control strip — all buttons and sliders |
| `ScrollingTextView.swift` | Manual-offset text scroll view with gradient fades and mirror support |
| `Info.plist` | Bundle config — `LSUIElement=YES` suppresses Dock icon |
| `project.yml` | xcodegen spec — run `xcodegen generate` to regenerate `.xcodeproj` |

## Architecture

**AppDelegate-first.** No SwiftUI `@main`. `main.swift` boots `NSApplication` and sets `AppDelegate` as delegate. `AppDelegate` creates a single `TelenotchPanel` (reused via show/hide, never destroyed) and an `NSStatusItem`. Clicking the status item toggles `panel.orderFront` / `panel.orderOut`.

**PrompterState** is the single source of truth. Created in `AppDelegate`, injected into all SwiftUI views as `.environmentObject`. It owns the 60fps `Timer`, all `@Published` properties, and UserDefaults persistence.

**Scrolling** is manual — no `ScrollView`. A `Text` view inside a `.clipped()` container uses `.offset(y: -scrollOffset)`. A `PreferenceKey` bubbles up text content height from an inner `GeometryReader` so `maxScrollOffset = textHeight - visibleHeight` can be computed. The timer increments `scrollOffset` by `speed / 60` per tick, capped at `maxScrollOffset`.

**Keyboard shortcuts** use `NSEvent.addLocalMonitorForEvents(matching: .keyDown)` in `AppDelegate`. The monitor is installed on panel show and removed on panel hide — never leaked.

## Key Conventions

- All shared state lives in `PrompterState` — no `@State` for cross-component data
- Themes are a Swift `enum` with inline `Color` hex values — no asset catalog colors
- The 60fps timer lives in `PrompterState`, not in views
- `PreferenceKey` (`TextHeightKey`) bubbles text height from `GeometryReader` to `PrompterState`
- `NSEvent` local monitor for keyboard (not SwiftUI `.onKeyPress`)
- UserDefaults keys are `static let` constants defined in `PrompterState`

## Known Issues / Limitations

_None at v1.0_

## Git

- Owner: raajpatkar@gmail.com
- Commits use conventional prefixes: `feat:`, `fix:`, `chore:`, `docs:`
```

- [ ] **Step 12: Create TODO.md**

Create `/Users/raajpatkar/Code/Open-source101/telenotch/TODO.md`:

```markdown
# Telenotch — Development Checklist

- [ ] Project scaffolding and git init
- [ ] Menu bar agent setup (NSStatusItem, LSUIElement)
- [ ] Floating NSPanel anchored below notch
- [ ] Teleprompter scrolling view (60fps timer)
- [ ] Control bar (play/pause, speed, font size)
- [ ] Edit mode toggle (read vs TextEditor)
- [ ] Mirror mode
- [ ] 5 color themes
- [ ] Keyboard shortcuts (Space, arrows, R, Esc)
- [ ] Top/bottom gradient fade on scroll area
- [ ] Drag-and-drop / import .txt files
- [ ] Visual polish and rounded corners
- [ ] Persistence (UserDefaults for speed, fontSize, theme, script)
- [ ] Final cleanup and README
```

- [ ] **Step 13: Add Telenotch.xcodeproj to .gitignore internals and commit**

Add to `.gitignore` (append):
```
# Regenerated by xcodegen — commit project.yml, not xcodeproj user data
Telenotch.xcodeproj/project.xcworkspace/
Telenotch.xcodeproj/xcuserdata/
```

Then commit:
```bash
cd /Users/raajpatkar/Code/Open-source101/telenotch
git add .gitignore CLAUDE.md TODO.md project.yml Telenotch/ Telenotch.xcodeproj/project.pbxproj
git commit -m "chore: scaffold project structure with CLAUDE.md and TODO.md"
```

Update `TODO.md`: mark `Project scaffolding and git init` as `[x]`.

---

## Task 2: Menu Bar Agent + Floating Panel Shell

**Files:**
- Modify: `Telenotch/AppDelegate.swift`
- Create: `Telenotch/TelenotchPanel.swift`

- [ ] **Step 1: Create TelenotchPanel.swift**

Create `/Users/raajpatkar/Code/Open-source101/telenotch/Telenotch/TelenotchPanel.swift`:

```swift
import AppKit

class TelenotchPanel: NSPanel {

    static let width: CGFloat = 380
    static let height: CGFloat = 520

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: TelenotchPanel.width, height: TelenotchPanel.height),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        configure()
    }

    private func configure() {
        isFloatingPanel = true
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isMovableByWindowBackground = true
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true

        // Rounded corners on the content layer
        contentView?.wantsLayer = true
        contentView?.layer?.cornerRadius = 16
        contentView?.layer?.masksToBounds = true
    }

    /// Position centered horizontally just below the menu bar.
    /// Uses the correct Cocoa coordinate math (Y origin is bottom-left).
    func positionBelowMenuBar() {
        guard let screen = NSScreen.main else { return }

        let menuBarHeight = screen.frame.maxY - screen.visibleFrame.maxY
        // Top of panel = bottom of menu bar minus 8pt breathing room
        let panelTop = screen.frame.maxY - menuBarHeight - 8
        let panelY = panelTop - TelenotchPanel.height

        // Center horizontally, clamped so panel never overflows right edge
        var panelX = screen.visibleFrame.midX - TelenotchPanel.width / 2
        let maxX = screen.visibleFrame.maxX - TelenotchPanel.width - 8
        panelX = min(panelX, maxX)

        setFrameOrigin(NSPoint(x: panelX, y: panelY))
    }
}
```

- [ ] **Step 2: Implement AppDelegate.swift with menu bar + panel**

Replace `/Users/raajpatkar/Code/Open-source101/telenotch/Telenotch/AppDelegate.swift`:

```swift
import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem!
    private var panel: TelenotchPanel!

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupPanel()
    }

    // MARK: - Status Item

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "text.alignleft", accessibilityDescription: "Telenotch")
            button.action = #selector(togglePanel)
            button.target = self
        }
    }

    // MARK: - Panel

    private func setupPanel() {
        panel = TelenotchPanel()

        // Placeholder view until Phase 4 wires in TeleprompterView
        let placeholder = NSHostingController(
            rootView: Rectangle()
                .fill(Color(red: 0.1, green: 0.1, blue: 0.18))
                .cornerRadius(16)
        )
        panel.contentViewController = placeholder
    }

    @objc private func togglePanel() {
        if panel.isVisible {
            hidePanel()
        } else {
            showPanel()
        }
    }

    func showPanel() {
        panel.positionBelowMenuBar()
        panel.orderFront(nil)
    }

    func hidePanel() {
        panel.orderOut(nil)
    }
}
```

- [ ] **Step 3: Verify it compiles**

```bash
cd /Users/raajpatkar/Code/Open-source101/telenotch
xcodebuild -project Telenotch.xcodeproj -scheme Telenotch -destination "platform=macOS" build CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Update TODO.md, commit**

Mark as `[x]`: `Menu bar agent setup (NSStatusItem, LSUIElement)` and `Floating NSPanel anchored below notch`.

```bash
cd /Users/raajpatkar/Code/Open-source101/telenotch
git add Telenotch/AppDelegate.swift Telenotch/TelenotchPanel.swift TODO.md
git commit -m "feat: menu bar agent with floating panel anchored below notch"
```

---

## Task 3: State Model + Themes

**Files:**
- Create: `Telenotch/Theme.swift`
- Create: `Telenotch/PrompterState.swift`

- [ ] **Step 1: Create Theme.swift**

Create `/Users/raajpatkar/Code/Open-source101/telenotch/Telenotch/Theme.swift`:

```swift
import SwiftUI

enum Theme: String, CaseIterable {
    case midnight
    case warmGlow
    case ocean
    case forest
    case rose

    var name: String {
        switch self {
        case .midnight: return "Midnight"
        case .warmGlow: return "Warm Glow"
        case .ocean:    return "Ocean"
        case .forest:   return "Forest"
        case .rose:     return "Rosé"
        }
    }

    var background: Color {
        switch self {
        case .midnight: return Color(hex: "#1a1a2e")
        case .warmGlow: return Color(hex: "#1c1008")
        case .ocean:    return Color(hex: "#0a1628")
        case .forest:   return Color(hex: "#0d1f0d")
        case .rose:     return Color(hex: "#1f0d14")
        }
    }

    var textColor: Color {
        switch self {
        case .midnight: return Color(hex: "#e0e0ff")
        case .warmGlow: return Color(hex: "#fbbf24")
        case .ocean:    return Color(hex: "#67e8f9")
        case .forest:   return Color(hex: "#86efac")
        case .rose:     return Color(hex: "#f9a8d4")
        }
    }

    var accentColor: Color {
        switch self {
        case .midnight: return Color(hex: "#a78bfa")
        case .warmGlow: return Color(hex: "#f97316")
        case .ocean:    return Color(hex: "#38bdf8")
        case .forest:   return Color(hex: "#34d399")
        case .rose:     return Color(hex: "#fb7185")
        }
    }

    func next() -> Theme {
        let all = Theme.allCases
        let idx = all.firstIndex(of: self)!
        return all[(idx + 1) % all.count]
    }
}

// MARK: - Hex Color Initializer

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255
        )
    }
}
```

- [ ] **Step 2: Create PrompterState.swift**

Create `/Users/raajpatkar/Code/Open-source101/telenotch/Telenotch/PrompterState.swift`:

```swift
import Foundation
import Combine
import SwiftUI

class PrompterState: ObservableObject {

    // MARK: - UserDefaults Keys

    private enum Keys {
        static let script       = "telenotch.script"
        static let speed        = "telenotch.speed"
        static let fontSize     = "telenotch.fontSize"
        static let theme        = "telenotch.theme"
    }

    static let defaultScript = """
    Welcome to Telenotch — your notch teleprompter.

    Click the edit button (pencil icon) above to replace this with your own script, or drag a .txt file onto this window.

    Tips:
    • Space bar to play/pause
    • Up/Down arrows to adjust speed
    • R to reset to the top
    • Escape to hide the panel

    Break your script into short paragraphs for easier reading. Leave blank lines between sections for natural breathing room.

    Happy presenting! ✨
    """

    // MARK: - Published State

    @Published var script: String {
        didSet { UserDefaults.standard.set(script, forKey: Keys.script) }
    }
    @Published var isPlaying: Bool = false {
        didSet {
            if isPlaying {
                startTimer()
            } else {
                stopTimer()
            }
        }
    }
    @Published var speed: Double {
        didSet {
            speed = min(max(speed, 5), 120)
            UserDefaults.standard.set(speed, forKey: Keys.speed)
        }
    }
    @Published var fontSize: Double {
        didSet {
            fontSize = min(max(fontSize, 14), 48)
            UserDefaults.standard.set(fontSize, forKey: Keys.fontSize)
        }
    }
    @Published var isMirrored: Bool = false
    @Published var isEditing: Bool = false {
        didSet {
            if isEditing { isPlaying = false }
        }
    }
    @Published var currentTheme: Theme {
        didSet { UserDefaults.standard.set(currentTheme.rawValue, forKey: Keys.theme) }
    }
    @Published var scrollOffset: Double = 0
    @Published var maxScrollOffset: Double = 0

    // MARK: - Timer

    private var scrollTimer: Timer?

    // MARK: - Init

    init() {
        let defaults = UserDefaults.standard
        self.script = defaults.string(forKey: Keys.script) ?? PrompterState.defaultScript
        self.speed = defaults.object(forKey: Keys.speed) as? Double ?? 35
        self.fontSize = defaults.object(forKey: Keys.fontSize) as? Double ?? 24
        let themeRaw = defaults.string(forKey: Keys.theme) ?? Theme.midnight.rawValue
        self.currentTheme = Theme(rawValue: themeRaw) ?? .midnight
    }

    deinit {
        scrollTimer?.invalidate()
    }

    // MARK: - Timer Control

    private func startTimer() {
        guard scrollTimer == nil else { return }
        // Use Timer(timeInterval:repeats:block:) — do NOT use Timer.scheduledTimer here,
        // because scheduledTimer already adds to .default mode; adding to .common afterward
        // would register it twice, causing double-speed scrolling.
        let t = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(t, forMode: .common)
        scrollTimer = t
    }

    private func stopTimer() {
        scrollTimer?.invalidate()
        scrollTimer = nil
    }

    private func tick() {
        guard isPlaying else { return }
        let newOffset = scrollOffset + speed / 60.0
        if newOffset >= maxScrollOffset {
            scrollOffset = maxScrollOffset
            isPlaying = false
        } else {
            scrollOffset = newOffset
        }
    }

    // MARK: - Actions

    func reset() {
        scrollOffset = 0
    }

    func cycleTheme() {
        currentTheme = currentTheme.next()
    }
}
```

- [ ] **Step 3: Wire PrompterState into AppDelegate**

Update `AppDelegate.swift` — add `state` property and inject as environmentObject:

```swift
import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem!
    private var panel: TelenotchPanel!
    let state = PrompterState()           // single instance

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupPanel()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "text.alignleft", accessibilityDescription: "Telenotch")
            button.action = #selector(togglePanel)
            button.target = self
        }
    }

    private func setupPanel() {
        panel = TelenotchPanel()

        // Placeholder — will be replaced in Task 5
        let placeholder = NSHostingController(
            rootView: Rectangle()
                .fill(Color(red: 0.1, green: 0.1, blue: 0.18))
                .cornerRadius(16)
                .environmentObject(state)
        )
        panel.contentViewController = placeholder
    }

    @objc private func togglePanel() {
        if panel.isVisible {
            hidePanel()
        } else {
            showPanel()
        }
    }

    func showPanel() {
        panel.positionBelowMenuBar()
        panel.orderFront(nil)
    }

    func hidePanel() {
        panel.orderOut(nil)
    }
}
```

- [ ] **Step 4: Verify it compiles**

```bash
cd /Users/raajpatkar/Code/Open-source101/telenotch
xcodebuild -project Telenotch.xcodeproj -scheme Telenotch -destination "platform=macOS" build CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Update TODO.md, commit**

Mark as `[x]`: `5 color themes`, `Persistence (UserDefaults for speed, fontSize, theme, script)`.

```bash
cd /Users/raajpatkar/Code/Open-source101/telenotch
git add Telenotch/Theme.swift Telenotch/PrompterState.swift Telenotch/AppDelegate.swift TODO.md
git commit -m "feat: PrompterState with timer, themes, and UserDefaults persistence"
```

---

## Task 4: Scrolling Text View

**Files:**
- Create: `Telenotch/ScrollingTextView.swift`

- [ ] **Step 1: Create ScrollingTextView.swift**

Create `/Users/raajpatkar/Code/Open-source101/telenotch/Telenotch/ScrollingTextView.swift`:

```swift
import SwiftUI

// MARK: - PreferenceKey for measuring text content height

struct TextHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

// MARK: - ScrollingTextView

struct ScrollingTextView: View {
    @EnvironmentObject var state: PrompterState

    var body: some View {
        GeometryReader { outerGeo in
            ZStack(alignment: .top) {
                // Scrolling text — offset drives the scroll.
                // .fixedSize(vertical: true) lets the VStack grow to its natural content height
                // so the inner GeometryReader can measure the true text height.
                // .clipped() is on the ZStack below, NOT here, so the measurement isn't
                // constrained to the visible frame before the PreferenceKey can read it.
                textContent
                    .fixedSize(horizontal: false, vertical: true)
                    .background(
                        // Measure text height via background GeometryReader
                        GeometryReader { innerGeo in
                            Color.clear
                                .preference(key: TextHeightKey.self, value: innerGeo.size.height)
                        }
                    )
                    .scaleEffect(x: state.isMirrored ? -1 : 1, y: 1)
                    .offset(y: -state.scrollOffset)
                    .onPreferenceChange(TextHeightKey.self) { textHeight in
                        let visibleHeight = outerGeo.size.height
                        state.maxScrollOffset = max(0, textHeight - visibleHeight)
                    }

                // Top gradient overlay (rendered on top of clipped text)
                VStack {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            state.currentTheme.background.opacity(0.95),
                            Color.clear
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 60)
                    Spacer()
                }
                .allowsHitTesting(false)

                // Bottom gradient overlay
                VStack {
                    Spacer()
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.clear,
                            state.currentTheme.background.opacity(0.95)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 60)
                }
                .allowsHitTesting(false)
            }
            // .clipped() on the ZStack — this is what prevents text from visually
            // overflowing the visible area. Must be OUTSIDE the text layer so the
            // GeometryReader can still measure the full natural height first.
            .clipped()
        }
    }

    private var textContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(state.script)
                .font(.system(size: state.fontSize))
                .foregroundColor(state.currentTheme.textColor)
                .lineSpacing(8)
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.disabled)
        }
    }
}
```

- [ ] **Step 2: Verify it compiles**

```bash
cd /Users/raajpatkar/Code/Open-source101/telenotch
xcodebuild -project Telenotch.xcodeproj -scheme Telenotch -destination "platform=macOS" build CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
cd /Users/raajpatkar/Code/Open-source101/telenotch
git add Telenotch/ScrollingTextView.swift
git commit -m "feat: scrolling text view with gradient fades and mirror mode"
```

---

## Task 5: Control Bar

**Files:**
- Create: `Telenotch/ControlBar.swift`

- [ ] **Step 1: Create ControlBar.swift**

Create `/Users/raajpatkar/Code/Open-source101/telenotch/Telenotch/ControlBar.swift`:

```swift
import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ControlBar: View {
    @EnvironmentObject var state: PrompterState
    var onClose: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            // Row 1: action buttons
            HStack(spacing: 12) {
                // Close
                toolButton(systemImage: "xmark", action: onClose)

                // Import
                toolButton(systemImage: "doc.text") { importFile() }

                Spacer()

                // Theme cycle
                Button(action: { state.cycleTheme() }) {
                    Text(state.currentTheme.name)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(state.currentTheme.accentColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(state.currentTheme.accentColor.opacity(0.15))
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)

                // Mirror
                toolButton(
                    systemImage: "arrow.left.and.right",
                    active: state.isMirrored
                ) { state.isMirrored.toggle() }

                // Edit
                toolButton(
                    systemImage: state.isEditing ? "checkmark" : "pencil",
                    active: state.isEditing
                ) { toggleEdit() }
            }

            // Row 2: transport controls
            HStack(spacing: 14) {
                // Reset
                toolButton(systemImage: "arrow.counterclockwise") { state.reset() }

                // Play / Pause
                Button(action: { state.isPlaying.toggle() }) {
                    Image(systemName: state.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(state.isEditing
                            ? state.currentTheme.textColor.opacity(0.3)
                            : state.currentTheme.accentColor)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
                .disabled(state.isEditing)

                Spacer()

                // Speed indicator
                Text("\(Int(state.speed)) pt/s")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(state.currentTheme.textColor.opacity(0.6))
                    .frame(minWidth: 54, alignment: .trailing)
            }

            // Row 3: speed slider
            HStack(spacing: 8) {
                Image(systemName: "tortoise")
                    .font(.system(size: 10))
                    .foregroundColor(state.currentTheme.textColor.opacity(0.4))
                Slider(value: $state.speed, in: 5...120, step: 1)
                    .tint(state.currentTheme.accentColor)
                Image(systemName: "hare")
                    .font(.system(size: 10))
                    .foregroundColor(state.currentTheme.textColor.opacity(0.4))
            }

            // Row 4: font size slider
            HStack(spacing: 8) {
                Image(systemName: "textformat.size.smaller")
                    .font(.system(size: 10))
                    .foregroundColor(state.currentTheme.textColor.opacity(0.4))
                Slider(value: $state.fontSize, in: 14...48, step: 1)
                    .tint(state.currentTheme.accentColor)
                Image(systemName: "textformat.size.larger")
                    .font(.system(size: 10))
                    .foregroundColor(state.currentTheme.textColor.opacity(0.4))
                Text("\(Int(state.fontSize))pt")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(state.currentTheme.textColor.opacity(0.6))
                    .frame(minWidth: 32, alignment: .trailing)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(state.currentTheme.background.opacity(0.6))
    }

    // MARK: - Helpers

    @ViewBuilder
    private func toolButton(
        systemImage: String,
        active: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(active
                    ? state.currentTheme.accentColor
                    : state.currentTheme.textColor.opacity(0.7))
                .frame(width: 28, height: 28)
                .background(active
                    ? state.currentTheme.accentColor.opacity(0.15)
                    : Color.clear)
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }

    private func toggleEdit() {
        if state.isEditing {
            // Exiting edit — reset scroll, defer maxScrollOffset recompute so layout settles
            state.isEditing = false
            state.scrollOffset = 0
            DispatchQueue.main.async {
                // Force maxScrollOffset recompute happens via PreferenceKey after layout
                // Trigger a no-op publish to nudge SwiftUI layout pass
                state.objectWillChange.send()
            }
        } else {
            state.isEditing = true
        }
    }

    private func importFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.plainText]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            do {
                let content = try String(contentsOf: url, encoding: .utf8)
                DispatchQueue.main.async {
                    state.script = content
                    state.scrollOffset = 0
                }
            } catch {
                // File read failed — silently ignore for v1.0
            }
        }
    }
}
```

- [ ] **Step 2: Verify it compiles**

```bash
cd /Users/raajpatkar/Code/Open-source101/telenotch
xcodebuild -project Telenotch.xcodeproj -scheme Telenotch -destination "platform=macOS" build CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
cd /Users/raajpatkar/Code/Open-source101/telenotch
git add Telenotch/ControlBar.swift
git commit -m "feat: control bar with all controls, sliders, and theme cycling"
```

---

## Task 6: TeleprompterView + Edit Mode + Wire Everything Together

**Files:**
- Create: `Telenotch/TeleprompterView.swift`
- Modify: `Telenotch/AppDelegate.swift` (swap placeholder for real view)

- [ ] **Step 1: Create TeleprompterView.swift**

Create `/Users/raajpatkar/Code/Open-source101/telenotch/Telenotch/TeleprompterView.swift`:

```swift
import SwiftUI
import UniformTypeIdentifiers

struct TeleprompterView: View {
    @EnvironmentObject var state: PrompterState
    var onClose: () -> Void

    var body: some View {
        ZStack {
            // Theme background
            state.currentTheme.background.opacity(0.95)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ControlBar(onClose: onClose)

                Divider()
                    .overlay(state.currentTheme.accentColor.opacity(0.2))

                // Script content area
                if state.isEditing {
                    TextEditor(text: $state.script)
                        .font(.system(size: state.fontSize))
                        .foregroundColor(state.currentTheme.textColor)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                } else {
                    ScrollingTextView()
                }
            }
        }
        .cornerRadius(16)
        // Drag-and-drop support
        .onDrop(of: [UTType.fileURL, UTType.plainText], isTargeted: nil) { providers in
            handleDrop(providers: providers)
        }
    }

    // MARK: - Drag and Drop

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        // Try fileURL first
        if let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) }) {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                guard let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil),
                      url.pathExtension.lowercased() == "txt" else { return }
                do {
                    let content = try String(contentsOf: url, encoding: .utf8)
                    DispatchQueue.main.async {
                        state.script = content
                        state.scrollOffset = 0
                    }
                } catch {}
            }
            return true
        }

        // Try plain text (e.g. dragged from a browser)
        if let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) }) {
            provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { item, _ in
                let text: String?
                if let data = item as? Data {
                    text = String(data: data, encoding: .utf8)
                } else if let string = item as? String {
                    text = string
                } else {
                    text = nil
                }
                guard let content = text else { return }
                DispatchQueue.main.async {
                    state.script = content
                    state.scrollOffset = 0
                }
            }
            return true
        }

        return false
    }
}
```

- [ ] **Step 2: Update AppDelegate to use TeleprompterView**

Replace the `setupPanel()` method in `AppDelegate.swift`:

```swift
private func setupPanel() {
    panel = TelenotchPanel()

    let rootView = TeleprompterView(onClose: { [weak self] in
        self?.hidePanel()
    })
    .environmentObject(state)

    let hostingController = NSHostingController(rootView: rootView)
    hostingController.view.frame = NSRect(
        x: 0, y: 0,
        width: TelenotchPanel.width,
        height: TelenotchPanel.height
    )
    panel.contentViewController = hostingController
}
```

- [ ] **Step 3: Verify it compiles**

```bash
cd /Users/raajpatkar/Code/Open-source101/telenotch
xcodebuild -project Telenotch.xcodeproj -scheme Telenotch -destination "platform=macOS" build CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Update TODO.md, commit**

Mark as `[x]`: `Teleprompter scrolling view (60fps timer)`, `Control bar (play/pause, speed, font size)`, `Edit mode toggle (read vs TextEditor)`, `Mirror mode`.

```bash
cd /Users/raajpatkar/Code/Open-source101/telenotch
git add Telenotch/TeleprompterView.swift Telenotch/AppDelegate.swift TODO.md
git commit -m "feat: edit mode with TextEditor and scroll reset"
```

---

## Task 7: Keyboard Shortcuts

**Files:**
- Modify: `Telenotch/AppDelegate.swift`

- [ ] **Step 1: Add keyboard monitor to AppDelegate**

Add the following to `AppDelegate.swift` (add property + updated show/hide methods):

```swift
// Add this property alongside statusItem and panel:
private var keyboardMonitor: Any?

// Replace showPanel() and hidePanel():
func showPanel() {
    panel.positionBelowMenuBar()
    panel.orderFront(nil)
    installKeyboardMonitor()
}

func hidePanel() {
    panel.orderOut(nil)
    removeKeyboardMonitor()   // safe here — no animation yet (animation added in Task 9)
}

// Add these two methods:
private func installKeyboardMonitor() {
    guard keyboardMonitor == nil else { return }
    keyboardMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
        guard let self = self, self.panel.isVisible else { return event }
        return self.handleKeyDown(event)
    }
}

private func removeKeyboardMonitor() {
    if let monitor = keyboardMonitor {
        NSEvent.removeMonitor(monitor)
        keyboardMonitor = nil
    }
}

private func handleKeyDown(_ event: NSEvent) -> NSEvent? {
    switch event.keyCode {
    case 49: // Space
        if !state.isEditing {
            state.isPlaying.toggle()
            return nil
        }
    case 126: // Up arrow
        state.speed = min(state.speed + 5, 120)
        return nil
    case 125: // Down arrow
        state.speed = max(state.speed - 5, 5)
        return nil
    case 15: // R key
        if !state.isEditing {
            state.reset()
            return nil
        }
    case 53: // Escape
        hidePanel()
        return nil
    default:
        break
    }
    return event
}
```

- [ ] **Step 2: Verify it compiles**

```bash
cd /Users/raajpatkar/Code/Open-source101/telenotch
xcodebuild -project Telenotch.xcodeproj -scheme Telenotch -destination "platform=macOS" build CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Update TODO.md, commit**

Mark as `[x]`: `Keyboard shortcuts (Space, arrows, R, Esc)`.

```bash
cd /Users/raajpatkar/Code/Open-source101/telenotch
git add Telenotch/AppDelegate.swift TODO.md
git commit -m "feat: keyboard shortcuts via NSEvent local monitor"
```

---

## Task 8: Drag-and-Drop + File Import (already in TeleprompterView)

The drag-and-drop handler was written in Task 6's `TeleprompterView.swift` and the import button was written in Task 5's `ControlBar.swift`. This task verifies both work correctly and updates the checklist.

- [ ] **Step 1: Verify both import paths compile and are wired**

```bash
cd /Users/raajpatkar/Code/Open-source101/telenotch
grep -n "onDrop\|importFile\|NSOpenPanel" Telenotch/TeleprompterView.swift Telenotch/ControlBar.swift
```

Expected: lines found in both files confirming the implementations are present.

- [ ] **Step 2: Update TODO.md, commit**

Mark as `[x]`: `Drag-and-drop / import .txt files`.

```bash
cd /Users/raajpatkar/Code/Open-source101/telenotch
git add TODO.md
git commit -m "feat: drag-and-drop and file import for .txt files"
```

---

## Task 9: Visual Polish

**Files:**
- Modify: `Telenotch/TeleprompterView.swift`
- Modify: `Telenotch/ControlBar.swift`
- Modify: `Telenotch/TelenotchPanel.swift`

- [ ] **Step 1: Confirm panel shadow**

`TelenotchPanel` already sets `hasShadow = true` in Task 2. This is the correct mechanism for `NSPanel` — do NOT add shadow via `contentView?.layer?.shadowColor` etc., because `contentView.layer.masksToBounds = true` (also set in Task 2 for corner radius) clips layer shadows. The `NSPanel.hasShadow` path is handled by the window compositor at a level above the layer, so it is unaffected by `masksToBounds`. No code change needed in this step.

- [ ] **Step 2: Add fade-in animation when panel appears**

In `TeleprompterView.swift`, add `.transition(.opacity)` to the root `ZStack` and animate the panel show with `withAnimation`:

In `AppDelegate.showPanel()`:
```swift
func showPanel() {
    panel.positionBelowMenuBar()
    panel.alphaValue = 0
    panel.orderFront(nil)
    NSAnimationContext.runAnimationGroup { ctx in
        ctx.duration = 0.18
        panel.animator().alphaValue = 1.0
    }
    installKeyboardMonitor()
}
```

In `AppDelegate.hidePanel()`:
```swift
func hidePanel() {
    // Remove monitor in completion handler (not before) to avoid a gap where
    // the panel is still visible during the fade but keys are no longer intercepted.
    NSAnimationContext.runAnimationGroup({ ctx in
        ctx.duration = 0.12
        panel.animator().alphaValue = 0
    }, completionHandler: { [weak self] in
        self?.panel.orderOut(nil)
        self?.panel.alphaValue = 1.0
        self?.removeKeyboardMonitor()
    })
}
```

- [ ] **Step 3: Verify it compiles**

```bash
cd /Users/raajpatkar/Code/Open-source101/telenotch
xcodebuild -project Telenotch.xcodeproj -scheme Telenotch -destination "platform=macOS" build CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Update TODO.md, commit**

Mark as `[x]`: `Visual polish and rounded corners`, `Top/bottom gradient fade on scroll area`.

```bash
cd /Users/raajpatkar/Code/Open-source101/telenotch
git add Telenotch/TelenotchPanel.swift Telenotch/AppDelegate.swift TODO.md
git commit -m "feat: visual polish, rounded corners, and themed styling"
```

---

## Task 10: Final Cleanup

**Files:**
- Modify: `CLAUDE.md` (update known issues)
- Modify: `TODO.md` (mark all complete)

- [ ] **Step 1: Final compile check**

```bash
cd /Users/raajpatkar/Code/Open-source101/telenotch
xcodebuild -project Telenotch.xcodeproj -scheme Telenotch -destination "platform=macOS" build CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 2: Mark all TODO items complete**

Edit `TODO.md` — change every `- [ ]` to `- [x]`.

- [ ] **Step 3: Update CLAUDE.md known issues if any were discovered**

Add any notable issues found during implementation under `## Known Issues / Limitations`.

- [ ] **Step 4: Final commit**

```bash
cd /Users/raajpatkar/Code/Open-source101/telenotch
git add CLAUDE.md TODO.md
git commit -m "feat: Telenotch v1.0 — complete notch teleprompter app"
```

---

## Appendix: Compile Error Quick-Reference

| Error | Fix |
|-------|-----|
| Code signing required | Add `CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY=""` to xcodebuild |
| `'Theme' has no member 'rose'` | Ensure `Theme.swift` uses `.rose` not `.rosé` (avoid special chars in enum cases) |
| `NSHostingController` requires `@MainActor` | Wrap in `DispatchQueue.main.async` or annotate with `@MainActor` |
| PreferenceKey not updating | Ensure `.background(GeometryReader {...})` is on the text VStack, not the outer container |
| `xcodegen: command not found` | Run `brew install xcodegen` |
| Timer not starting | Ensure `RunLoop.main.add(scrollTimer!, forMode: .common)` is called (prevents timer freeze during UI interaction) |
