import Foundation

/// Step 2 of the list pipeline: DTO to domain. The data is taken as the backend
/// sent it; only decoding (step 1) can reject it.
enum RecipeListMapper {
    static func map(_ listDTO: RecipeListDTO) -> [RecipePreview] {
        listDTO.map { previewDTO in
            RecipePreview(
                id: previewDTO.id,
                title: previewDTO.title,
                summary: previewDTO.description,
                servings: previewDTO.servings,
                dietaryAttributes: DietaryAttributes(isVegetarian: previewDTO.dietaryAttributes.isVegetarian),
                imageURL: previewDTO.imageURL
            )
        }
    }
}
