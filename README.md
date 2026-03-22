# Telenotch

A macOS menu bar teleprompter app designed to live near the notch. Click the menu bar icon to reveal a floating panel with smooth auto-scrolling text.

## Features

- Floating panel anchored below the menu bar / notch
- 60fps smooth auto-scroll with adjustable speed
- 5 color themes
- Mirror mode (for teleprompter glass setups)
- Edit mode — type or paste your script directly in the app
- Drag and drop `.txt` file import
- Keyboard shortcuts for hands-free control
- Persistent settings — speed, font size, theme, and script survive restarts
- No Dock icon — lives entirely in the menu bar

## Screenshots

> Coming soon

## Requirements

- macOS 13.0 (Ventura) or later
- Xcode 15+ (for building from source)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (only needed if regenerating the `.xcodeproj`)

## Installation

### Option A — Build from source

1. Clone the repo:
   ```bash
   git clone https://github.com/raajpatkar/telenotch.git
   cd telenotch
   ```

2. Open the project in Xcode:
   ```bash
   open Telenotch.xcodeproj
   ```

3. Select the **Telenotch** scheme, then press **Cmd+R** to build and run.

The app will appear in your menu bar. There is no Dock icon — this is intentional (`LSUIElement=YES`).

### Option B — Command-line build

```bash
xcodebuild -project Telenotch.xcodeproj \
           -scheme Telenotch \
           build \
           CODE_SIGNING_REQUIRED=NO \
           CODE_SIGN_IDENTITY=""
```

### Regenerating the Xcode project

If you edit `project.yml` (the XcodeGen spec), regenerate the `.xcodeproj` with:

```bash
xcodegen generate
```

Install XcodeGen via Homebrew if you don't have it:

```bash
brew install xcodegen
```

## Usage

1. Click the **text icon** in the menu bar to open the panel.
2. Click **Edit** to enter your script, then click **Done** when ready.
3. Press **Space** or click **Play** to start scrolling.
4. Drag and drop a `.txt` file onto the panel to load a script.
5. Click the icon again (or press **Esc**) to close the panel.

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| `Space` | Play / Pause |
| `↑` | Increase speed |
| `↓` | Decrease speed |
| `R` | Reset scroll to top |
| `Esc` | Close panel |

Shortcuts are active whenever the panel is visible. They are disabled while in Edit mode so normal text input works.

## Project Structure

| File | Role |
|------|------|
| `main.swift` | `NSApplication` entry point |
| `AppDelegate.swift` | Status item, panel lifecycle, keyboard event monitor |
| `TelenotchPanel.swift` | `NSPanel` subclass — borderless, floating, always-on-top |
| `PrompterState.swift` | `ObservableObject` — all app state, 60fps timer, UserDefaults persistence |
| `Theme.swift` | `enum Theme` — 5 color themes |
| `TeleprompterView.swift` | Root SwiftUI view hosted in the panel |
| `ControlBar.swift` | Top control strip — buttons and sliders |
| `ScrollingTextView.swift` | Manual-offset scroll view with gradient fades and mirror support |
| `Info.plist` | Bundle config — `LSUIElement=YES` suppresses Dock icon |
| `project.yml` | XcodeGen spec |

## Architecture Notes

**AppDelegate-first** — no SwiftUI `@main`. `main.swift` boots `NSApplication` and sets `AppDelegate` as delegate.

**PrompterState** is the single source of truth. It owns the 60fps `Timer`, all `@Published` properties, and UserDefaults persistence. It is injected into all SwiftUI views as `.environmentObject`.

**Scrolling is manual** — no `ScrollView`. A `Text` view inside a `.clipped()` container uses `.offset(y: -scrollOffset)`. A `PreferenceKey` (`TextHeightKey`) bubbles content height up from a `GeometryReader` so the max scroll offset can be computed correctly.

**Keyboard shortcuts** use `NSEvent.addLocalMonitorForEvents(matching: .keyDown)`. The monitor is installed on panel show and removed on panel hide to avoid leaks.

## License

MIT
