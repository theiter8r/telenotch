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
**No third-party dependencies.**

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
@Published var script: String           // teleprompter text
@Published var isPlaying: Bool          // play/pause, default false
@Published var speed: Double            // pts/sec, range 5–120, default 35
@Published var fontSize: Double         // range 14–48, default 24
@Published var isMirrored: Bool         // horizontal flip, default false
@Published var isEditing: Bool          // TextEditor vs read-only mode, default false
@Published var currentTheme: Theme      // active color theme, default .midnight
@Published var scrollOffset: Double     // current Y scroll position, default 0
@Published var maxScrollOffset: Double  // textHeight - visibleHeight, updated by views
```

**Persistence:** `speed`, `fontSize`, `currentTheme`, and `script` are persisted to `UserDefaults` on change via `didSet` / Combine `.sink`. Other state (isPlaying, scrollOffset, isMirrored, isEditing) resets to defaults on each app launch.

---

## Timer Lifecycle

- The 60fps `Timer` lives in `PrompterState` as a private `Timer?` property.
- Created lazily when `isPlaying` is set to `true` for the first time; reused thereafter.
- Each tick: `scrollOffset = min(scrollOffset + speed / 60.0, maxScrollOffset)`. When `scrollOffset >= maxScrollOffset`, sets `isPlaying = false` automatically (auto-stop at end).
- Timer is **not** invalidated when the panel is hidden — it simply stops doing work because `isPlaying == false`. Invalidated only on `PrompterState` deinit (app quit).
- `isPlaying` is the sole gate: timer fires at 60fps always when running, but only advances scroll when `isPlaying == true`.

---

## Scrolling Engine

- **No `ScrollView`.** Text content sits in a `VStack` with `.offset(y: -scrollOffset)` inside a `.clipped()` frame.
- **Measuring `maxScrollOffset`:** `ScrollingTextView` uses a `PreferenceKey` (`TextHeightKey`) to bubble up the text content height from an inner `GeometryReader` background. The visible container height is captured with an outer `GeometryReader`. Both values are written to `PrompterState.maxScrollOffset` in `.onPreferenceChange(TextHeightKey.self)` and `.onAppear` / `.onChange(of: geometry.size)`. `maxScrollOffset = max(0, textHeight - visibleHeight)`.
- **Recompute triggers:** `maxScrollOffset` recomputes when: (a) `script` changes (edit mode exit), (b) `fontSize` changes, (c) panel is resized. It does NOT recompute on every keystroke during live editing — it recomputes on `isEditing` toggle off (edit → read mode).
- **Mirror:** `.scaleEffect(x: isMirrored ? -1 : 1, y: 1)` on the text container.
- **Gradient fade:** Two `LinearGradient` overlays via `.overlay(alignment: .top)` and `.overlay(alignment: .bottom)`, each 60pt tall, fading from `theme.background.opacity(0.95)` to `.clear`. Overlays are placed outside the clipped region so they render over the text.

---

## Panel (`TelenotchPanel`)

`NSPanel` subclass:
- Style mask: `.borderless | .nonactivatingPanel`
- `isFloatingPanel = true`
- `level = .floating`
- `collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]`
- `isMovableByWindowBackground = true`
- `backgroundColor = .clear`, `isOpaque = false`, `hasShadow = true`
- Size: **380×520**
- `NSHostingController` wraps `TeleprompterView`; its view fills the panel content view

**Panel positioning:**
- On show, the panel is positioned centered horizontally on the screen (`screen.visibleFrame.midX - 190`), with its top edge at `screen.frame.maxY - screen.visibleFrame.maxY + 8` — i.e., 8pt below the menu bar.
- On non-notch displays this places the panel just below the menu bar at screen center, which is correct.
- If the computed X position would cause the panel to overflow the screen right edge, clamp to `screen.visibleFrame.maxX - 380 - 8`.

**Show/hide behavior:**
- First click on status item: calls `panel.orderFront(nil)` and `panel.makeKey()`.
- Second click (panel is already visible): calls `panel.orderOut(nil)`.
- Clicking outside the panel does **not** auto-dismiss — the panel is non-activating and stays visible until explicitly closed (close button, Escape key, or second status-item click).
- Panel is created once in `AppDelegate.applicationDidFinishLaunching` and reused (shown/hidden via `orderFront`/`orderOut`, never destroyed and recreated).

---

## Themes (`Theme` enum)

Five cases, each providing `background: Color`, `textColor: Color`, `accentColor: Color`, `name: String`:

| Name | Background | Text | Accent |
|------|-----------|------|--------|
| `.midnight` | Dark blue `#1a1a2e` | Soft white `#e0e0ff` | Lavender `#a78bfa` |
| `.warmGlow` | Dark brown `#1c1008` | Amber `#fbbf24` | Orange `#f97316` |
| `.ocean` | Deep teal `#0a1628` | Cyan `#67e8f9` | Light blue `#38bdf8` |
| `.forest` | Dark green `#0d1f0d` | Light green `#86efac` | Mint `#34d399` |
| `.rosé` | Dark mauve `#1f0d14` | Soft pink `#f9a8d4` | Rose `#fb7185` |

Panel background uses `theme.background.opacity(0.95)`. Theme cycling goes forward through cases in order, wrapping at the end.

---

## Control Bar (`ControlBar`)

A horizontal strip at the top of `TeleprompterView`:

| Control | Type | Details |
|---------|------|---------|
| Close | Button (SF: `xmark`) | Calls `panel.orderOut(nil)` via `AppDelegate` ref |
| Import | Button (SF: `doc.text`) | Opens `NSOpenPanel` filtered to `.txt` |
| Edit | Toggle button (SF: `pencil` / `checkmark`) | Toggles `isEditing`; recomputes `maxScrollOffset` on exit |
| Mirror | Toggle button (SF: `arrow.left.and.right`) | Toggles `isMirrored` |
| Play/Pause | Button (SF: `play.fill` / `pause.fill`) | Toggles `isPlaying`; disabled while `isEditing == true` |
| Reset | Button (SF: `arrow.counterclockwise`) | Sets `scrollOffset = 0` |
| Speed | Slider + label | Range 5–120, default 35, step 1, shows current value (e.g. "35 pt/s") |
| Font | Slider + label | Range 14–48, default 24, step 1 |
| Theme | Button (text: theme name) | Cycles to next theme |

Edit mode: when `isEditing == true`, `isPlaying` is forced to `false`.

---

## Keyboard Shortcuts

Captured via `NSEvent.addLocalMonitorForEvents(matching: .keyDown)` installed in `AppDelegate` after the panel is created. This is reliable for a floating `NSPanel` regardless of SwiftUI focus state.

| Key | Action |
|-----|--------|
| Space | Toggle `isPlaying` (only when `!isEditing`) |
| ↑ Arrow | `speed = min(speed + 5, 120)` |
| ↓ Arrow | `speed = max(speed - 5, 5)` |
| R | `scrollOffset = 0` |
| Escape | `panel.orderOut(nil)` |

The monitor is only active when the panel is visible (installed on `orderFront`, removed on `orderOut`).

---

## File Import

**Button:** `ControlBar` has an import button that calls `NSOpenPanel` with `allowedContentTypes = [.plainText]` and `allowsMultipleSelection = false`. On successful selection, reads `String(contentsOf: url, encoding: .utf8)` into `state.script`. Resets `scrollOffset = 0`.

**Drag-and-drop:** `TeleprompterView` uses `.onDrop(of: [UTType.plainText, UTType.fileURL])`. The drop handler validates that the file extension is `.txt`; rejects otherwise. Accepted files are read the same way as button import. Drop works in both read and edit mode.

---

## Edit Mode Behavior

1. Tapping Edit sets `isEditing = true` and forces `isPlaying = false`.
2. The script display switches from `Text(state.script)` to `TextEditor(text: $state.script)`.
3. `maxScrollOffset` is **not** recomputed on every keystroke. It recomputes when Edit is toggled **off** (the text settles into read mode and the layout is measured fresh).
4. When Edit is toggled off, `scrollOffset` is reset to `0` (jump to top of updated script).
5. The play button is disabled (`opacity(0.4)`, non-interactive) while `isEditing == true`.

---

## Git & Project Setup

**`.gitignore`** covers: `.build/`, `DerivedData/`, `.DS_Store`, `xcuserdata/`, `*.xcuserstate`, `*.moved-aside`, `*.hmap`, `*.ipa`, `Pods/`

**`CLAUDE.md`** at root contains:
- Project name and description
- Tech stack (Swift, SwiftUI, AppKit, macOS 13+)
- Build instructions (open `.xcodeproj` in Xcode, Cmd+R)
- Project structure (all files and their roles)
- Architecture notes (AppDelegate-first, PrompterState, NSPanel)
- Key conventions (state ownership, timer location, theme enum pattern)
- Known issues/limitations (empty at start)
- Git info (owner: raajpatkar@gmail.com)

**`TODO.md`** checklist:
```
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

**Commit convention:** `feat:`, `fix:`, `chore:`, `docs:` prefixes. Commit after each major feature.

---

## Conventions

- All shared state lives in `PrompterState` — no local `@State` for cross-component concerns
- Themes defined as `enum` with inline static `Color` values (no asset catalog colors)
- 60fps timer owned by `PrompterState`, not views
- `PreferenceKey` used to bubble text height from inner `GeometryReader` to `PrompterState`
- `NSEvent` local monitor for keyboard shortcuts (not SwiftUI `.onKeyPress`)
- No third-party dependencies
- `UserDefaults` keys are namespaced constants defined in `PrompterState`
