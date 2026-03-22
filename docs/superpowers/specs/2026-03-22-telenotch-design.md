# Telenotch — Design Spec
**Date:** 2026-03-22
**Status:** Approved

## Overview

Telenotch is a macOS menu bar teleprompter app that lives near the notch. Clicking the menu bar icon reveals a floating, borderless, always-on-top panel with a smooth auto-scrolling script view, speed/font controls, 5 color themes, mirror mode, and keyboard shortcuts.

---

## Architecture

**Pattern:** AppDelegate-first. No SwiftUI `@main` App struct.
`main.swift` boots `NSApplication` directly. `AppDelegate` owns the menu bar item and panel lifecycle. All view state flows through a single `PrompterState` ObservableObject passed as `.environmentObject`.

**Deployment target:** macOS 13.0+
**Project type:** Xcode project (.xcodeproj)

---

## File Structure

```
telenotch/
├── Telenotch.xcodeproj/
├── Telenotch/
│   ├── main.swift                  # NSApplication entry point
│   ├── AppDelegate.swift           # NSStatusItem + NSPanel lifecycle
│   ├── TelenotchPanel.swift        # NSPanel subclass (borderless, floating)
│   ├── PrompterState.swift         # ObservableObject — all app state + timer
│   ├── TeleprompterView.swift      # Root SwiftUI view hosted in panel
│   ├── ControlBar.swift            # Top bar: play/pause, speed, font, theme, edit
│   ├── ScrollingTextView.swift     # Scrolling text content + gradient fade overlays
│   ├── Theme.swift                 # Enum: 5 themes with background/text/accent colors
│   ├── Info.plist                  # LSUIElement=YES
│   └── Assets.xcassets/
├── docs/superpowers/specs/
│   └── 2026-03-22-telenotch-design.md
├── CLAUDE.md
├── TODO.md
└── .gitignore
```

---

## State Model (`PrompterState`)

Single `ObservableObject`, instantiated once in `AppDelegate`, injected as `environmentObject`.

```swift
@Published var script: String          // teleprompter text
@Published var isPlaying: Bool         // play/pause toggle
@Published var speed: Double           // pts/sec, range 5–120, default 35
@Published var fontSize: Double        // range 14–48, default 24
@Published var isMirrored: Bool        // horizontal flip via scaleEffect(x: -1, y: 1)
@Published var isEditing: Bool         // TextEditor vs read-only mode
@Published var currentTheme: Theme     // active color theme
@Published var scrollOffset: Double    // current Y scroll position (capped)
@Published var maxScrollOffset: Double // textHeight - visibleHeight (set by GeometryReader)
```

**Timer:** `Timer.scheduledTimer(withTimeInterval: 1/60)` lives in `PrompterState`. Each tick increments `scrollOffset` by `speed / 60` when `isPlaying == true`. Capped at `max(0, maxScrollOffset)`. Timer is started on `init`, firing is gated by `isPlaying`.

---

## Scrolling Engine

- **No ScrollView.** Text content sits in a `VStack` with `.offset(y: -scrollOffset)` inside a clipped frame.
- **Measuring:** A `GeometryReader` wraps the text content to get `textHeight`. The visible frame height is captured via another `GeometryReader` on the clip container. `maxScrollOffset = max(0, textHeight - visibleHeight)`.
- **Cap:** Each timer tick: `scrollOffset = min(scrollOffset + speed/60, maxScrollOffset)`. Auto-pauses when cap is reached.
- **Mirror:** `.scaleEffect(x: isMirrored ? -1 : 1, y: 1)` on the text container.
- **Gradient fade:** Two `LinearGradient` overlays via `.overlay(alignment: .top)` and `.overlay(alignment: .bottom)`, each ~60pt tall, fading from `theme.background.opacity(0.95)` to `.clear`.

---

## Panel (`TelenotchPanel`)

`NSPanel` subclass with:
- Style: `.borderless`, no title bar
- `isFloatingPanel = true`
- `level = .floating`
- `collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]`
- `isMovableByWindowBackground = true`
- `backgroundColor = .clear`
- `isOpaque = false`
- Size: 380×520, positioned centered horizontally just below menu bar
- SwiftUI content has `cornerRadius(16)` + `shadow`
- `NSHostingController` wraps `TeleprompterView`

---

## Themes (`Theme` enum)

Five cases, each providing `background: Color`, `textColor: Color`, `accentColor: Color`:

| Name | Background | Text | Accent |
|------|-----------|------|--------|
| Midnight | Dark blue/purple | Soft white | Lavender |
| Warm Glow | Dark brown | Amber/orange | Orange |
| Ocean | Deep teal | Cyan | Light blue |
| Forest | Dark green | Light green | Mint |
| Rosé | Dark mauve | Soft pink | Rose |

Panel background uses `theme.background.opacity(0.95)` for subtle translucency.

---

## Control Bar

Top strip inside the panel:
- **Close (X):** Hides panel
- **Edit toggle:** Switches between `Text(script)` read mode and `TextEditor(text: $script)`
- **Play/Pause:** SF Symbol `play.fill` / `pause.fill`
- **Reset:** SF Symbol `arrow.counterclockwise` — sets `scrollOffset = 0`
- **Speed slider:** Range 5–120, label shows current value
- **Font size slider:** Range 14–48
- **Theme cycle button:** Shows current theme name, cycles to next on tap
- **Mirror toggle:** SF Symbol `arrow.left.and.right`

---

## Keyboard Shortcuts

Captured in `TeleprompterView` via `.onKeyPress` (macOS 13+) or `NSEvent` monitor in `AppDelegate`:

| Key | Action |
|-----|--------|
| Space | Toggle play/pause |
| ↑ | Speed += 5 |
| ↓ | Speed -= 5 |
| R | Reset scroll to top |
| Escape | Hide panel |

---

## File Import

A toolbar button (SF Symbol `doc.text`) opens `NSOpenPanel` filtered to `.txt` files. Selected file content is read with `String(contentsOf:)` and written to `state.script`. Drag-and-drop on the panel uses `.onDrop(of: [.fileURL])`.

---

## Git & Project Setup

- Repo initialized in `telenotch/` with `user.name = "Raaj Patkar"`, `user.email = "raajpatkar@gmail.com"`
- `.gitignore` covers: `.build/`, `DerivedData/`, `.DS_Store`, `xcuserdata/`, `*.xcuserstate`, `*.moved-aside`, `*.hmap`
- `CLAUDE.md` at root with project description, tech stack, build instructions, architecture notes, conventions
- `TODO.md` checklist tracking all features
- Commits use conventional commits: `feat:`, `fix:`, `chore:`, `docs:`

---

## Conventions

- All state in `PrompterState` — no local `@State` for shared concerns
- Themes as `enum` with static color definitions (no dynamic loading)
- 60fps timer in `PrompterState`, not in views
- `GeometryReader` used only for scroll cap measurement — not for layout
- No third-party dependencies
