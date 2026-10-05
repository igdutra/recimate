// Tests the mock only: the catalog repeats ingredients and steps that two details
// files also hold, so this pins them equal. Delete this file, with
// `API/Infrastructure/` (the fake server, the catalog, the details fixtures and
// `LocalRecipeAPIClient`), when a real backend replaces the mock: with one source of
// truth there is nothing to compare.

import Foundation
import Testing
@testable import ReciMate

struct RecipeCatalogDriftTests {
    /// Creamy Tomato Pasta is left out on purpose: its details file is malformed
    /// (step 2 is "two") to demo the E2 failure, and the catalog holds the corrected step.
    @Test(arguments: ["petit-gateau", "lemon-herb-chicken"])
    func catalog_matchesTheDetailsFile(recipeID: String) throws {
        let catalogRecord = try #require(Self.catalogRecords.first { $0["id"] as? String == recipeID })
        let detailsRecord = try Self.jsonObject(named: recipeID)

        #expect(NSArray(array: catalogRecord["ingredients"] as? [Any] ?? [])
                == NSArray(array: detailsRecord["ingredients"] as? [Any] ?? []))
        #expect(NSArray(array: catalogRecord["cooking_instructions"] as? [Any] ?? [])
                == NSArray(array: detailsRecord["cooking_instructions"] as? [Any] ?? []))
        #expect(catalogRecord["ingredients"] != nil)
    }

    @Test func catalog_holdsTheCorrectedStepForTheMalformedDetailsFile() throws {
        let catalogRecord = try #require(Self.catalogRecords.first { $0["id"] as? String == "creamy-tomato-pasta" })
        let steps = try #require(catalogRecord["cooking_instructions"] as? [[String: Any]])

        #expect(steps.compactMap { $0["step"] as? Int } == [1, 2, 3])
    }

    static var catalogRecords: [[String: Any]] {
        get throws { try jsonArray(named: "recipe-catalog") }
    }

    private static func jsonArray(named name: String) throws -> [[String: Any]] {
        let jsonObject = try JSONSerialization.jsonObject(with: Data(contentsOf: fileURL(named: name)))
        return try #require(jsonObject as? [[String: Any]])
    }

    private static func jsonObject(named name: String) throws -> [String: Any] {
        let jsonObject = try JSONSerialization.jsonObject(with: Data(contentsOf: fileURL(named: name)))
        return try #require(jsonObject as? [String: Any])
    }

    private static func fileURL(named name: String) throws -> URL {
        try #require(Bundle.main.url(forResource: name, withExtension: "json"))
    }
}
