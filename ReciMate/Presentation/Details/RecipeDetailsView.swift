import SwiftUI

/// Placeholder until the Recipe Detail screen is built.
struct RecipeDetailsView: View {
    let recipeID: String

    var body: some View {
        Text("Recipe details: \(recipeID)")
            .navigationTitle("Details")
            .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Details placeholder") {
    NavigationStack {
        RecipeDetailsView(recipeID: "creamy-tomato-pasta")
    }
}
#endif
