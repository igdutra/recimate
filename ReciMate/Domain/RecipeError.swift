import Foundation

/// What the rest of the app can learn about a failed load. Three outcomes the
/// caller can react to. Only `invalidData` says why, because the reason is
/// useful to whoever decides what to do with bad data.
enum RecipeError: Error, Equatable, Sendable {
    /// The recipe does not exist.
    case notFound
    /// The data arrived but does not decode. `reason` is `String(describing:)` of the
    /// `DecodingError`: the missing key, the wrong type and its path, or "not valid JSON".
    /// Not `localizedDescription`, which says only "couldn't be read". A `String`, not the
    /// error itself, keeps this type `Equatable` and `Sendable`. Never shown to the person.
    case invalidData(reason: String)
    /// Anything else went wrong. The cause is not the data, so retrying makes sense.
    case unavailable
}
