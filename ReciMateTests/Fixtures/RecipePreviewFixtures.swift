import Foundation
@testable import ReciMate

// Domain fixtures for the list. Valid values, safe to share across tests.
// Fixtures can also build invalid values (servings 0, duplicate steps) because
// the domain types do not validate; the API layer does.

// MARK: - Named recipes

/// Realistic recipes from the bundled list, so a test that only needs "a recipe"
/// reads as one. Photo URLs point to example.com and are never fetched.
extension RecipePreview {
    /// Vegetarian, 4 servings, has a photo.
    static let petitGateau = RecipePreview(
        id: "petit-gateau",
        title: "Petit Gâteau",
        summary: "Warm chocolate cake with a molten center.",
        servings: 4,
        dietaryAttributes: DietaryAttributes(isVegetarian: true),
        imageURL: URL(string: "https://example.com/petit-gateau.jpg")
    )

    /// Not vegetarian, 4 servings, has a photo.
    static let lemonHerbChicken = RecipePreview(
        id: "lemon-herb-chicken",
        title: "Lemon Herb Chicken",
        summary: "Roasted chicken with bright lemon and herbs.",
        servings: 4,
        dietaryAttributes: DietaryAttributes(isVegetarian: false),
        imageURL: URL(string: "https://example.com/lemon-herb-chicken.jpg")
    )

    /// Vegetarian, 3 servings, no photo (the placeholder card in the design).
    static let roastedVegetableCouscous = RecipePreview(
        id: "roasted-vegetable-couscous",
        title: "Roasted Vegetable Couscous",
        summary: "Colorful roast vegetables over fluffy couscous.",
        servings: 3,
        dietaryAttributes: DietaryAttributes(isVegetarian: true),
        imageURL: nil
    )
}

// MARK: - Factory

extension RecipePreview {
    /// For a test where one field is the point: starts from `petitGateau`,
    /// override only that field.
    static func fixture(
        id: String = petitGateau.id,
        title: String = petitGateau.title,
        summary: String = petitGateau.summary,
        servings: Int = petitGateau.servings,
        isVegetarian: Bool = petitGateau.dietaryAttributes.isVegetarian,
        imageURL: URL? = petitGateau.imageURL
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
