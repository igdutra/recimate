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
            RecipeImageView(imageURL: card.imageURL)
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

#Preview("Card variants") {
    let photoURL = PreviewImage.fileURL
    HStack(alignment: .top, spacing: Spacing.large) {
        VStack(spacing: Spacing.large) {
            RecipeCardView(card: RecipeCardViewData(
                id: "one-line-leaf", title: "Petit Gâteau", servingsLabel: "4 servings",
                isVegetarian: true, imageURL: photoURL
            ))
            RecipeCardView(card: RecipeCardViewData(
                id: "one-line-no-leaf", title: "Sheet Pan Salmon", servingsLabel: "1 serving",
                isVegetarian: false, imageURL: photoURL
            ))
        }
        VStack(spacing: Spacing.large) {
            RecipeCardView(card: RecipeCardViewData(
                id: "two-lines-leaf", title: "Roasted Vegetable Couscous", servingsLabel: "6 servings",
                isVegetarian: true, imageURL: nil
            ))
            RecipeCardView(card: RecipeCardViewData(
                id: "two-lines-no-leaf", title: "Lemon Herb Chicken with Garlic Potatoes",
                servingsLabel: "2 servings", isVegetarian: false, imageURL: PreviewImage.failingURL
            ))
        }
    }
    .padding(Spacing.extraLarge)
}
