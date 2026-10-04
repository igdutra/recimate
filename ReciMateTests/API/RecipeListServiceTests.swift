import Foundation
import Testing
@testable import ReciMate

@MainActor
struct RecipeListServiceTests {
    // MARK: - Request

    @Test(arguments: ["https://api.recimate.example", "http://localhost:8080/v2"])
    func loadRecipes_requestsListEndpointURL(baseURLString: String) async throws {
        let baseURL = URL(string: baseURLString)!
        let (sut, spy) = makeSUT(baseURL: baseURL)
        spy.stub(data: makeListData([]))

        _ = try await sut.loadRecipes()

        #expect(spy.requestedURLs == [RecipeEndpoint.list.url(baseURL: baseURL)])
    }

    // MARK: - Happy path

    @Test func loadRecipes_onValidJSON_deliversMappedPreviewsInOrder() async throws {
        let (sut, spy) = makeSUT()
        let previews: [RecipePreview] = [.petitGateau, .lemonHerbChicken, .roastedVegetableCouscous]
        spy.stub(data: makeListData(previews))

        let result = try await sut.loadRecipes()

        #expect(result == previews)
    }

    @Test func loadRecipes_onEmptyList_deliversEmptyArray() async throws {
        let (sut, spy) = makeSUT()
        spy.stub(data: makeListData([]))

        let result = try await sut.loadRecipes()

        #expect(result.isEmpty)
    }

    // MARK: - Failure modes

    @Test func loadRecipes_onClientNotFound_throwsNotFound() async {
        let (sut, spy) = makeSUT()
        spy.stub(error: RecipeAPIClientError.notFound)

        await #expect(throws: RecipeError.notFound) { try await sut.loadRecipes() }
    }

    @Test(arguments: undecodablePayloads())
    func loadRecipes_onUndecodableData_throwsInvalidData(payload: Data) async {
        let (sut, spy) = makeSUT()
        spy.stub(data: payload)

        await #expect { try await sut.loadRecipes() } throws: { isInvalidDataWithReason($0) }
    }

    @Test(arguments: [
        URLError(.notConnectedToInternet) as any Error,
        CustomError() as any Error,
    ])
    func loadRecipes_onAnyOtherClientError_throwsUnavailable(clientError: any Error) async {
        let (sut, spy) = makeSUT()
        spy.stub(error: clientError)

        await #expect(throws: RecipeError.unavailable) { try await sut.loadRecipes() }
    }
}

// MARK: - Helpers

private extension RecipeListServiceTests {
    typealias SUTBundle = (sut: RemoteRecipeListService, spy: RecipeAPIClientSpy)

    struct CustomError: Error {}

    func makeSUT(baseURL: URL = URL(string: "https://api.recimate.example")!) -> SUTBundle {
        let spy = RecipeAPIClientSpy()
        let sut = RemoteRecipeListService(baseURL: baseURL, client: spy)
        return (sut, spy)
    }

    func makeListData(_ previews: [RecipePreview]) -> Data {
        makeJSONData(previews.map(makePreviewJSON(from:)))
    }

    nonisolated static func undecodablePayloads() -> [Data] {
        // One undecodable item in the middle fails the whole list.
        var wrongType = makePreviewJSON(from: .lemonHerbChicken)
        wrongType["servings"] = "four"
        return [
            Data("not json".utf8),
            makeJSONData(["id": "an object, not an array"]),
            makeJSONData([makePreviewJSON(from: .petitGateau), wrongType, makePreviewJSON(from: .roastedVegetableCouscous)]),
        ]
    }
}
