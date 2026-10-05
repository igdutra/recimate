// DEVELOPMENT ASSETS: this whole folder is listed in DEVELOPMENT_ASSET_PATHS (app target).
// Xcode leaves these files out of the build input only when ARCHIVING, but they are still
// compiled in every other build. So any code that uses them in a Release/Archive build would
// not find them and fail the archive, a failure that tends to show up late, in CI.
// Therefore: (1) wrap every file here in `#if DEBUG`, and (2) only reference these types from
// code that is also inside `#if DEBUG`, such as `#Preview` blocks.

#if DEBUG

/// A `RecipeDetailsService` for previews that returns one sample recipe at once (or
/// loads forever, or fails, per its `outcome`), with no network and no bundled data.
struct PreviewRecipeDetailsService: RecipeDetailsService {
    let recipe: RecipeDetails
    let outcome: PreviewOutcome

    init(recipe: RecipeDetails = RecipeDetails.previewSamples[0], outcome: PreviewOutcome = .loaded) {
        self.recipe = recipe
        self.outcome = outcome
    }

    func loadRecipe(id: String) async throws -> RecipeDetails {
        try await outcome.resolve(recipe)
    }
}
#endif
