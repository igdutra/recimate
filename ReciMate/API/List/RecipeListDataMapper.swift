import Foundation

/// Step 1 of the list pipeline: bytes to DTO.
enum RecipeListDataMapper {
    static func map(_ data: Data) throws -> RecipeListDTO {
        do {
            return try JSONDecoder().decode(RecipeListDTO.self, from: data)
        } catch let error as DecodingError {
            throw RecipeError.invalidData(reason: String(describing: error))
        }
    }
}
