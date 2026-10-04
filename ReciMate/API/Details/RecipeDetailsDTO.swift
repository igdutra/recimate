import Foundation

// Transport types: mirror the JSON contract exactly, snake_case keys included.
// The JSON files in `Infrastructure/` stand in for the server's responses.
// Mapping to domain types belongs to the API layer, not to these types.

/// Response of the detail endpoint (`GET /recipe-details/{id}`), mocked by
/// `Infrastructure/RecipeDetails/<id>.json`.
struct RecipeDetailsDTO: Decodable, Sendable {
    let id: String
    let title: String
    let description: String
    let servings: Int
    let ingredients: [IngredientDTO]
    let cookingInstructions: [CookingInstructionDTO]
    let dietaryAttributes: DietaryAttributesDTO
    let imageURL: URL?

    // Explicit keys instead of `.convertFromSnakeCase`, which would turn
    // `image_url` into `imageUrl` and silently drop the image.
    enum CodingKeys: String, CodingKey {
        case id, title, description, servings, ingredients
        case cookingInstructions = "cooking_instructions"
        case dietaryAttributes = "dietary_attributes"
        case imageURL = "image_url"
    }
}

struct IngredientDTO: Decodable, Sendable {
    let id: String
    let name: String
    let quantity: String?
}

struct CookingInstructionDTO: Decodable, Sendable {
    let step: Int
    let text: String
}

struct DietaryAttributesDTO: Decodable, Sendable {
    let isVegetarian: Bool

    enum CodingKeys: String, CodingKey {
        case isVegetarian = "is_vegetarian"
    }
}
