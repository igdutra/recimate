import Foundation
import Observation

@MainActor
@Observable
final class RecipeLibraryViewModel {
    let filtersViewModel: FiltersViewModel
    private(set) var viewData = RecipeLibraryViewData(
        state: .loading, cards: [], activeFilterCount: 0, searchedText: "", searchedWithFilters: false
    )

    @ObservationIgnored private let service: any RecipeListService
    /// The one query the screen is showing: the search text plus the sheet's filters.
    @ObservationIgnored private var query = RecipeSearchQuery.empty
    /// Starts as `.loading`, so the state cannot tell a load in flight from one not
    /// started yet; this flag does.
    @ObservationIgnored private var isLoadInFlight = false
    /// Each search takes the next number and only the latest may present its result,
    /// so a slow reply that arrives late, or work that was cancelled, never shows.
    @ObservationIgnored private var latestSearchNumber = 0
    @ObservationIgnored private var searchTask: Task<Void, Never>?
    /// Successful results by the query that produced them, so going back to a query
    /// already searched (clearing the text, turning a filter off) is instant. Rudimentary
    /// on purpose: no expiry, no size limit, never invalidated, lost with the view model.
    /// Failures are never stored. See "Search result cache" in docs/decisions.md.
    @ObservationIgnored private var cachedPreviews: [RecipeSearchQuery: [RecipePreview]] = [:]
    /// How long typing must pause before a search starts. Tests pass `.zero`.
    @ObservationIgnored private let searchDebounce: Duration

    init(service: any RecipeListService, searchDebounce: Duration = .milliseconds(300)) {
        self.service = service
        self.searchDebounce = searchDebounce
        filtersViewModel = FiltersViewModel()
        filtersViewModel.onChange = { [weak self] filters in
            self?.didChangeFilters(filters)
        }
    }

    /// Runs the first search (the empty query, so every recipe) and presents it.
    /// Returns at once if already loaded or a load is in flight. After an error it
    /// searches again.
    func load() async {
        guard !viewData.state.isLoaded, !isLoadInFlight else { return }
        isLoadInFlight = true
        defer { isLoadInFlight = false }
        viewData = makeViewData(state: .loading, cards: viewData.cards)
        let searchNumber = beginSearch()
        await runSearch(number: searchNumber)
    }

    /// Stores the trimmed text, so "pasta" and "pasta " are one search, and searches once
    /// typing pauses (debounce, not throttle: nobody wants the results for every prefix).
    func didChangeSearch(_ searchText: String) {
        let trimmedText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedText != query.searchText else { return }
        query.searchText = trimmedText
        startSearch(debounce: searchDebounce)
    }

    /// The sheet reports the filters only; the search text stays as typed.
    private func didChangeFilters(_ filters: RecipeSearchQuery) {
        var updatedQuery = filters
        updatedQuery.searchText = query.searchText
        updatedQuery.instructionText = query.instructionText
        query = updatedQuery
        // The button reflects the filters at once; the recipes follow with the result.
        viewData = makeViewData(state: viewData.state, cards: viewData.cards)
        startSearch(debounce: .zero)
    }

    /// Turns every filter off; the search text stays. The filters view model reports the
    /// change through `onChange`, which searches again.
    func clearFilters() {
        filtersViewModel.reset()
    }

    // MARK: - Searching

    /// Takes the next search number and cancels the previous search as a courtesy.
    private func beginSearch() -> Int {
        latestSearchNumber += 1
        searchTask?.cancel()
        return latestSearchNumber
    }

    /// Waits `debounce` first. The next search cancels this task (`beginSearch()`), so only
    /// the last one reaches the service. Not `try?`: it would swallow the cancellation and
    /// search anyway.
    private func startSearch(debounce: Duration) {
        let searchNumber = beginSearch()
        // A query searched before is presented at once: no debounce, no spinner. Taking the
        // number above already dropped any search still in flight.
        if let previews = cachedPreviews[query] {
            present(previews, for: query)
            return
        }
        searchTask = Task {
            do {
                try await Task.sleep(for: debounce)
            } catch {
                return
            }
            await runSearch(number: searchNumber)
        }
    }

    /// Every search shows the loading state while it waits, like the first load, so the
    /// person gets feedback; the old cards stay in the view data underneath until the
    /// result replaces them. A cancelled or outdated search presents nothing, not even
    /// an error.
    private func runSearch(number searchNumber: Int) async {
        viewData = makeViewData(state: .loading, cards: viewData.cards)
        do {
            // The query as sent: later keystrokes or filter changes must not leak into
            // what this result says it searched.
            let searchedQuery = query
            let previews = try await service.loadRecipes(matching: searchedQuery)
            guard isCurrent(searchNumber) else { return }
            cachedPreviews[searchedQuery] = previews
            present(previews, for: searchedQuery)
        } catch {
            guard isCurrent(searchNumber), !(error is CancellationError) else { return }
            let recipeError = error as? RecipeError ?? .unavailable
            viewData = makeViewData(state: .error(recipeError), cards: viewData.cards)
        }
    }

    private func present(_ previews: [RecipePreview], for searchedQuery: RecipeSearchQuery) {
        viewData = RecipeLibraryViewData(
            state: .loaded,
            cards: previews.map { Self.makeCard(from: $0, searchedText: searchedQuery.searchText) },
            activeFilterCount: query.activeFilterCount,
            searchedText: searchedQuery.searchText,
            searchedWithFilters: searchedQuery.hasFilters
        )
    }

    private func isCurrent(_ searchNumber: Int) -> Bool {
        searchNumber == latestSearchNumber && !Task.isCancelled
    }

    private func makeViewData(state: ViewState, cards: [RecipeCardViewData]) -> RecipeLibraryViewData {
        RecipeLibraryViewData(
            state: state,
            cards: cards,
            activeFilterCount: query.activeFilterCount,
            searchedText: viewData.searchedText,
            searchedWithFilters: viewData.searchedWithFilters
        )
    }

    // MARK: - Mapping

    /// Builds a card's view data from a domain preview, once per recipe per load.
    /// A card is a step-only match when the searched text is not blank and the title does
    /// not contain it. Assumption: this is the same rule the fake server uses; a real
    /// backend with its own matching would have to return where the text matched.
    static func makeCard(from preview: RecipePreview, searchedText: String = "") -> RecipeCardViewData {
        let hasSearchedText = !SearchTextMatching.folded(searchedText).isEmpty
        return RecipeCardViewData(
            id: preview.id,
            title: preview.title,
            servingsLabel: ServingsLabelFormatter.label(forServingCount: preview.servings),
            isVegetarian: preview.dietaryAttributes.isVegetarian,
            imageURL: preview.imageURL,
            isStepOnlyMatch: hasSearchedText && !SearchTextMatching.text(preview.title, contains: searchedText)
        )
    }
}
