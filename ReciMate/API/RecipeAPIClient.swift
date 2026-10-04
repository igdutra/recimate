import Foundation

/// Fetches the bytes at an address. Knows nothing about recipes, DTOs or
/// domain errors, so a URLSession client can replace the local one without
/// touching a service.
protocol RecipeAPIClient: Sendable {
    func data(from url: URL) async throws -> Data
}

/// The error every `RecipeAPIClient` throws for a resource that does not exist,
/// so services never inspect Foundation file errors or HTTP status codes.
enum RecipeAPIClientError: Error, Sendable {
    case notFound
}
