import SwiftUI

// MARK: - View data

/// The servings picker's value: any serving count, or exactly one.
enum ServingsChoice: Hashable, Sendable {
    case any
    case count(Int)

    /// The picker offers "Any" and 1 to 8. Assumption: the data holds 2 to 6 and any
    /// upper bound is arbitrary, so a server holding other values would not be reachable.
    static let all: [ServingsChoice] = [.any] + (1...8).map(ServingsChoice.count)
}

/// Everything the Filters sheet shows, replaced as a whole on every change.
struct FiltersSheetViewData: Equatable {
    let isVegetarianOnly: Bool
    let servingsChoice: ServingsChoice
    let includedTerms: [String]
    let excludedTerms: [String]
    let isResetEnabled: Bool
}

/// Placeholder until the Filters sheet is built.
struct FiltersSheetView: View {
    var body: some View {
        Text("Filters")
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Filters placeholder") {
    FiltersSheetView()
}
#endif
