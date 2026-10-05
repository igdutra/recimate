import SwiftUI

// MARK: - View data

struct QuickFilterBarViewData: Equatable {
    let chips: [FilterChipViewData]
}

// MARK: - QuickFilterBar

/// The horizontal row of quick chips.
struct QuickFilterBar: View {
    let viewModel: QuickFilterBarViewModel

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(viewModel.viewData.chips) { chip in
                    FilterChipView(chip: chip) {
                        viewModel.didTapChip(chip.id)
                    }
                }
            }
        }
        .scrollIndicators(.hidden)
        .contentMargins(.horizontal, Layout.screenGutter, for: .scrollContent)
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Quick filter bar") {
    QuickFilterBar(viewModel: QuickFilterBarViewModel())
}
#endif
