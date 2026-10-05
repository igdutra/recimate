// DEVELOPMENT ASSETS: wrapped in `#if DEBUG` and only used from `#Preview` blocks; see
// the note at the top of `PreviewRecipeListService.swift`.

#if DEBUG

/// What a preview service does when asked, so a preview can show the loading and error states.
enum PreviewOutcome {
    /// Returns the sample data at once.
    case loaded
    /// Never returns, so the screen stays in its loading state.
    case loading
    /// Throws this error.
    case failed(RecipeError)

    /// Returns `value` for `.loaded`, waits forever for `.loading`, and throws for `.failed`.
    func resolve<Value: Sendable>(_ value: Value) async throws -> Value {
        switch self {
        case .loaded:
            return value
        case .loading:
            try await Task.sleep(for: .seconds(86_400))
            return value
        case .failed(let recipeError):
            throw recipeError
        }
    }
}
#endif
