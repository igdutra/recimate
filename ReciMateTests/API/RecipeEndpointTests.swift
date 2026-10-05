import Foundation
import Testing
@testable import ReciMate

struct RecipeEndpointTests {
    private let baseURL = URL(string: "https://api.recimate.example")!

    @Test func list_url_withNoFilters_isBaseURLPlusRecipes() {
        #expect(RecipeEndpoint.list(query: .empty).url(baseURL: baseURL).absoluteString
                == "https://api.recimate.example/recipes")
    }

    @Test func details_url_isBaseURLPlusRecipesAndID() {
        #expect(RecipeEndpoint.details(id: "petit-gateau").url(baseURL: baseURL).absoluteString
                == "https://api.recimate.example/recipes/petit-gateau")
    }

    // MARK: - List query

    @Test(arguments: [
        (RecipeSearchQuery(onlyVegetarian: true), "?vegetarian=true"),
        (RecipeSearchQuery(servings: 4), "?servings=4"),
        (RecipeSearchQuery(instructionText: "ramekins"), "?instructions=ramekins"),
        (RecipeSearchQuery(searchText: "pet"), "?q=pet"),
        (RecipeSearchQuery(includedIngredients: ["eggs"]), "?include=eggs"),
        (RecipeSearchQuery(excludedIngredients: ["nuts"]), "?exclude=nuts"),
    ])
    func list_url_encodesEachFilter(query: RecipeSearchQuery, expectedSuffix: String) {
        #expect(RecipeEndpoint.list(query: query).url(baseURL: baseURL).absoluteString
                == "https://api.recimate.example/recipes" + expectedSuffix)
    }

    @Test func list_url_repeatsIncludeAndExcludeInOrder() {
        let query = RecipeSearchQuery(
            instructionText: "bake",
            onlyVegetarian: true,
            servings: 2,
            includedIngredients: ["cream", "tomato"],
            excludedIngredients: ["mushrooms", "nuts"]
        )

        #expect(RecipeEndpoint.list(query: query).url(baseURL: baseURL).absoluteString
                == "https://api.recimate.example/recipes?vegetarian=true&servings=2&include=cream&include=tomato&exclude=mushrooms&exclude=nuts&instructions=bake")
    }

    @Test func list_url_sendsSearchTextAndInstructionTextTogether() {
        let query = RecipeSearchQuery(searchText: "roast", instructionText: "bake")

        #expect(RecipeEndpoint.list(query: query).url(baseURL: baseURL).absoluteString
                == "https://api.recimate.example/recipes?instructions=bake&q=roast")
    }

    @Test func list_url_dropsBlankSearchText() {
        #expect(RecipeEndpoint.list(query: RecipeSearchQuery(searchText: "  \n")).url(baseURL: baseURL).absoluteString
                == "https://api.recimate.example/recipes")
    }

    @Test func list_url_dropsBlankValues() {
        let query = RecipeSearchQuery(
            instructionText: "   ",
            includedIngredients: ["", "  eggs "],
            excludedIngredients: ["\n"]
        )

        #expect(RecipeEndpoint.list(query: query).url(baseURL: baseURL).absoluteString
                == "https://api.recimate.example/recipes?include=eggs")
    }

    @Test func list_url_keepsABaseURLPathPrefix() {
        let prefixedBaseURL = URL(string: "https://api.recimate.example/v1/")!

        #expect(RecipeEndpoint.list(query: RecipeSearchQuery(onlyVegetarian: true)).url(baseURL: prefixedBaseURL).absoluteString
                == "https://api.recimate.example/v1/recipes?vegetarian=true")
    }

    @Test func list_url_encodesSpacesAccentsAndAmpersands() throws {
        let query = RecipeSearchQuery(instructionText: "mac & cheese", includedIngredients: ["crème fraîche"])
        let url = RecipeEndpoint.list(query: query).url(baseURL: baseURL)

        #expect(url.absoluteString.contains("instructions=mac%20%26%20cheese"))
        #expect(url.absoluteString.contains("include=cr%C3%A8me%20fra%C3%AEche"))
        let queryItems = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems)
        #expect(queryItems.first { $0.name == "instructions" }?.value == "mac & cheese")
    }
}
