import Foundation

/// Loads one recipe through a `RecipeAPIClient`, maps it to a domain value and
/// translates every failure into a `RecipeError`.
struct RemoteRecipeDetailsService: RecipeDetailsService {
    let baseURL: URL
    let client: any RecipeAPIClient

    func loadRecipe(id: String) async throws -> RecipeDetails {
        // Ids that cannot name a recipe never reach the client. `.` and `..`
        // are not percent-encoded by `URL.appending`, so they would traverse.
        guard !id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, id != ".", id != ".." else {
            throw RecipeError.notFound
        }
        return try await load(id: id)
    }

    /// `@concurrent`: see `RemoteRecipeListService.load()`.
    @concurrent
    private func load(id: String) async throws -> RecipeDetails {
        let url = RecipeEndpoint.details(id: id).url(baseURL: baseURL)
        do {
            let data = try await client.data(from: url)
            let detailsDTO = try RecipeDetailsDataMapper.map(data)
            return RecipeDetailsMapper.map(detailsDTO)
        } catch let error as RecipeError {
            throw error
        } catch RecipeAPIClientError.notFound {
            throw RecipeError.notFound
        } catch {
            throw RecipeError.unavailable
        }
    }
}
