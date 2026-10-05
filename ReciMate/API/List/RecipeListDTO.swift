import Foundation

/// Response of the list endpoint (`GET /recipes`), mocked by `LocalRecipeSearchServer`
/// from `Infrastructure/RecipeSearch/recipe-catalog.json`.
typealias RecipeListDTO = [RecipePreviewDTO]

/// One item of the list endpoint.
struct RecipePreviewDTO: Codable, Sendable {
    let id: String
    let title: String
    let description: String
    let servings: Int
    let dietaryAttributes: DietaryAttributesDTO
    let imageURL: URL?

    enum CodingKeys: String, CodingKey {
        case id, title, description, servings
        case dietaryAttributes = "dietary_attributes"
        case imageURL = "image_url"
    }
}
