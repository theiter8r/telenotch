import SwiftUI

// MARK: - PreferenceKey for measuring text content height

struct TextHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

// MARK: - ScrollingTextView

struct ScrollingTextView: View {
    @EnvironmentObject var state: PrompterState

    var body: some View {
        GeometryReader { outerGeo in
            ZStack(alignment: .top) {
                // Scrolling text — offset drives the scroll.
                // .fixedSize(vertical: true) lets the VStack grow to its natural content height
                // so the inner GeometryReader can measure the true text height.
                // .clipped() is on the ZStack below, NOT here, so the measurement isn't
                // constrained to the visible frame before the PreferenceKey can read it.
                textContent
                    .fixedSize(horizontal: false, vertical: true)
                    .background(
                        // Measure text height via background GeometryReader
                        GeometryReader { innerGeo in
                            Color.clear
                                .preference(key: TextHeightKey.self, value: innerGeo.size.height)
                        }
                    )
                    .scaleEffect(x: state.isMirrored ? -1 : 1, y: 1)
                    .offset(y: -state.scrollOffset)
                    .onPreferenceChange(TextHeightKey.self) { textHeight in
                        // Dispatch to main thread: @Published mutations must happen on the main actor.
                        DispatchQueue.main.async {
                            state.maxScrollOffset = max(0, textHeight - outerGeo.size.height)
                        }
                    }

                // Top gradient overlay (rendered on top of clipped text)
                VStack {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            state.currentTheme.background.opacity(0.95),
                            Color.clear
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 60)
                    Spacer()
                }
                .allowsHitTesting(false)

                // Bottom gradient overlay
                VStack {
                    Spacer()
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.clear,
                            state.currentTheme.background.opacity(0.95)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 60)
                }
                .allowsHitTesting(false)
            }
            // .clipped() on the ZStack — this is what prevents text from visually
            // overflowing the visible area. Must be OUTSIDE the text layer so the
            // GeometryReader can still measure the full natural height first.
            .clipped()
        }
    }

    private var textContent: some View {
        Text(state.script)
            .font(.system(size: state.fontSize))
            .foregroundColor(state.currentTheme.textColor)
            .lineSpacing(8)
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .textSelection(.disabled)
    }
}
