import Foundation
import Playgrounds

/// Stands in for a server: serves the bundled JSON fixtures. It ignores the
/// URL's scheme and host and reads `<last path component>.json` from the
/// bundle root (the fixtures are bundled flat, so file names must stay unique).
/// A missing file is `RecipeAPIClientError.notFound`; any other read failure
/// passes through untouched. `recipes` (the collection) is the exception: it is answered by
/// `LocalRecipeSearchServer`, which filters `recipe-catalog.json` by the query items.
///
/// The `#Playground` at the bottom of this file composes it with the list and details services,
/// so the whole data layer can be exercised and printed without a screen.
struct LocalRecipeAPIClient: RecipeAPIClient {
    let bundle: Bundle
    /// How long every request waits before it is answered.
    let delay: Duration

    init(bundle: Bundle = .main, delay: Duration = .seconds(1)) {
        self.bundle = bundle
        self.delay = delay
    }

    func data(from url: URL) async throws -> Data {
        // Only to mock network latency, so the loading state is visible when running the
        // app. A real client has no such wait. A cancelled request throws `CancellationError` here.
        try await Task.sleep(for: delay)
        if url.lastPathComponent == "recipes" {
            return try searchResponse(for: url)
        }
        // Note: the RecipeAPIClient endpoint for details resolves as `https://api.recimate.example/recipes/petit-gateau`
        // But this mock object only cares for the lastPathComponent, that is why the filename is `petit-gateau.json`.
        guard let fileURL = bundle.url(forResource: url.lastPathComponent, withExtension: "json") else {
            throw RecipeAPIClientError.notFound
        }
        return try Data(contentsOf: fileURL)
    }

    private func searchResponse(for url: URL) throws -> Data {
        guard let catalogURL = bundle.url(forResource: "recipe-catalog", withExtension: "json") else {
            throw RecipeAPIClientError.notFound
        }
        let server = LocalRecipeSearchServer(catalogData: try Data(contentsOf: catalogURL))
        return try server.response(for: url)
    }
}

// MARK: Playground

// Verify that integration works!
#Playground("Recipe data layer") {
    let client = LocalRecipeAPIClient()
    let listService = RemoteRecipeListService(baseURL: ReciMateApp.apiBaseURL, client: client)
    let detailsService = RemoteRecipeDetailsService(baseURL: ReciMateApp.apiBaseURL, client: client)

    let allRecipes = try await listService.loadRecipes(matching: .empty)
    print("all recipes:", allRecipes.map(\.title))

    let ramekinRecipes = try await listService.loadRecipes(matching: RecipeSearchQuery(instructionText: "ramekins"))
    print("instructions contain ramekins:", ramekinRecipes.map(\.title))

    var filteredQuery = RecipeSearchQuery(onlyVegetarian: true, servings: 2)
    filteredQuery.addIncludedIngredient("cream")
    filteredQuery.addExcludedIngredient("mushrooms")
    let filteredRecipes = try await listService.loadRecipes(matching: filteredQuery)
    print("vegetarian, 2 servings, cream, no mushrooms:", filteredRecipes.map(\.title))

    // A good recipe, the one with a malformed detail, and the one with no detail file.
    for recipeID in ["petit-gateau", "creamy-tomato-pasta", "beef-tacos"] {
        do {
            let recipe = try await detailsService.loadRecipe(id: recipeID)
            print("\(recipeID):", recipe.title, "-", recipe.ingredients.count, "ingredients,", recipe.instructions.count, "steps")
        } catch {
            print("\(recipeID):", error)
        }
    }
}
