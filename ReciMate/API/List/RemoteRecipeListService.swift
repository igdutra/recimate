import Foundation

/// Loads the list through a `RecipeAPIClient`, maps it to domain values and
/// translates every failure into a `RecipeError`.
struct RemoteRecipeListService: RecipeListService {
    let baseURL: URL
    let client: any RecipeAPIClient

    func loadRecipes() async throws -> [RecipePreview] {
        try await load()
    }

    /// `@concurrent` so the read and the decoding leave the caller's actor (the
    /// main actor, from a view model) once per load. Private, so the protocol
    /// requirement keeps its default form.
    @concurrent
    private func load() async throws -> [RecipePreview] {
        let url = RecipeEndpoint.list.url(baseURL: baseURL)
        do {
            let data = try await client.data(from: url)
            let listDTO = try RecipeListDataMapper.map(data)
            return RecipeListMapper.map(listDTO)
        } catch let error as RecipeError {
            throw error
        } catch RecipeAPIClientError.notFound {
            throw RecipeError.notFound
        } catch {
            throw RecipeError.unavailable
        }
    }
}
