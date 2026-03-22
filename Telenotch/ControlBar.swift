import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ControlBar: View {
    @EnvironmentObject var state: PrompterState
    var onClose: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            // Row 1: action buttons
            HStack(spacing: 12) {
                // Close
                toolButton(systemImage: "xmark", action: onClose)

                // Import
                toolButton(systemImage: "doc.text") { importFile() }

                Spacer()

                // Theme cycle
                Button(action: { state.cycleTheme() }) {
                    Text(state.currentTheme.name)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(state.currentTheme.accentColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(state.currentTheme.accentColor.opacity(0.15))
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)

                // Mirror
                toolButton(
                    systemImage: "arrow.left.and.right",
                    active: state.isMirrored
                ) { state.isMirrored.toggle() }

                // Edit
                toolButton(
                    systemImage: state.isEditing ? "checkmark" : "pencil",
                    active: state.isEditing
                ) { toggleEdit() }
            }

            // Row 2: transport controls
            HStack(spacing: 14) {
                // Reset
                toolButton(systemImage: "arrow.counterclockwise") { state.reset() }

                // Play / Pause
                Button(action: { state.isPlaying.toggle() }) {
                    Image(systemName: state.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(state.isEditing
                            ? state.currentTheme.textColor.opacity(0.3)
                            : state.currentTheme.accentColor)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
                .disabled(state.isEditing)

                Spacer()

                // Speed indicator
                Text("\(Int(state.speed)) pt/s")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(state.currentTheme.textColor.opacity(0.6))
                    .frame(minWidth: 54, alignment: .trailing)
            }

            // Row 3: speed slider
            HStack(spacing: 8) {
                Image(systemName: "tortoise")
                    .font(.system(size: 10))
                    .foregroundColor(state.currentTheme.textColor.opacity(0.4))
                Slider(value: $state.speed, in: 5...120, step: 1)
                    .tint(state.currentTheme.accentColor)
                Image(systemName: "hare")
                    .font(.system(size: 10))
                    .foregroundColor(state.currentTheme.textColor.opacity(0.4))
            }

            // Row 4: font size slider
            HStack(spacing: 8) {
                Image(systemName: "textformat.size.smaller")
                    .font(.system(size: 10))
                    .foregroundColor(state.currentTheme.textColor.opacity(0.4))
                Slider(value: $state.fontSize, in: 14...48, step: 1)
                    .tint(state.currentTheme.accentColor)
                Image(systemName: "textformat.size.larger")
                    .font(.system(size: 10))
                    .foregroundColor(state.currentTheme.textColor.opacity(0.4))
                Text("\(Int(state.fontSize))pt")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(state.currentTheme.textColor.opacity(0.6))
                    .frame(minWidth: 32, alignment: .trailing)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(state.currentTheme.background.opacity(0.6))
    }

    // MARK: - Helpers

    @ViewBuilder
    private func toolButton(
        systemImage: String,
        active: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(active
                    ? state.currentTheme.accentColor
                    : state.currentTheme.textColor.opacity(0.7))
                .frame(width: 28, height: 28)
                .background(active
                    ? state.currentTheme.accentColor.opacity(0.15)
                    : Color.clear)
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }

    private func toggleEdit() {
        if state.isEditing {
            // Exiting edit — reset scroll, defer maxScrollOffset recompute so layout settles
            state.isEditing = false
            state.scrollOffset = 0
            DispatchQueue.main.async {
                // Nudge SwiftUI to trigger a layout pass so PreferenceKey re-fires
                state.objectWillChange.send()
            }
        } else {
            state.isEditing = true
        }
    }

    private func importFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.plainText]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            do {
                let content = try String(contentsOf: url, encoding: .utf8)
                DispatchQueue.main.async {
                    state.script = content
                    state.scrollOffset = 0
                }
            } catch {
                // File read failed — silently ignore for v1.0
            }
        }
    }
}
