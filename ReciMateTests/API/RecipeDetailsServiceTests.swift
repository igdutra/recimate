import Foundation
import Testing
@testable import ReciMate

@MainActor
struct RecipeDetailsServiceTests {
    // MARK: - Request

    @Test(arguments: [
        ("petit-gateau", "https://api.recimate.example"),
        ("lemon-herb-chicken", "http://localhost:8080/v2"),
        ("a b", "https://other.example"),
    ])
    func loadRecipe_requestsDetailsEndpointURL(recipeID: String, baseURLString: String) async throws {
        let baseURL = URL(string: baseURLString)!
        let (sut, spy) = makeSUT(baseURL: baseURL)
        spy.stub(data: makeDetailsData(.petitGateau))

        _ = try await sut.loadRecipe(id: recipeID)

        #expect(spy.requestedURLs == [RecipeEndpoint.details(id: recipeID).url(baseURL: baseURL)])
    }

    // MARK: - Happy path

    @Test(arguments: [RecipeDetails.petitGateau, .lemonHerbChicken])
    func loadRecipe_onValidJSON_deliversMappedDetails(recipe: RecipeDetails) async throws {
        let (sut, spy) = makeSUT()
        spy.stub(data: makeDetailsData(recipe))

        let result = try await sut.loadRecipe(id: recipe.id)

        #expect(result == recipe)
    }

    @Test(arguments: [[3, 1, 2], [10, 5]])
    func loadRecipe_withOutOfOrderSteps_deliversInstructionsSortedByStep(steps: [Int]) async throws {
        let (sut, spy) = makeSUT()
        let outOfOrder = RecipeDetails.fixture(instructions: steps.map { .fixture(step: $0, text: "Step \($0)") })
        spy.stub(data: makeDetailsData(outOfOrder))

        let result = try await sut.loadRecipe(id: knownRecipeID)

        #expect(result.instructions == steps.sorted().map { .fixture(step: $0, text: "Step \($0)") })
    }

    @Test func loadRecipe_withoutPhotoIngredientsOrInstructions_succeeds() async throws {
        let (sut, spy) = makeSUT()
        let sparseRecipe = RecipeDetails.fixture(ingredients: [], instructions: [], imageURL: nil)
        spy.stub(data: makeDetailsData(sparseRecipe))

        let result = try await sut.loadRecipe(id: knownRecipeID)

        #expect(result == sparseRecipe)
    }

    // MARK: - Failure modes

    @Test func loadRecipe_onClientNotFound_throwsNotFound() async {
        let (sut, spy) = makeSUT()
        spy.stub(error: RecipeAPIClientError.notFound)

        await #expect(throws: RecipeError.notFound) { try await sut.loadRecipe(id: knownRecipeID) }
    }

    @Test(arguments: undecodablePayloads())
    func loadRecipe_onUndecodableData_throwsInvalidData(payload: Data) async {
        let (sut, spy) = makeSUT()
        spy.stub(data: payload)

        await #expect { try await sut.loadRecipe(id: knownRecipeID) } throws: { isInvalidDataWithReason($0) }
    }

    @Test(arguments: [
        URLError(.notConnectedToInternet) as any Error,
        CustomError() as any Error,
    ])
    func loadRecipe_onAnyOtherClientError_throwsUnavailable(clientError: any Error) async {
        let (sut, spy) = makeSUT()
        spy.stub(error: clientError)

        await #expect(throws: RecipeError.unavailable) { try await sut.loadRecipe(id: knownRecipeID) }
    }
}

// MARK: - Helpers

private extension RecipeDetailsServiceTests {
    typealias SUTBundle = (sut: RemoteRecipeDetailsService, spy: RecipeAPIClientSpy)

    struct CustomError: Error {}

    /// An id the fixtures know, for tests where the id is not the point.
    var knownRecipeID: String { RecipeDetails.petitGateau.id }

    func makeSUT(baseURL: URL = URL(string: "https://api.recimate.example")!) -> SUTBundle {
        let spy = RecipeAPIClientSpy()
        let sut = RemoteRecipeDetailsService(baseURL: baseURL, client: spy)
        return (sut, spy)
    }

    func makeDetailsData(_ recipe: RecipeDetails) -> Data {
        makeJSONData(makeDetailsJSON(from: recipe))
    }

    nonisolated static func undecodablePayloads() -> [Data] {
        var wrongServingsType = makeDetailsJSON(from: .petitGateau)
        wrongServingsType["servings"] = "four"
        var malformedStep = makeDetailsJSON(from: .petitGateau)
        malformedStep["cooking_instructions"] = [["step": "two", "text": "Mix."]]
        return [
            Data("not json".utf8),
            makeJSONData(["an", "array"]),
            makeJSONData(wrongServingsType),
            makeJSONData(malformedStep),
        ]
    }
}
