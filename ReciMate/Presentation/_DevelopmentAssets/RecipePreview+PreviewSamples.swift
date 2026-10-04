// DEVELOPMENT ASSETS: this whole folder is listed in DEVELOPMENT_ASSET_PATHS (app target).
// Xcode leaves these files out of the build input only when ARCHIVING, but they are still
// compiled in every other build. So any code that uses them in a Release/Archive build would
// not find them and fail the archive, a failure that tends to show up late, in CI.
// Therefore: (1) wrap every file here in `#if DEBUG`, and (2) only reference these types from
// code that is also inside `#if DEBUG`, such as `#Preview` blocks.

#if DEBUG
import Foundation

/// Sample recipes for previews. One list covers every card case: a photo that loads,
/// a vegetarian and a non-vegetarian recipe, a long two-line title with a photo that fails,
/// and a recipe with no photo. Photos come from `PreviewImage`, so no preview needs the network.
extension RecipePreview {
    static let previewSamples: [RecipePreview] = [
        RecipePreview(
            id: "petit-gateau",
            title: "Petit Gâteau",
            summary: "Warm chocolate cake with a molten center.",
            servings: 4,
            dietaryAttributes: DietaryAttributes(isVegetarian: true),
            imageURL: PreviewImage.fileURL
        ),
        RecipePreview(
            id: "lemon-herb-chicken",
            title: "Lemon Herb Chicken",
            summary: "Roasted chicken with bright lemon and herbs.",
            servings: 4,
            dietaryAttributes: DietaryAttributes(isVegetarian: false),
            imageURL: PreviewImage.fileURL
        ),
        RecipePreview(
            id: "creamy-tomato-pasta",
            title: "Creamy Tomato Pasta",
            summary: "A quick pantry pasta with a silky tomato sauce.",
            servings: 1,
            dietaryAttributes: DietaryAttributes(isVegetarian: true),
            imageURL: PreviewImage.fileURL
        ),
        RecipePreview(
            id: "sheet-pan-salmon",
            title: "Sheet Pan Salmon with Roasted Vegetables and Herbs",
            summary: "Salmon, potatoes, and greens in one easy pan.",
            servings: 4,
            dietaryAttributes: DietaryAttributes(isVegetarian: false),
            imageURL: PreviewImage.failingURL
        ),
        RecipePreview(
            id: "roasted-vegetable-couscous",
            title: "Roasted Vegetable Couscous",
            summary: "Colorful roast vegetables over fluffy couscous.",
            servings: 6,
            dietaryAttributes: DietaryAttributes(isVegetarian: true),
            imageURL: nil
        ),
    ]
}
#endif
