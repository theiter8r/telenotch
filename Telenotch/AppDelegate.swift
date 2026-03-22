import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem!
    private var panel: TelenotchPanel!
    private var keyboardMonitor: Any?
    let state = PrompterState()    // single source of truth

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
        hostingController.view.autoresizingMask = [.width, .height]
        panel.contentViewController = hostingController
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
        installKeyboardMonitor()
    }

    func hidePanel() {
        panel.orderOut(nil)
        removeKeyboardMonitor()
    }

    // MARK: - Keyboard Monitor

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
}
