import Foundation
import Testing
@testable import ReciMate

@MainActor
struct RecipeListServiceTests {
    @Test(arguments: ["https://api.recimate.example", "http://localhost:8080/v2"])
    func loadRecipes_requestsListEndpointURL(baseURLString: String) async throws {
        let baseURL = URL(string: baseURLString)!
        let (service, clientSpy) = makeSUT(baseURL: baseURL)
        clientSpy.stub(data: makeListData([]))

        _ = try await service.loadRecipes()

        #expect(clientSpy.requestedURLs == [RecipeEndpoint.list.url(baseURL: baseURL)])
    }

    @Test func loadRecipes_onValidJSON_deliversMappedPreviewsInOrder() async throws {
        let (service, clientSpy) = makeSUT()
        let previews = [
            RecipePreview.fixture(id: "petit-gateau"),
            .fixture(id: "lemon-chicken", title: "Lemon Chicken", summary: "Roast.", servings: 2, isVegetarian: false),
            .fixture(id: "salad", title: "Salad", summary: "Fresh.", servings: 1, imageURL: nil),
        ]
        clientSpy.stub(data: makeListData(previews))

        let result = try await service.loadRecipes()

        #expect(result == previews)
    }

    @Test func loadRecipes_onEmptyList_deliversEmptyArray() async throws {
        let (service, clientSpy) = makeSUT()
        clientSpy.stub(data: makeListData([]))

        let result = try await service.loadRecipes()

        #expect(result.isEmpty)
    }

    @Test func loadRecipes_onClientNotFound_throwsNotFound() async {
        let (service, clientSpy) = makeSUT()
        clientSpy.stub(error: RecipeAPIClientError.notFound)

        await #expect(throws: RecipeError.notFound) { try await service.loadRecipes() }
    }

    private nonisolated static func undecodablePayloads() -> [Data] {
        // One undecodable item in the middle fails the whole list.
        var wrongType = makePreviewJSON(from: .fixture(id: "bad"))
        wrongType["servings"] = "four"
        return [
            Data("not json".utf8),
            makeJSONData(["id": "an object, not an array"]),
            makeJSONData([makePreviewJSON(from: .fixture(id: "first")), wrongType, makePreviewJSON(from: .fixture(id: "last"))]),
        ]
    }

    @Test(arguments: undecodablePayloads())
    func loadRecipes_onUndecodableData_throwsInvalidData(payload: Data) async {
        let (service, clientSpy) = makeSUT()
        clientSpy.stub(data: payload)

        await #expect { try await service.loadRecipes() } throws: { isInvalidDataWithReason($0) }
    }

    @Test(arguments: [
        URLError(.notConnectedToInternet) as any Error,
        CustomError() as any Error,
    ])
    func loadRecipes_onAnyOtherClientError_throwsUnavailable(clientError: any Error) async {
        let (service, clientSpy) = makeSUT()
        clientSpy.stub(error: clientError)

        await #expect(throws: RecipeError.unavailable) { try await service.loadRecipes() }
    }

    // MARK: - Helpers

    private struct CustomError: Error {}

    private func makeSUT(
        baseURL: URL = URL(string: "https://api.recimate.example")!
    ) -> (service: RemoteRecipeListService, clientSpy: RecipeAPIClientSpy) {
        let clientSpy = RecipeAPIClientSpy()
        return (RemoteRecipeListService(baseURL: baseURL, client: clientSpy), clientSpy)
    }

    private func makeListData(_ previews: [RecipePreview]) -> Data {
        makeJSONData(previews.map(makePreviewJSON(from:)))
    }
}
