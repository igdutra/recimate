import Foundation

/// Response of the list endpoint (`GET /recipe-list`), mocked by
/// `Infrastructure/RecipeList/recipe-list.json`.
typealias RecipeListDTO = [RecipePreviewDTO]

/// One item of the list endpoint.
struct RecipePreviewDTO: Decodable, Sendable {
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
