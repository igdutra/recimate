import Foundation

/// The URL map of the recipe API. Services ask an endpoint for their URL, so
/// base-URL handling and id encoding live in one place.
///
/// Assumption: the base URL carries no query and no fragment.
enum RecipeEndpoint: Sendable {
    /// `GET /recipes`, the collection, with optional query items, each omitted when
    /// unset: `vegetarian=true`,
    /// `servings=<n>`,
    ///  repeated `include=<term>`,
    ///  repeated`exclude=<term>`
    ///  and `instructions=<text>`.
    ///  With no filters it lists every recipe.
    case list(query: RecipeSearchQuery)
    /// `GET /recipes/{id}`, one member of the collection.
    case details(id: String)

    /// `URL.appending` keeps the base URL's scheme, port and path prefix, ignores
    /// a trailing slash, and percent-encodes an id as a single path component.
    /// Assumption: ids are trusted (they come from `GET /recipes`); the dot
    /// segments `.` and `..` are not encoded (see BACKLOG.md, URL handling).
    func url(baseURL: URL) -> URL {
        switch self {
        case let .list(query):
            Self.listURL(for: query, baseURL: baseURL)
        case let .details(id):
            baseURL.appending(component: "recipes").appending(component: id)
        }
    }

    // MARK: - Query

    /// Blank values are dropped here, in one place, so a blank search field or an
    /// empty term never reaches the server. `URLComponents` percent-encodes spaces,
    /// accents and `&` inside a value. Limitation: it leaves a `+` as is, which a
    /// real server could read as a space.
    private static func listURL(for query: RecipeSearchQuery, baseURL: URL) -> URL {
        let collectionURL = baseURL.appending(component: "recipes")
        var queryItems: [URLQueryItem] = []
        if query.onlyVegetarian {
            queryItems.append(URLQueryItem(name: "vegetarian", value: "true"))
        }
        if let servings = query.servings {
            queryItems.append(URLQueryItem(name: "servings", value: String(servings)))
        }
        for term in trimmedNonBlank(query.includedIngredients) {
            queryItems.append(URLQueryItem(name: "include", value: term))
        }
        for term in trimmedNonBlank(query.excludedIngredients) {
            queryItems.append(URLQueryItem(name: "exclude", value: term))
        }
        for text in trimmedNonBlank([query.instructionText]) {
            queryItems.append(URLQueryItem(name: "instructions", value: text))
        }
        guard !queryItems.isEmpty,
              var components = URLComponents(url: collectionURL, resolvingAgainstBaseURL: false)
        else { return collectionURL }
        components.queryItems = queryItems
        return components.url ?? collectionURL
    }

    private static func trimmedNonBlank(_ values: [String]) -> [String] {
        values
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
