import Foundation

// Domain types: what the app means by a recipe, independent of how any API spells it.

struct RecipeDetails: Identifiable {
    let id: String
    let title: String
    /// The brief calls this "description". `summary` avoids clashing with
    /// `CustomStringConvertible.description`.
    let summary: String
    /// At least 1. The API layer enforces this when it maps transport data.
    let servings: Int
    let ingredients: [Ingredient]
    /// Ordered by `step`.
    let instructions: [CookingInstruction]
    let dietaryAttributes: DietaryAttributes
    /// A recipe without a photo is still a valid recipe.
    let imageURL: URL?
}

struct Ingredient: Identifiable {
    /// Stable across recipes ("eggs" is the same ingredient everywhere), so the
    /// include/exclude filters match on it rather than on the display name.
    let id: String
    let name: String
    /// Free text such as "200 g" or "To serve". Not structured, so quantities
    /// can't be scaled by servings.
    let quantity: String?
}

struct CookingInstruction: Identifiable {
    let step: Int
    let text: String

    var id: Int { step }
}

/// A struct rather than a set of flags so each attribute is a named, documented
/// property. The brief only names vegetarian.
struct DietaryAttributes {
    let isVegetarian: Bool
}
