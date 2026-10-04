import Foundation

/// What the rest of the app can learn about a failed load. Three outcomes the
/// caller can react to. Only `invalidData` says why, because the reason is
/// useful to whoever decides what to do with bad data.
enum RecipeError: Error, Equatable, Sendable {
    /// The recipe does not exist.
    case notFound
    /// The data arrived but does not decode. `reason` is the decoder's description
    /// of what was wrong (the missing key, the wrong type, the path to it).
    case invalidData(reason: String)
    /// Anything else went wrong. The cause is not the data, so retrying makes sense.
    case unavailable
}
