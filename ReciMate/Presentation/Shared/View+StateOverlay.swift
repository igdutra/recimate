import SwiftUI

// An overlay, not an `if/else` around the content: the content keeps its identity, so
// its scroll position and view state survive loading to loaded and loaded to error.
extension View {
    /// Hides and disables the content while `state` is loading or an error. `stateOverlay`
    /// does it by default; a caller whose content sits inside a scroll view that owns the
    /// navigation title (the Library) applies this to the inner content instead, because
    /// fading the scroll view itself fades the large title too.
    func coveredBy(state: ViewState) -> some View {
        let isCovered = state.isLoading || state.error != nil
        return self
            .opacity(isCovered ? 0 : 1)
            .disabled(isCovered)
    }

    /// Covers the content with a spinner while loading, and with a
    /// `ContentUnavailableView` and a Try Again button after a failure.
    func stateOverlay(state: ViewState, hidesContent: Bool = true, retry: @escaping () -> Void) -> some View {
        self
            .modifier(ConditionalCover(state: state, isActive: hidesContent))
            .overlay {
                if state.isLoading {
                    ProgressView()
                } else if let error = state.error {
                    ContentUnavailableView {
                        Label("Couldn't Load", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(error.errorMessage)
                    } actions: {
                        Button("Try Again", action: retry)
                            .buttonStyle(.bordered)
                    }
                }
            }
    }
}

private struct ConditionalCover: ViewModifier {
    let state: ViewState
    let isActive: Bool

    func body(content: Content) -> some View {
        if isActive {
            content.coveredBy(state: state)
        } else {
            content
        }
    }
}

// MARK: - Preview

#if DEBUG
private struct SampleList: View {
    var body: some View {
        List(1...12, id: \.self) { number in
            Text("Row \(number)")
        }
    }
}

#Preview("State overlay, loading") {
    SampleList().stateOverlay(state: .loading) {}
}

#Preview("State overlay, error") {
    SampleList().stateOverlay(state: .error(.unavailable)) {}
}

#Preview("State overlay, loaded") {
    SampleList().stateOverlay(state: .loaded) {}
}
#endif
