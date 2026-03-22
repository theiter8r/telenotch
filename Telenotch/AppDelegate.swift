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
    }

    func hidePanel() {
        panel.orderOut(nil)
    }
}
