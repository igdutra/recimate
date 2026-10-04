import SwiftUI

/// A card's photo: fills a fixed-height tile. While the photo loads the tile shows a
/// spinner; with no URL, or when the photo fails to load, it shows a neutral icon.
struct RecipeImageView: View {
    let imageURL: URL?

    var body: some View {
        RecipeImageTile {
            if let imageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .empty:
                        // Only reached with a URL: `AsyncImage` also reports `.empty` for a
                        // `nil` URL, which is why that case is handled before it, below.
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        PlaceholderIcon()
                    @unknown default:
                        // `AsyncImagePhase` is not frozen. A phase we do not know gets the
                        // neutral icon, never a spinner that might never stop.
                        PlaceholderIcon()
                    }
                }
            } else {
                PlaceholderIcon()
            }
        }
    }
}

/// The fixed-height tile every state of the photo sits in.
private struct RecipeImageTile<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        Color.placeholderFill
            .frame(height: Sizing.cardPhotoHeight)
            .frame(maxWidth: .infinity)
            .overlay { content }
            .clipped()
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

#if DEBUG
#Preview("Loaded") {
    RecipeImageView(imageURL: PreviewImage.fileURL)
}

// A real URL cannot be held in its loading phase in a preview, so this draws the
// loading state directly.
#Preview("Loading") {
    RecipeImageTile { ProgressView() }
}

#Preview("No URL") {
    RecipeImageView(imageURL: nil)
}

#Preview("Failing URL") {
    RecipeImageView(imageURL: PreviewImage.failingURL)
}
#endif
