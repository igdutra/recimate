import SwiftUI

/// What one recipe card shows. A plain value so SwiftUI can skip cards that did not change.
struct RecipeCardViewData: Identifiable, Equatable {
    let id: String
    let title: String
    let servingsLabel: String
    let isVegetarian: Bool
    let imageURL: URL?
}

struct RecipeCardView: View {
    let card: RecipeCardViewData

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RecipeImageView(
                imageURL: card.imageURL,
                height: Sizing.cardPhotoHeight,
                placeholderIconSize: Sizing.iconPlaceholder
            )
            details
        }
        .background(Color.mist)
        .clipShape(.rect(cornerRadius: Radius.card))
        .accessibilityElement(children: .combine)
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: Spacing.extraSmall) {
            Text(card.title)
                .font(Typography.cardTitle)
                .foregroundStyle(Color.ink)
                .lineLimit(2, reservesSpace: true)
            HStack {
                Text(card.servingsLabel)
                    .font(Typography.cardDetail)
                    .foregroundStyle(Color.inkSecondary)
                Spacer()
                if card.isVegetarian {
                    VegetarianMarkView()
                }
            }
            // Same height with or without the leaf, so cards in a row match.
            .frame(minHeight: Sizing.icon)
        }
        .padding(Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Card variants") {
    LazyVGrid(
        columns: [GridItem(.adaptive(minimum: Sizing.gridColumnMinimum), spacing: Spacing.large, alignment: .top)],
        spacing: Spacing.large
    ) {
        ForEach(RecipeCardViewData.previewSamples) { card in
            RecipeCardView(card: card)
        }
    }
    .padding(Spacing.extraLarge)
}
#endif
