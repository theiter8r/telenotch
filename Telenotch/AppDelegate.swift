import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem!
    private var panel: TelenotchPanel!
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

        // Placeholder view until TeleprompterView is wired in Task 6
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
