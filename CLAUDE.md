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
xcodebuild -project Telenotch.xcodeproj -scheme Telenotch build CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY=""
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

- **Keyboard monitor teardown timing:** `showPanel`/`hidePanel` use `NSAnimationContext` fade (~0.14s). The keyboard event monitor is removed in the hide animation's completion handler (deferred ~0.14s after `hidePanel` is called). This is safe because the monitor closure contains a `panel.isVisible` guard — any keyDown events that slip through during the fade are ignored.
- **Corner radius layering:** `.clipShape(RoundedRectangle(cornerRadius: 16))` is applied in `TeleprompterView` (not the deprecated `.cornerRadius` modifier). The underlying `NSPanel` layer also has `cornerRadius=16` and `masksToBounds=true`. Both layers are intentional — the SwiftUI clip handles the SwiftUI content, and the AppKit layer handles the native window chrome.

## Git

- Owner: raajpatkar@gmail.com
- Commits use conventional prefixes: `feat:`, `fix:`, `chore:`, `docs:`
