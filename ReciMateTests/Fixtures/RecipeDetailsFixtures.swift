import Foundation
@testable import ReciMate

// MARK: - Named recipes

extension RecipeDetails {
    /// Vegetarian, an ingredient with a quantity and one without, two steps.
    static let petitGateau = RecipeDetails(
        id: "petit-gateau",
        title: "Petit Gâteau",
        summary: "Warm chocolate cake with a molten center.",
        servings: 4,
        ingredients: [.eggs, .salt],
        instructions: [.mix, .bake],
        dietaryAttributes: DietaryAttributes(isVegetarian: true),
        imageURL: URL(string: "https://example.com/petit-gateau.jpg")
    )

    /// Not vegetarian, one ingredient, one step.
    static let lemonHerbChicken = RecipeDetails(
        id: "lemon-herb-chicken",
        title: "Lemon Herb Chicken",
        summary: "Roasted chicken with bright lemon and herbs.",
        servings: 4,
        ingredients: [.chicken],
        instructions: [.roast],
        dietaryAttributes: DietaryAttributes(isVegetarian: false),
        imageURL: URL(string: "https://example.com/lemon-herb-chicken.jpg")
    )
}

extension Ingredient {
    static let eggs = Ingredient(id: "eggs", name: "Eggs", quantity: "2")
    static let chicken = Ingredient(id: "chicken", name: "Chicken", quantity: "1 whole")
    /// No quantity, as the real data has for "to taste" items.
    static let salt = Ingredient(id: "salt", name: "Salt", quantity: nil)
}

extension CookingInstruction {
    static let mix = CookingInstruction(step: 1, text: "Mix.")
    static let bake = CookingInstruction(step: 2, text: "Bake.")
    static let roast = CookingInstruction(step: 1, text: "Roast until golden.")
}

// MARK: - Factory

extension RecipeDetails {
    /// For a test where one field is the point: starts from `petitGateau`,
    /// override only that field.
    static func fixture(
        id: String = petitGateau.id,
        title: String = petitGateau.title,
        summary: String = petitGateau.summary,
        servings: Int = petitGateau.servings,
        ingredients: [Ingredient] = petitGateau.ingredients,
        instructions: [CookingInstruction] = petitGateau.instructions,
        isVegetarian: Bool = petitGateau.dietaryAttributes.isVegetarian,
        imageURL: URL? = petitGateau.imageURL
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
    static func fixture(id: String = eggs.id, name: String = eggs.name, quantity: String? = eggs.quantity) -> Ingredient {
        Ingredient(id: id, name: name, quantity: quantity)
    }
}

extension CookingInstruction {
    static func fixture(step: Int = mix.step, text: String = mix.text) -> CookingInstruction {
        CookingInstruction(step: step, text: text)
    }
}
