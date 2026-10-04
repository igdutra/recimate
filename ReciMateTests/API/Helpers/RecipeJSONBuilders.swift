import Foundation
@testable import ReciMate

// Build the API's snake_case JSON from domain values, so a test states the
// expected model once and derives the payload from it. A `nil` optional leaves
// its key out, as the real API does. To build a wrongly typed or missing field,
// change the returned dictionary.

func makeJSONData(_ jsonObject: Any) -> Data {
    try! JSONSerialization.data(withJSONObject: jsonObject)
}

func makePreviewJSON(from preview: RecipePreview) -> [String: Any] {
    var json: [String: Any] = [
        "id": preview.id,
        "title": preview.title,
        "description": preview.summary,
        "servings": preview.servings,
        "dietary_attributes": ["is_vegetarian": preview.dietaryAttributes.isVegetarian],
    ]
    if let imageURL = preview.imageURL { json["image_url"] = imageURL.absoluteString }
    return json
}

func makeDetailsJSON(from recipe: RecipeDetails) -> [String: Any] {
    var json: [String: Any] = [
        "id": recipe.id,
        "title": recipe.title,
        "description": recipe.summary,
        "servings": recipe.servings,
        "ingredients": recipe.ingredients.map { ingredient -> [String: Any] in
            var ingredientJSON: [String: Any] = ["id": ingredient.id, "name": ingredient.name]
            if let quantity = ingredient.quantity { ingredientJSON["quantity"] = quantity }
            return ingredientJSON
        },
        "cooking_instructions": recipe.instructions.map { ["step": $0.step, "text": $0.text] },
        "dietary_attributes": ["is_vegetarian": recipe.dietaryAttributes.isVegetarian],
    ]
    if let imageURL = recipe.imageURL { json["image_url"] = imageURL.absoluteString }
    return json
}
