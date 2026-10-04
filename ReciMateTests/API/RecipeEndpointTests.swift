import Foundation
import Testing
@testable import ReciMate

struct RecipeEndpointTests {
    private let baseURL = URL(string: "https://api.recimate.example")!

    @Test func list_url_isBaseURLPlusRecipeList() {
        #expect(RecipeEndpoint.list.url(baseURL: baseURL).absoluteString
                == "https://api.recimate.example/recipe-list")
    }

    @Test func details_url_isBaseURLPlusRecipeDetailsAndID() {
        #expect(RecipeEndpoint.details(id: "petit-gateau").url(baseURL: baseURL).absoluteString
                == "https://api.recimate.example/recipe-details/petit-gateau")
    }
}
