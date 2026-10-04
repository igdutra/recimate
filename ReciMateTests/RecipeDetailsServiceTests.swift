import Foundation
import Testing
@testable import ReciMate

@MainActor
struct RecipeDetailsServiceTests {
    @Test(arguments: [
        ("petit-gateau", "https://api.recimate.example"),
        ("lemon-herb-chicken", "http://localhost:8080/v2"),
        ("a b", "https://other.example"),
    ])
    func loadRecipe_requestsDetailsEndpointURL(recipeID: String, baseURLString: String) async throws {
        let baseURL = URL(string: baseURLString)!
        let (service, clientSpy) = makeSUT(baseURL: baseURL)
        clientSpy.stub(data: makeDetailsData(.fixture(id: recipeID)))

        _ = try await service.loadRecipe(id: recipeID)

        #expect(clientSpy.requestedURLs == [RecipeEndpoint.details(id: recipeID).url(baseURL: baseURL)])
    }

    @Test func loadRecipe_onValidJSON_deliversMappedDetails() async throws {
        let (service, clientSpy) = makeSUT()
        let recipe = RecipeDetails.fixture(
            ingredients: [.fixture(id: "eggs", name: "Eggs", quantity: "2"), .fixture(id: "salt", name: "Salt", quantity: nil)],
            instructions: [.fixture(step: 1, text: "Mix."), .fixture(step: 2, text: "Bake.")],
            isVegetarian: false
        )
        clientSpy.stub(data: makeDetailsData(recipe))

        let result = try await service.loadRecipe(id: "petit-gateau")

        #expect(result == recipe)
    }

    @Test(arguments: [[3, 1, 2], [10, 5]])
    func loadRecipe_withOutOfOrderSteps_deliversInstructionsSortedByStep(steps: [Int]) async throws {
        let (service, clientSpy) = makeSUT()
        let outOfOrder = RecipeDetails.fixture(instructions: steps.map { .fixture(step: $0, text: "Step \($0)") })
        clientSpy.stub(data: makeDetailsData(outOfOrder))

        let result = try await service.loadRecipe(id: "petit-gateau")

        #expect(result.instructions == steps.sorted().map { .fixture(step: $0, text: "Step \($0)") })
    }

    @Test func loadRecipe_withoutPhotoIngredientsOrInstructions_succeeds() async throws {
        let (service, clientSpy) = makeSUT()
        let sparseRecipe = RecipeDetails.fixture(ingredients: [], instructions: [], imageURL: nil)
        clientSpy.stub(data: makeDetailsData(sparseRecipe))

        let result = try await service.loadRecipe(id: "petit-gateau")

        #expect(result == sparseRecipe)
    }

    @Test func loadRecipe_onClientNotFound_throwsNotFound() async {
        let (service, clientSpy) = makeSUT()
        clientSpy.stub(error: RecipeAPIClientError.notFound)

        await #expect(throws: RecipeError.notFound) { try await service.loadRecipe(id: "petit-gateau") }
    }

    private nonisolated static func undecodablePayloads() -> [Data] {
        var wrongServingsType = makeDetailsJSON(from: .fixture())
        wrongServingsType["servings"] = "four"
        var malformedStep = makeDetailsJSON(from: .fixture())
        malformedStep["cooking_instructions"] = [["step": "two", "text": "Mix."]]
        return [
            Data("not json".utf8),
            makeJSONData(["an", "array"]),
            makeJSONData(wrongServingsType),
            makeJSONData(malformedStep),
        ]
    }

    @Test(arguments: undecodablePayloads())
    func loadRecipe_onUndecodableData_throwsInvalidData(payload: Data) async {
        let (service, clientSpy) = makeSUT()
        clientSpy.stub(data: payload)

        await #expect { try await service.loadRecipe(id: "petit-gateau") } throws: { isInvalidDataWithReason($0) }
    }

    @Test(arguments: [
        URLError(.notConnectedToInternet) as any Error,
        CustomError() as any Error,
    ])
    func loadRecipe_onAnyOtherClientError_throwsUnavailable(clientError: Error) async {
        let (service, clientSpy) = makeSUT()
        clientSpy.stub(error: clientError)

        await #expect(throws: RecipeError.unavailable) { try await service.loadRecipe(id: "petit-gateau") }
    }

    @Test(arguments: ["", " ", ".", ".."])
    func loadRecipe_withUnusableID_throwsNotFoundWithoutRequesting(recipeID: String) async {
        let (service, clientSpy) = makeSUT()
        clientSpy.stub(data: makeDetailsData(.fixture(id: recipeID)))

        await #expect(throws: RecipeError.notFound) { try await service.loadRecipe(id: recipeID) }
        #expect(clientSpy.requestedURLs.isEmpty)
    }

    // MARK: - Helpers

    private struct CustomError: Error {}

    private func makeSUT(
        baseURL: URL = URL(string: "https://api.recimate.example")!
    ) -> (service: RemoteRecipeDetailsService, clientSpy: RecipeAPIClientSpy) {
        let clientSpy = RecipeAPIClientSpy()
        return (RemoteRecipeDetailsService(baseURL: baseURL, client: clientSpy), clientSpy)
    }

    private func makeDetailsData(_ recipe: RecipeDetails) -> Data {
        makeJSONData(makeDetailsJSON(from: recipe))
    }
}
