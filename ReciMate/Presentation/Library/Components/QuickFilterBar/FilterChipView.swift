import SwiftUI

// MARK: - View data

/// What one quick chip shows.
struct FilterChipViewData: Identifiable, Equatable {
    enum ID: Equatable {
        case vegetarian
        case servings
    }

    let id: ID
    let title: String
    let symbolName: String
    let showsChevron: Bool
    /// Whether the icon is drawn in the accent color instead of ink.
    let usesAccentIcon: Bool
}

// MARK: - FilterChipView

struct FilterChipView: View {
    let chip: FilterChipViewData
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: chip.symbolName)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(chip.usesAccentIcon ? Color.accentColor : Color.ink)
                Text(chip.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.ink)
                if chip.showsChevron {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.ink)
                }
            }
            .padding(.horizontal, 12)
            .frame(minHeight: 44) // Touch target
            .background(Color.mist, in: .capsule)
            .contentShape(.capsule)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Chips: leaf, chevron, plain") {
    HStack(spacing: 8) {
        ForEach(QuickFilterBarViewModel().viewData.chips) { chip in
            FilterChipView(chip: chip, action: {})
        }
    }
    .padding(20)
}
#endif
