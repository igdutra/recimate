import Foundation

/// The URL map of the recipe API. Services ask an endpoint for their URL, so
/// base-URL handling and id encoding live in one place.
///
/// Assumption: the base URL carries no query and no fragment.
enum RecipeEndpoint: Sendable {
    /// `GET /recipe-list`
    case list
    /// `GET /recipe-details/{id}`
    case details(id: String)

    /// `URL.appending` keeps the base URL's scheme, port and path prefix, ignores
    /// a trailing slash, and percent-encodes an id as a single path component.
    /// The dot segments `.` and `..` are not encoded; services reject them first.
    func url(baseURL: URL) -> URL {
        switch self {
        case .list:
            baseURL.appending(component: "recipe-list")
        case let .details(id):
            baseURL.appending(component: "recipe-details").appending(component: id)
        }
    }
}
