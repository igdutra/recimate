import SwiftUI

/// What one quick chip shows.
struct FilterChipViewData: Identifiable, Equatable {
    enum ID: Equatable {
        case vegetarian
        case servings
        case filters
    }

    let id: ID
    let title: String
    let symbolName: String
    let showsChevron: Bool
    /// Whether the icon is drawn in the accent color instead of ink.
    let usesAccentIcon: Bool
}

struct FilterChipView: View {
    let chip: FilterChipViewData
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.extraSmall) {
                Image(systemName: chip.symbolName)
                    .font(.system(size: Sizing.icon, weight: .medium))
                    .foregroundStyle(chip.usesAccentIcon ? Color.accentColor : Color.ink)
                Text(chip.title)
                    .font(Typography.chipLabel)
                    .foregroundStyle(Color.ink)
                if chip.showsChevron {
                    Image(systemName: "chevron.down")
                        .font(.system(size: Sizing.iconSmall, weight: .semibold))
                        .foregroundStyle(Color.ink)
                }
            }
            .padding(.horizontal, Spacing.medium)
            .frame(minHeight: Sizing.touchTarget)
            .background(Color.mist, in: .capsule)
            .contentShape(.capsule)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("Chips: plain, leaf, chevron") {
    HStack(spacing: Spacing.small) {
        FilterChipView(
            chip: FilterChipViewData(id: .filters, title: "Filters", symbolName: "slider.horizontal.3", showsChevron: false, usesAccentIcon: false),
            action: {}
        )
        FilterChipView(
            chip: FilterChipViewData(id: .vegetarian, title: "Vegetarian", symbolName: "leaf", showsChevron: false, usesAccentIcon: true),
            action: {}
        )
        FilterChipView(
            chip: FilterChipViewData(id: .servings, title: "Servings", symbolName: "person.2", showsChevron: true, usesAccentIcon: false),
            action: {}
        )
    }
    .padding(Spacing.extraLarge)
}
