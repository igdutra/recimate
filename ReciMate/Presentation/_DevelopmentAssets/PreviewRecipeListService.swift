// DEVELOPMENT ASSETS: this whole folder is listed in DEVELOPMENT_ASSET_PATHS (app target).
// Xcode leaves these files out of the build input only when ARCHIVING, but they are still
// compiled in every other build. So any code that uses them in a Release/Archive build would
// not find them and fail the archive, a failure that tends to show up late, in CI.
// Therefore: (1) wrap every file here in `#if DEBUG`, and (2) only reference these types from
// code that is also inside `#if DEBUG`, such as `#Preview` blocks.

#if DEBUG

/// A `RecipeListService` for previews that returns the sample recipes at once, with no
/// network and no bundled data.
struct PreviewRecipeListService: RecipeListService {
    let previews: [RecipePreview]

    init(previews: [RecipePreview] = RecipePreview.previewSamples) {
        self.previews = previews
    }

    func loadRecipes() async throws -> [RecipePreview] {
        previews
    }
}
#endif
