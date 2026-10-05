import Testing
@testable import ReciMate

/// A `RecipeListService` the test controls: every `loadRecipes(matching:)` call is recorded
/// with its query and waits until the test completes or fails it. `@MainActor` like `RecipeAPIClientSpy`,
/// with the method marked `@MainActor` so the conformance to the `Sendable` protocol compiles.
@MainActor
final class RecipeListServiceSpy: RecipeListService {
    private let serviceSpy = ServiceSpy<RecipeSearchQuery, [RecipePreview]>()

    var requestCount: Int { serviceSpy.requests.count }
    var requestedQueries: [RecipeSearchQuery] { serviceSpy.requests.map(\.parameter) }

    @MainActor func loadRecipes(matching query: RecipeSearchQuery) async throws -> [RecipePreview] {
        try await serviceSpy.load(query)
    }

    func waitUntilRequested(count: Int = 1, sourceLocation: SourceLocation = #_sourceLocation) async {
        await serviceSpy.waitUntilRequested(count: count, sourceLocation: sourceLocation)
    }

    func complete(with previews: [RecipePreview], at requestIndex: Int = 0, sourceLocation: SourceLocation = #_sourceLocation) async {
        await serviceSpy.complete(with: previews, at: requestIndex, sourceLocation: sourceLocation)
    }

    func fail(with error: any Error, at requestIndex: Int = 0, sourceLocation: SourceLocation = #_sourceLocation) async {
        await serviceSpy.fail(with: error, at: requestIndex, sourceLocation: sourceLocation)
    }

    func failPendingRequests(sourceLocation: SourceLocation = #_sourceLocation) async {
        await serviceSpy.failPendingRequests(sourceLocation: sourceLocation)
    }
}
