import Foundation

/// Where a screen's data is in its life. There is no `idle` case: a screen starts
/// in `loading`, because the first load starts as soon as the screen appears. `error` holds a `RecipeError` rather
/// than `any Error` so the whole enum stays `Equatable`.
enum ViewState: Equatable, Sendable {
    case loading
    case loaded
    case error(RecipeError)

    var isLoading: Bool {
        self == .loading
    }

    var isLoaded: Bool {
        self == .loaded
    }

    var error: RecipeError? {
        if case .error(let recipeError) = self {
            return recipeError
        }
        return nil
    }
}
