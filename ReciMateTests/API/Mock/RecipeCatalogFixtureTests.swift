// Tests the mock only: the bundled catalog fixture and the local client that serves
// it. Delete this file, with `API/Infrastructure/` (the fake server, the catalog, the
// details fixtures and `LocalRecipeAPIClient`), when a real backend replaces the mock.

import Foundation
import Testing
@testable import ReciMate

struct RecipeCatalogFixtureTests {
    static let baseURL = URL(string: "https://api.recimate.example")!

    static let allRecipeIDs = [
        "petit-gateau", "lemon-herb-chicken", "creamy-tomato-pasta", "sheet-pan-salmon", "chickpea-curry",
        "beef-tacos", "roasted-vegetable-couscous", "turkey-meatballs", "mushroom-risotto",
    ]

    @Test func catalog_decodesAndHasTheNineIDsInOrder() throws {
        let catalogURL = try #require(Bundle.main.url(forResource: "recipe-catalog", withExtension: "json"))
        let jsonObject = try JSONSerialization.jsonObject(with: Data(contentsOf: catalogURL))
        let records = try #require(jsonObject as? [[String: Any]])

        #expect(records.compactMap { $0["id"] as? String } == Self.allRecipeIDs)
    }

    // MARK: - End to end: local client, search service, domain

    @Test(arguments: [
        (RecipeSearchQuery.empty, RecipeCatalogFixtureTests.allRecipeIDs),
        (
            RecipeSearchQuery(onlyVegetarian: true),
            ["petit-gateau", "creamy-tomato-pasta", "chickpea-curry", "roasted-vegetable-couscous", "mushroom-risotto"]
        ),
        (RecipeSearchQuery(instructionText: "ramekins"), ["petit-gateau"]),
        (RecipeSearchQuery(instructionText: "RAMEKINS"), ["petit-gateau"]),
        (RecipeSearchQuery(servings: 2), ["creamy-tomato-pasta", "mushroom-risotto"]),
        (RecipeSearchQuery(onlyVegetarian: true, servings: 2), ["creamy-tomato-pasta", "mushroom-risotto"]),
        (RecipeSearchQuery(onlyVegetarian: true, servings: 5), []),
        (RecipeSearchQuery(instructionText: "tofu lasagna"), []),
        // The design's frame 7: vegetarian, 2 servings, include "cream", exclude "mushrooms".
        (
            RecipeSearchQuery(
                onlyVegetarian: true,
                servings: 2,
                includedIngredients: ["cream"],
                excludedIngredients: ["mushrooms"]
            ),
            ["creamy-tomato-pasta"]
        ),
    ])
    func search_throughTheLocalClient_returnsTheExpectedRecipes(query: RecipeSearchQuery, expectedIDs: [String]) async throws {
        let service = RemoteRecipeListService(baseURL: Self.baseURL, client: LocalRecipeAPIClient())

        let previews = try await service.loadRecipes(matching: query)

        #expect(previews.map(\.id) == expectedIDs)
    }

    @Test func search_throughTheLocalClient_keepsThePreviewFields() async throws {
        let service = RemoteRecipeListService(baseURL: Self.baseURL, client: LocalRecipeAPIClient())

        let previews = try await service.loadRecipes(matching: RecipeSearchQuery(instructionText: "ramekins"))

        let petitGateau = try #require(previews.first)
        #expect(petitGateau.title == "Petit Gâteau")
        #expect(petitGateau.servings == 4)
        #expect(petitGateau.dietaryAttributes.isVegetarian)
        #expect(petitGateau.imageURL != nil)
    }
}
