import Foundation
@testable import ReciMate

/// Sits at the `RecipeAPIClient` seam. Stub the result up front, call the service,
/// then assert on `requestedURLs`. `@MainActor` makes the class `Sendable` without
/// any escape hatch; the suites that use it are `@MainActor` too, so the tests
/// read and stub it synchronously.
@MainActor
final class RecipeAPIClientSpy: RecipeAPIClient {
    private(set) var requestedURLs: [URL] = []

    private var stubbedResult: Result<Data, any Error> = .failure(NSError(domain: "test", code: 0))

    func stub(data: Data) {
        stubbedResult = .success(data)
    }

    func stub(error: any Error) {
        stubbedResult = .failure(error)
    }

    @MainActor func data(from url: URL) async throws -> Data {
        requestedURLs.append(url)
        return try stubbedResult.get()
    }
}
