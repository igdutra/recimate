import Foundation

/// What the person asked for: instruction text plus the four filters of the brief.
/// A value type; the rules of the Filters sheet (what a term is, that a term can
/// never sit in both lists) live in its mutating helpers so they are testable
/// without a view.
struct RecipeSearchQuery: Equatable, Sendable {
    /// Matched against the cooking steps. Search text is not a filter: it never
    /// counts as active and `resetFilters()` keeps it.
    var instructionText: String
    /// Off means "no filter", never "non-vegetarian only".
    var onlyVegetarian: Bool
    /// Exact match. `nil` means any.
    var servings: Int?
    /// Ordered, no repeats when built through the helpers.
    var includedIngredients: [String]
    var excludedIngredients: [String]

    static let empty = RecipeSearchQuery()

    init(
        instructionText: String = "",
        onlyVegetarian: Bool = false,
        servings: Int? = nil,
        includedIngredients: [String] = [],
        excludedIngredients: [String] = []
    ) {
        self.instructionText = instructionText
        self.onlyVegetarian = onlyVegetarian
        self.servings = servings
        self.includedIngredients = includedIngredients
        self.excludedIngredients = excludedIngredients
    }

    /// Vegetarian counts 1, servings counts 1, each ingredient term counts 1.
    var activeFilterCount: Int {
        (onlyVegetarian ? 1 : 0)
            + (servings == nil ? 0 : 1)
            + includedIngredients.count
            + excludedIngredients.count
    }

    var hasFilters: Bool { activeFilterCount > 0 }

    // MARK: - Ingredient terms

    /// Adds a term to the include list and removes it from the exclude list.
    /// Blank terms and repeats (ignoring case and accents) are ignored.
    mutating func addIncludedIngredient(_ term: String) {
        Self.add(term, to: &includedIngredients, removingFrom: &excludedIngredients)
    }

    /// Adds a term to the exclude list and removes it from the include list.
    mutating func addExcludedIngredient(_ term: String) {
        Self.add(term, to: &excludedIngredients, removingFrom: &includedIngredients)
    }

    mutating func removeIncludedIngredient(_ term: String) {
        Self.remove(term, from: &includedIngredients)
    }

    mutating func removeExcludedIngredient(_ term: String) {
        Self.remove(term, from: &excludedIngredients)
    }

    /// Clears every filter and keeps the search text.
    mutating func resetFilters() {
        onlyVegetarian = false
        servings = nil
        includedIngredients = []
        excludedIngredients = []
    }

    private static func add(_ term: String, to targetList: inout [String], removingFrom otherList: inout [String]) {
        let trimmedTerm = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTerm.isEmpty else { return }
        let foldedTerm = SearchTextMatching.folded(trimmedTerm)
        otherList.removeAll { SearchTextMatching.folded($0) == foldedTerm }
        guard !targetList.contains(where: { SearchTextMatching.folded($0) == foldedTerm }) else { return }
        targetList.append(trimmedTerm)
    }

    private static func remove(_ term: String, from list: inout [String]) {
        let foldedTerm = SearchTextMatching.folded(term)
        list.removeAll { SearchTextMatching.folded($0) == foldedTerm }
    }
}

/// The one definition of "same text" for search: ignoring case, accents and
/// surrounding whitespace. Shared by the query rules and the fake server.
enum SearchTextMatching {
    static func folded(_ text: String) -> String {
        text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
    }

    /// Whether `text` contains `term` as a phrase, ignoring case and accents. A plain
    /// substring search (no regular expression), and it does not copy `text`.
    static func text(_ text: String, contains term: String) -> Bool {
        let trimmedTerm = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTerm.isEmpty else { return true }
        return text.range(of: trimmedTerm, options: [.caseInsensitive, .diacriticInsensitive]) != nil
    }
}
