// DEVELOPMENT ASSETS: this whole folder is listed in DEVELOPMENT_ASSET_PATHS (app target).
// Xcode leaves these files out of the build input only when ARCHIVING, but they are still
// compiled in every other build. So any code that uses them in a Release/Archive build would
// not find them and fail the archive, a failure that tends to show up late, in CI.
// Therefore: (1) wrap every file here in `#if DEBUG`, and (2) only reference these types from
// code that is also inside `#if DEBUG`, such as `#Preview` blocks.

#if DEBUG

/// The sample recipes as the cards the screen shows, built with the production mapper so a
/// preview cannot drift from what the app does.
extension RecipeCardViewData {
    @MainActor static let previewSamples: [RecipeCardViewData] = RecipePreview.previewSamples.map { RecipeLibraryViewModel.makeCard(from: $0) }
}
#endif
