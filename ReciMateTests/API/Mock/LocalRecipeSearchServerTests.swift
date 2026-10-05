// Tests the mock only: the fake search server exists because the data is mocked.
// Delete this file, with `API/Infrastructure/` (the fake server, the catalog, the
// details fixtures and `LocalRecipeAPIClient`), when a real backend replaces the mock.

import Foundation
import Testing
@testable import ReciMate

struct LocalRecipeSearchServerTests {
    private let baseURL = URL(string: "https://api.recimate.example")!

    // MARK: - Query items round trip

    @Test(arguments: [
        RecipeSearchQuery.empty,
        RecipeSearchQuery(instructionText: "mac & cheese"),
        RecipeSearchQuery(onlyVegetarian: true, servings: 2),
        RecipeSearchQuery(
            instructionText: "bake",
            onlyVegetarian: true,
            servings: 6,
            includedIngredients: ["crème fraîche", "tomato"],
            excludedIngredients: ["nuts", "mushrooms"]
        ),
        // One term in both lists survives the trip: the server must see it as sent.
        RecipeSearchQuery(includedIngredients: ["cream"], excludedIngredients: ["cream"]),
    ])
    func query_roundTripsThroughTheEndpointURL(query: RecipeSearchQuery) {
        let url = RecipeEndpoint.list(query: query).url(baseURL: baseURL)

        #expect(LocalRecipeSearchServer.query(from: url) == query)
    }

    // MARK: - Matching rules (decision 5)

    @Test(arguments: [
        // Instruction text: a phrase, case- and accent-insensitive, against any single step.
        (RecipeSearchQuery(instructionText: "RAMEKINS"), ["soup"]),
        (RecipeSearchQuery(instructionText: "brown the beef"), ["stew"]),
        (RecipeSearchQuery(instructionText: "gently serve"), []),
        (RecipeSearchQuery(instructionText: "crème"), []),
        // Include: AND, contains on names, ignoring case and accents.
        (RecipeSearchQuery(includedIngredients: ["cream"]), ["soup", "bread"]),
        (RecipeSearchQuery(includedIngredients: ["CREME FRAICHE"]), ["stew"]),
        (RecipeSearchQuery(includedIngredients: ["cream", "mushroom"]), ["soup"]),
        (RecipeSearchQuery(includedIngredients: ["cream", "flour"]), ["bread"]),
        // Exclude: dropped if any term matches.
        (RecipeSearchQuery(excludedIngredients: ["cream"]), ["stew", "bare"]),
        (RecipeSearchQuery(excludedIngredients: ["mushrooms", "beef"]), ["bread", "bare"]),
        // The same term on both sides is unsatisfiable.
        (RecipeSearchQuery(includedIngredients: ["cream"], excludedIngredients: ["cream"]), []),
        // Vegetarian off is no filter; on keeps vegetarian recipes only.
        (RecipeSearchQuery(onlyVegetarian: false), ["soup", "stew", "bread", "bare"]),
        (RecipeSearchQuery(onlyVegetarian: true), ["soup", "bread", "bare"]),
        // Servings: exact; below 1 matches nothing.
        (RecipeSearchQuery(servings: 4), ["stew", "bread"]),
        (RecipeSearchQuery(servings: 0), []),
        (RecipeSearchQuery(servings: -2), []),
        // Combined.
        (RecipeSearchQuery(onlyVegetarian: true, servings: 4, includedIngredients: ["cream"]), ["bread"]),
    ])
    func search_appliesTheMatchingRule(query: RecipeSearchQuery, expectedIDs: [String]) throws {
        #expect(try searchedIDs(for: query) == expectedIDs)
    }

    @Test func search_withNoFilters_returnsEveryRecipeInCatalogOrder() throws {
        #expect(try searchedIDs(for: .empty) == ["soup", "stew", "bread", "bare"])
    }

    // MARK: - Recipes with no data (AC14)

    @Test func search_recipeWithNoIngredientData_failsAnIncludeFilter() throws {
        #expect(try !searchedIDs(for: RecipeSearchQuery(includedIngredients: ["cream"])).contains("bare"))
    }

    @Test func search_recipeWithNoIngredientData_passesAnExcludeFilter() throws {
        #expect(try searchedIDs(for: RecipeSearchQuery(excludedIngredients: ["cream"])).contains("bare"))
    }

    @Test func search_recipeWithNoStepData_failsAnInstructionFilter() throws {
        #expect(try !searchedIDs(for: RecipeSearchQuery(instructionText: "serve")).contains("bare"))
    }

    // MARK: - Response shape

    @Test func search_answersWithListShapedJSON() throws {
        let server = LocalRecipeSearchServer(catalogData: Self.catalogData)
        let url = RecipeEndpoint.list(query: RecipeSearchQuery(instructionText: "ramekins")).url(baseURL: baseURL)

        let jsonObject = try JSONSerialization.jsonObject(with: server.response(for: url))
        let records = try #require(jsonObject as? [[String: Any]])

        #expect(records.count == 1)
        #expect(records.first?["ingredients"] == nil)
        #expect(records.first?["cooking_instructions"] == nil)
        #expect(records.first?["title"] as? String == "Soup")
    }

    @Test func search_withAnUndecodableCatalog_throws() {
        let server = LocalRecipeSearchServer(catalogData: Data("not json".utf8))
        let url = RecipeEndpoint.list(query: .empty).url(baseURL: baseURL)

        #expect(throws: DecodingError.self) { try server.response(for: url) }
    }
}

// MARK: - Helpers

private extension LocalRecipeSearchServerTests {
    func searchedIDs(for query: RecipeSearchQuery) throws -> [String] {
        let server = LocalRecipeSearchServer(catalogData: Self.catalogData)
        let url = RecipeEndpoint.list(query: query).url(baseURL: baseURL)
        let previews = try JSONDecoder().decode([RecipePreviewDTO].self, from: server.response(for: url))
        return previews.map(\.id)
    }

    /// A small catalog that makes every rule observable. `bare` has no ingredient or
    /// step keys at all.
    static let catalogData = makeJSONData([
        makeCatalogRecord(
            id: "soup", title: "Soup", servings: 2, isVegetarian: true,
            ingredients: ["Cooking cream", "Mushrooms"],
            steps: ["Simmer gently.", "Serve in ramekins."]
        ),
        makeCatalogRecord(
            id: "stew", title: "Stew", servings: 4, isVegetarian: false,
            ingredients: ["Beef", "Crème fraîche"],
            steps: ["Brown the beef.", "Add stock."]
        ),
        makeCatalogRecord(
            id: "bread", title: "Bread", servings: 4, isVegetarian: true,
            ingredients: ["Flour", "Cream cheese"],
            steps: ["Knead the dough."]
        ),
        makeCatalogRecord(id: "bare", title: "Bare", servings: 3, isVegetarian: true, ingredients: nil, steps: nil),
    ])

    static func makeCatalogRecord(
        id: String,
        title: String,
        servings: Int,
        isVegetarian: Bool,
        ingredients: [String]?,
        steps: [String]?
    ) -> [String: Any] {
        var record: [String: Any] = [
            "id": id,
            "title": title,
            "description": "\(title) description",
            "servings": servings,
            "dietary_attributes": ["is_vegetarian": isVegetarian],
        ]
        if let ingredients {
            record["ingredients"] = ingredients.map { ["id": $0.lowercased(), "name": $0] }
        }
        if let steps {
            record["cooking_instructions"] = steps.enumerated().map { ["step": $0.offset + 1, "text": $0.element] }
        }
        return record
    }
}
