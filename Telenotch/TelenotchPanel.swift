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
    /// Correct Cocoa coordinate math: Y origin is bottom-left of screen.
    func positionBelowMenuBar() {
        guard let screen = NSScreen.main else { return }

        let menuBarHeight = screen.frame.maxY - screen.visibleFrame.maxY
        // Flush against the bottom of the menu bar — hugs the notch
        let panelTop = screen.frame.maxY - menuBarHeight
        let panelY = panelTop - TelenotchPanel.height

        // Center on the physical screen midX so the panel sits under the notch
        var panelX = screen.frame.midX - TelenotchPanel.width / 2
        let maxX = screen.visibleFrame.maxX - TelenotchPanel.width - 8
        panelX = min(panelX, maxX)

        setFrameOrigin(NSPoint(x: panelX, y: panelY))
    }
}
