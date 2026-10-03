import Foundation

/// The light version of a recipe shown in the list. Ingredients and
/// instructions only come with `RecipeDetails`, fetched when it's opened.
struct RecipePreview: Identifiable {
    let id: String
    let title: String
    let summary: String
    let servings: Int
    let dietaryAttributes: DietaryAttributes
    let imageURL: URL?
}
