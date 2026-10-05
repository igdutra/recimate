extension RecipeError {
    /// The message under "Couldn't Load". It fits both screens, since the state overlay does
    /// not know which one it covers, and promises nothing about a retry. `invalidData`'s
    /// reason is never shown.
    var errorMessage: String {
        switch self {
        case .notFound:
            "We couldn't find what you were looking for."
        case .invalidData:
            "The data we received couldn't be read."
        case .unavailable:
            "Something went wrong while loading."
        }
    }
}
