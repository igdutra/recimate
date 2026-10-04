import Foundation
import Playgrounds

/// Stands in for a server: serves the bundled JSON fixtures. It ignores the
/// URL's scheme and host and reads `<last path component>.json` from the
/// bundle root (the fixtures are bundled flat, so file names must stay unique).
/// A missing file is `RecipeAPIClientError.notFound`; any other read failure
/// passes through untouched.
///
/// The `#Playground` at the bottom of this file composes it with both services,
/// so the whole data layer can be exercised and printed without a screen.
struct LocalRecipeAPIClient: RecipeAPIClient {
    let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    func data(from url: URL) async throws -> Data {
        // Note: the RecipeAPIClient endpoint for details resolves as ` https://api.recimate.example/recipe-details/petit-gateau`
        // But this mock object only cares for the lastPathComponent, that is why the filename is `petit-gateau.json`.
        guard let fileURL = bundle.url(forResource: url.lastPathComponent, withExtension: "json") else {
            throw RecipeAPIClientError.notFound
        }
        return try Data(contentsOf: fileURL)
    }
}

// MARK: Playground

// Verify that integration works!
#Playground("Recipe data layer") {
    let client = LocalRecipeAPIClient()
    let listService = RemoteRecipeListService(baseURL: ReciMateApp.apiBaseURL, client: client)
    let detailsService = RemoteRecipeDetailsService(baseURL: ReciMateApp.apiBaseURL, client: client)

    let previews = try await listService.loadRecipes()
    print("list:", previews.map(\.title))

    // A good recipe, the intentionally broken one, and ids with no detail file.
    for recipeID in ["petit-gateau", "creamy-tomato-pasta", "beef-tacos"] {
        do {
            let recipe = try await detailsService.loadRecipe(id: recipeID)
            print("\(recipeID):", recipe.title, "-", recipe.ingredients.count, "ingredients,", recipe.instructions.count, "steps")
        } catch {
            print("\(recipeID):", error)
        }
    }
}
