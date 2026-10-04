// DEVELOPMENT ASSETS: this whole folder is listed in DEVELOPMENT_ASSET_PATHS (app target).
// Xcode leaves these files out of the build input only when ARCHIVING, but they are still
// compiled in every other build. So any code that uses them in a Release/Archive build would
// not find them and fail the archive, a failure that tends to show up late, in CI.
// Therefore: (1) wrap every file here in `#if DEBUG`, and (2) only reference these types from
// code that is also inside `#if DEBUG`, such as `#Preview` blocks.

#if DEBUG
import Foundation

/// Sample recipes for the Details previews. One list covers every case: a vegetarian recipe
/// with a photo that loads and an ingredient with no quantity, a non-vegetarian one with a long
/// title and a long step, one with no photo, and one whose photo fails. Photos come from
/// `PreviewImage`, so no preview needs the network.
extension RecipeDetails {
    static let previewSamples: [RecipeDetails] = [
        RecipeDetails(
            id: "petit-gateau",
            title: "Petit Gâteau",
            summary: "Brazilian-style warm chocolate cake with a molten center, served with vanilla ice cream.",
            servings: 4,
            ingredients: [
                Ingredient(id: "dark-chocolate", name: "Dark chocolate", quantity: "200 g"),
                Ingredient(id: "unsalted-butter", name: "Unsalted butter", quantity: "100 g"),
                Ingredient(id: "eggs", name: "Eggs", quantity: "2"),
                Ingredient(id: "salt", name: "Salt", quantity: nil),
                Ingredient(id: "vanilla-ice-cream", name: "Vanilla ice cream", quantity: "To serve"),
            ],
            instructions: [
                CookingInstruction(step: 1, text: "Heat the oven to 220°C and butter four small ramekins."),
                CookingInstruction(step: 2, text: "Melt chocolate and butter together, then whisk in eggs, sugar, and flour."),
                CookingInstruction(step: 3, text: "Fill the ramekins and bake for 8 to 10 minutes, until the edges set and the centers stay soft."),
                CookingInstruction(step: 4, text: "Turn out while warm and serve immediately with vanilla ice cream."),
            ],
            dietaryAttributes: DietaryAttributes(isVegetarian: true),
            imageURL: PreviewImage.fileURL
        ),
        RecipeDetails(
            id: "sheet-pan-salmon",
            title: "Sheet Pan Salmon with Roasted Vegetables and Herbs",
            summary: "Salmon, potatoes, and greens in one easy pan.",
            servings: 1,
            ingredients: [
                Ingredient(id: "salmon", name: "Salmon fillets, skin on, pin bones removed", quantity: "4 fillets, about 150 g each"),
                Ingredient(id: "potatoes", name: "Baby potatoes", quantity: "500 g"),
            ],
            instructions: [
                CookingInstruction(step: 1, text: "Toss the potatoes with oil and roast them for 15 minutes before anything else goes on the pan, so they finish at the same time as the fish, which cooks much faster than they do."),
                CookingInstruction(step: 2, text: "Add the salmon and greens, then roast for 12 more minutes."),
            ],
            dietaryAttributes: DietaryAttributes(isVegetarian: false),
            imageURL: PreviewImage.fileURL
        ),
        RecipeDetails(
            id: "roasted-vegetable-couscous",
            title: "Roasted Vegetable Couscous",
            summary: "Colorful roast vegetables over fluffy couscous.",
            servings: 6,
            ingredients: [Ingredient(id: "couscous", name: "Couscous", quantity: "300 g")],
            instructions: [CookingInstruction(step: 1, text: "Roast the vegetables, then fold them through the couscous.")],
            dietaryAttributes: DietaryAttributes(isVegetarian: true),
            imageURL: nil
        ),
        RecipeDetails(
            id: "lemon-herb-chicken",
            title: "Lemon Herb Chicken",
            summary: "Roasted chicken with bright lemon and herbs.",
            servings: 4,
            ingredients: [Ingredient(id: "chicken", name: "Chicken", quantity: "1 whole")],
            instructions: [CookingInstruction(step: 1, text: "Roast until golden.")],
            dietaryAttributes: DietaryAttributes(isVegetarian: false),
            imageURL: PreviewImage.failingURL
        ),
    ]
}
#endif
