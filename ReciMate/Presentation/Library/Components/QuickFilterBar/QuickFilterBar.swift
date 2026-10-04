import SwiftUI

struct QuickFilterBarViewData: Equatable {
    let chips: [FilterChipViewData]
}

/// The horizontal row of quick chips.
struct QuickFilterBar: View {
    let viewModel: QuickFilterBarViewModel

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: Spacing.small) {
                ForEach(viewModel.viewData.chips) { chip in
                    FilterChipView(chip: chip) {
                        viewModel.didTapChip(chip.id)
                    }
                }
            }
        }
        .scrollIndicators(.hidden)
        .contentMargins(.horizontal, Spacing.extraLarge, for: .scrollContent)
    }
}

// MARK: - Preview

#Preview("Quick filter bar") {
    QuickFilterBar(viewModel: QuickFilterBarViewModel())
}
