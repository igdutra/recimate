import SwiftUI

// MARK: - View data

/// What one recipe card shows. A plain value so SwiftUI can skip cards that did not change.
struct RecipeCardViewData: Identifiable, Equatable {
    let id: String
    let title: String
    let servingsLabel: String
    let isVegetarian: Bool
    let imageURL: URL?
    /// The search found this recipe in its steps and not in its title.
    let isStepOnlyMatch: Bool
}

// MARK: - RecipeCardView

struct RecipeCardView: View {
    let card: RecipeCardViewData

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RecipeImageView(
                imageURL: card.imageURL,
                height: 140
            )
            details
        }
        .background(Color.mist)
        .clipShape(.rect(cornerRadius: 20))
        .accessibilityElement(children: .combine)
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(card.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.ink)
                .lineLimit(2, reservesSpace: true)
            HStack {
                Text(card.servingsLabel)
                    .font(.footnote)
                    .foregroundStyle(Color.inkSecondary)
                Spacer()
                if card.isVegetarian {
                    VegetarianMarkView()
                }
            }
            // Same height with or without the leaf, so cards in a row match.
            .frame(minHeight: VegetarianMarkView.iconSize)
            if card.isStepOnlyMatch {
                HStack(spacing: 4) {
                    Image(systemName: "list.bullet")
                        .font(.footnote)
                        .foregroundStyle(Color.accentColor)
                        .accessibilityHidden(true)
                    Text("Found in the steps")
                        .font(.footnote)
                        .foregroundStyle(Color.inkSecondary)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Card variants") {
    LazyVGrid(
        columns: [GridItem(.adaptive(minimum: 160), spacing: 16, alignment: .top)],
        spacing: 16
    ) {
        ForEach(RecipeCardViewData.previewSamples) { card in
            RecipeCardView(card: card)
        }
    }
    .padding(20)
}

#Preview("Card, found in the steps") {
    // "roast" is not in this title, so the card shows the caption.
    RecipeCardView(card: RecipeLibraryViewModel.makeCard(from: RecipePreview.previewSamples[2], searchedText: "roast"))
        .frame(width: 180)
        .padding(20)
}
#endif
