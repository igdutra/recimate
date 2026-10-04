import Testing
@testable import ReciMate

/// A `RecipeDetailsService` the test controls: every `loadRecipe(id:)` call is recorded
/// and waits until the test completes or fails it. Shaped like `RecipeListServiceSpy`.
@MainActor
final class RecipeDetailsServiceSpy: RecipeDetailsService {
    private let serviceSpy = ServiceSpy<String, RecipeDetails>()

    var requestCount: Int { serviceSpy.requests.count }
    /// The ids the service was asked for, in call order.
    var requestedIDs: [String] { serviceSpy.requests.map(\.parameter) }

    @MainActor func loadRecipe(id: String) async throws -> RecipeDetails {
        try await serviceSpy.load(id)
    }

    func waitUntilRequested(count: Int = 1, sourceLocation: SourceLocation = #_sourceLocation) async {
        await serviceSpy.waitUntilRequested(count: count, sourceLocation: sourceLocation)
    }

    func complete(with recipe: RecipeDetails, at requestIndex: Int = 0, sourceLocation: SourceLocation = #_sourceLocation) async {
        await serviceSpy.complete(with: recipe, at: requestIndex, sourceLocation: sourceLocation)
    }

    func fail(with error: any Error, at requestIndex: Int = 0, sourceLocation: SourceLocation = #_sourceLocation) async {
        await serviceSpy.fail(with: error, at: requestIndex, sourceLocation: sourceLocation)
    }

    func failPendingRequests(sourceLocation: SourceLocation = #_sourceLocation) async {
        await serviceSpy.failPendingRequests(sourceLocation: sourceLocation)
    }
}
