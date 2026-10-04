import Foundation

/// Step 2 of the details pipeline: DTO to domain. The data is taken as the
/// backend sent it, except that instructions are sorted by step.
enum RecipeDetailsMapper {
    static func map(_ detailsDTO: RecipeDetailsDTO) -> RecipeDetails {
        RecipeDetails(
            id: detailsDTO.id,
            title: detailsDTO.title,
            summary: detailsDTO.description,
            servings: detailsDTO.servings,
            ingredients: detailsDTO.ingredients.map {
                Ingredient(id: $0.id, name: $0.name, quantity: $0.quantity)
            },
            instructions: detailsDTO.cookingInstructions
                .sorted { $0.step < $1.step }
                .map { CookingInstruction(step: $0.step, text: $0.text) },
            dietaryAttributes: DietaryAttributes(isVegetarian: detailsDTO.dietaryAttributes.isVegetarian),
            imageURL: detailsDTO.imageURL
        )
    }
}
