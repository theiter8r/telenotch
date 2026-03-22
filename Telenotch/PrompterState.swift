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
