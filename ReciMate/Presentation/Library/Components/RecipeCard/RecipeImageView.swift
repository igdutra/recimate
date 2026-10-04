import SwiftUI

/// A card's photo: fills a fixed-height frame, and shows a neutral tile when
/// there is no URL or the photo fails to load.
struct RecipeImageView: View {
    let imageURL: URL?

    var body: some View {
        Color.placeholderFill
            .frame(height: Sizing.cardPhotoHeight)
            .frame(maxWidth: .infinity)
            .overlay { content }
            .clipped()
    }

    @ViewBuilder
    private var content: some View {
        if let imageURL {
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    PlaceholderIcon()
                default:
                    // Still loading: the bare tile, without the "no image" icon.
                    Color.clear
                }
            }
        } else {
            PlaceholderIcon()
        }
    }
}

private struct PlaceholderIcon: View {
    var body: some View {
        Image(systemName: "photo")
            .font(.system(size: Sizing.iconPlaceholder, weight: .light))
            .foregroundStyle(Color.inkSecondary)
            .accessibilityHidden(true)
    }
}

// MARK: - Preview

#Preview("Loaded") {
    RecipeImageView(imageURL: PreviewImage.fileURL)
}

#Preview("No URL") {
    RecipeImageView(imageURL: nil)
}

#Preview("Failing URL") {
    RecipeImageView(imageURL: PreviewImage.failingURL)
}
