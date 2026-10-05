import Foundation

/// Stands in for the server side of `GET /recipes`: parses the query items,
/// filters the full-record catalog and answers with list-shaped JSON (preview
/// fields only, no ingredients or steps). Exists only because the data is mocked;
/// it goes away with `LocalRecipeAPIClient` when a real backend replaces the mock.
///
/// Matching rules (documented in the spec 008 notes):
/// - Instruction text: one phrase, case- and diacritic-insensitive "contains",
///   against any single step.
/// - Include terms: AND. Exclude terms: a recipe is dropped if any matches. Both
///   are "contains" on ingredient names, ignoring case and accents.
/// - The same term included and excluded matches nothing (it falls out of the rules).
/// - A recipe with no ingredient or step data fails an include filter and passes an
///   exclude filter.
/// - Servings is exact; a value below 1 matches nothing.
/// - Vegetarian off is no filter. Results keep catalog order.
struct LocalRecipeSearchServer: Sendable {
    let catalogData: Data

    /// Answers a search request. A catalog that does not decode is a thrown
    /// `DecodingError`, like any other failure reading the mock.
    func response(for url: URL) throws -> Data {
        let catalog = try JSONDecoder().decode([CatalogRecipe].self, from: catalogData)
        let query = Self.query(from: url)
        let previews = catalog.filter { $0.matches(query) }.map(\.preview)
        return try JSONEncoder().encode(previews)
    }

    /// The inverse of `RecipeEndpoint.list(query:)`: query items back to a query. Repeated
    /// `include` and `exclude` items are kept in order and not deduplicated, so a
    /// request holding one term in both lists reaches the filter as sent.
    static func query(from url: URL) -> RecipeSearchQuery {
        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        func values(named name: String) -> [String] {
            queryItems
                .filter { $0.name == name }
                .compactMap(\.value)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }
        return RecipeSearchQuery(
            instructionText: values(named: "instructions").first ?? "",
            onlyVegetarian: values(named: "vegetarian").first == "true",
            servings: values(named: "servings").first.flatMap { Int($0) },
            includedIngredients: values(named: "include"),
            excludedIngredients: values(named: "exclude")
        )
    }
}

// MARK: - Catalog

/// One record of `recipe-catalog.json`: the list fields plus the data only the
/// details endpoint carries. Ingredients and steps are optional and default to empty.
private struct CatalogRecipe: Decodable {
    let preview: RecipePreviewDTO
    let ingredients: [IngredientDTO]
    let cookingInstructions: [CookingInstructionDTO]

    enum CodingKeys: String, CodingKey {
        case ingredients
        case cookingInstructions = "cooking_instructions"
    }

    init(from decoder: any Decoder) throws {
        preview = try RecipePreviewDTO(from: decoder)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        ingredients = try container.decodeIfPresent([IngredientDTO].self, forKey: .ingredients) ?? []
        cookingInstructions = try container.decodeIfPresent([CookingInstructionDTO].self, forKey: .cookingInstructions) ?? []
    }

    func matches(_ query: RecipeSearchQuery) -> Bool {
        if query.onlyVegetarian, !preview.dietaryAttributes.isVegetarian { return false }
        if let servings = query.servings, servings < 1 || preview.servings != servings { return false }
        if !SearchTextMatching.folded(query.instructionText).isEmpty,
           !cookingInstructions.contains(where: { SearchTextMatching.text($0.text, contains: query.instructionText) }) {
            return false
        }
        let ingredientNames = ingredients.map(\.name)
        for term in query.includedIngredients
        where !ingredientNames.contains(where: { SearchTextMatching.text($0, contains: term) }) {
            return false
        }
        for term in query.excludedIngredients
        where ingredientNames.contains(where: { SearchTextMatching.text($0, contains: term) }) {
            return false
        }
        return true
    }
}
