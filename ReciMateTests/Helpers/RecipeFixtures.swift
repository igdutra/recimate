import Foundation
@testable import ReciMate

// Domain fixtures: valid by default, override only what a test is about.
// Fixtures can also build invalid values (servings 0, duplicate steps) because
// the domain types do not validate; the API layer does.

extension RecipePreview {
    static func fixture(
        id: String = "petit-gateau",
        title: String = "Petit Gâteau",
        summary: String = "Warm chocolate cake.",
        servings: Int = 4,
        isVegetarian: Bool = true,
        imageURL: URL? = URL(string: "https://example.com/petit-gateau.jpg")
    ) -> RecipePreview {
        RecipePreview(
            id: id,
            title: title,
            summary: summary,
            servings: servings,
            dietaryAttributes: DietaryAttributes(isVegetarian: isVegetarian),
            imageURL: imageURL
        )
    }
}

extension RecipeDetails {
    static func fixture(
        id: String = "petit-gateau",
        title: String = "Petit Gâteau",
        summary: String = "Warm chocolate cake.",
        servings: Int = 4,
        ingredients: [Ingredient] = [.fixture()],
        instructions: [CookingInstruction] = [.fixture()],
        isVegetarian: Bool = true,
        imageURL: URL? = URL(string: "https://example.com/petit-gateau.jpg")
    ) -> RecipeDetails {
        RecipeDetails(
            id: id,
            title: title,
            summary: summary,
            servings: servings,
            ingredients: ingredients,
            instructions: instructions,
            dietaryAttributes: DietaryAttributes(isVegetarian: isVegetarian),
            imageURL: imageURL
        )
    }
}

extension Ingredient {
    static func fixture(id: String = "eggs", name: String = "Eggs", quantity: String? = "2") -> Ingredient {
        Ingredient(id: id, name: name, quantity: quantity)
    }
}

extension CookingInstruction {
    static func fixture(step: Int = 1, text: String = "Mix.") -> CookingInstruction {
        CookingInstruction(step: step, text: text)
    }
}
