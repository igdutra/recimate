import Observation

/// The logic of the Filters sheet. Holds the filter part of the query, applies the
/// query's rules (blank and repeated terms, a term never in both lists) and tells the
/// Library view model about every change, so the recipes behind the sheet update live.
@MainActor
@Observable
final class FiltersViewModel {
    private(set) var viewData: FiltersSheetViewData

    /// Called once per change, with the new filters (the search text is empty). Not
    /// called for an action that changes nothing, such as a blank or repeated term.
    /// Set by the Library view model, which owns this one.
    @ObservationIgnored var onChange: (@MainActor (RecipeSearchQuery) -> Void)?

    @ObservationIgnored private var filters: RecipeSearchQuery

    init(filters: RecipeSearchQuery = .empty) {
        self.filters = filters
        viewData = Self.makeViewData(from: filters)
    }

    // MARK: - Actions

    func setVegetarianOnly(_ isVegetarianOnly: Bool) {
        change { $0.onlyVegetarian = isVegetarianOnly }
    }

    func chooseServings(_ choice: ServingsChoice) {
        switch choice {
        case .any:
            change { $0.servings = nil }
        case .count(let servingCount):
            change { $0.servings = servingCount }
        }
    }

    func submitIncludedTerm(_ term: String) {
        change { $0.addIncludedIngredient(term) }
    }

    func submitExcludedTerm(_ term: String) {
        change { $0.addExcludedIngredient(term) }
    }

    func removeIncludedTerm(_ term: String) {
        change { $0.removeIncludedIngredient(term) }
    }

    func removeExcludedTerm(_ term: String) {
        change { $0.removeExcludedIngredient(term) }
    }

    func reset() {
        change { $0.resetFilters() }
    }

    // MARK: - Private

    private func change(_ mutation: (inout RecipeSearchQuery) -> Void) {
        var updatedFilters = filters
        mutation(&updatedFilters)
        guard updatedFilters != filters else { return }
        filters = updatedFilters
        viewData = Self.makeViewData(from: updatedFilters)
        onChange?(updatedFilters)
    }

    private static func makeViewData(from filters: RecipeSearchQuery) -> FiltersSheetViewData {
        FiltersSheetViewData(
            isVegetarianOnly: filters.onlyVegetarian,
            servingsChoice: filters.servings.map(ServingsChoice.count) ?? .any,
            includedTerms: filters.includedIngredients,
            excludedTerms: filters.excludedIngredients,
            isResetEnabled: filters.hasFilters
        )
    }
}
