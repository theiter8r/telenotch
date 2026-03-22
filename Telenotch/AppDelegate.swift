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

    private func showPanel() {
        panel.positionBelowMenuBar()
        panel.alphaValue = 0
        panel.orderFront(nil)
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.18
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 1
        }
        installKeyboardMonitor()
    }

    private func hidePanel() {
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.14
            ctx.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            self?.panel.orderOut(nil)
            self?.removeKeyboardMonitor()
        })
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

    // MARK: - Key Codes

    private enum Key {
        static let space: UInt16  = 49
        static let upArrow: UInt16 = 126
        static let downArrow: UInt16 = 125
        static let r: UInt16      = 15
        static let escape: UInt16 = 53
    }

    private func handleKeyDown(_ event: NSEvent) -> NSEvent? {
        switch event.keyCode {
        case Key.space:
            if !state.isEditing {
                state.isPlaying.toggle()
                return nil
            }
        case Key.upArrow:
            state.speed = min(state.speed + 5, 120)
            return nil
        case Key.downArrow:
            state.speed = max(state.speed - 5, 5)
            return nil
        case Key.r:
            if !state.isEditing {
                state.reset()
                return nil
            }
        case Key.escape:
            hidePanel()
            return nil
        default:
            break
        }
        return event
    }
}
