import SwiftUI
import UniformTypeIdentifiers

struct TeleprompterView: View {
    @EnvironmentObject var state: PrompterState
    var onClose: () -> Void

    var body: some View {
        ZStack {
            // Theme background
            state.currentTheme.background.opacity(0.95)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ControlBar(onClose: onClose)

                Divider()
                    .overlay(state.currentTheme.accentColor.opacity(0.2))

                // Script content area
                if state.isEditing {
                    TextEditor(text: $state.script)
                        .font(.system(size: state.fontSize))
                        .foregroundColor(state.currentTheme.textColor)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                } else {
                    ScrollingTextView()
                }
            }
        }
        .cornerRadius(16)
        // Drag-and-drop support
        .onDrop(of: [UTType.fileURL, UTType.plainText], isTargeted: nil) { providers in
            handleDrop(providers: providers)
        }
    }

    // MARK: - Drag and Drop

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        // Try fileURL first (e.g. drag a .txt file from Finder)
        if let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) }) {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                guard let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil),
                      url.pathExtension.lowercased() == "txt" else { return }
                do {
                    let content = try String(contentsOf: url, encoding: .utf8)
                    DispatchQueue.main.async {
                        state.script = content
                        state.scrollOffset = 0
                    }
                } catch {}
            }
            return true
        }

        // Try plain text (e.g. dragged from a browser or text editor)
        if let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) }) {
            provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { item, _ in
                let text: String?
                if let data = item as? Data {
                    text = String(data: data, encoding: .utf8)
                } else if let string = item as? String {
                    text = string
                } else {
                    text = nil
                }
                guard let content = text else { return }
                DispatchQueue.main.async {
                    state.script = content
                    state.scrollOffset = 0
                }
            }
            return true
        }

        return false
    }
}
