import Foundation

/// Step 1 of the details pipeline: bytes to DTO.
enum RecipeDetailsDataMapper {
    static func map(_ data: Data) throws -> RecipeDetailsDTO {
        do {
            return try JSONDecoder().decode(RecipeDetailsDTO.self, from: data)
        } catch let error as DecodingError {
            throw RecipeError.invalidData(reason: String(describing: error))
        }
    }
}
