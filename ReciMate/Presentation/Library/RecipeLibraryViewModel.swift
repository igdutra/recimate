import Observation

@MainActor
@Observable
final class RecipeLibraryViewModel {
    let filtersViewModel: FiltersViewModel
    private(set) var viewData = RecipeLibraryViewData(state: .loading, cards: [], activeFilterCount: 0)

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

    init(service: any RecipeListService) {
        self.service = service
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

    func didChangeSearch(_ searchText: String) {
        guard searchText != query.instructionText else { return }
        query.instructionText = searchText
        startSearch()
    }

    /// The sheet reports the filters only; the search text stays as typed.
    private func didChangeFilters(_ filters: RecipeSearchQuery) {
        var updatedQuery = filters
        updatedQuery.instructionText = query.instructionText
        query = updatedQuery
        // The button reflects the filters at once; the recipes follow with the result.
        viewData = makeViewData(state: viewData.state, cards: viewData.cards)
        startSearch()
    }

    // MARK: - Searching

    /// Takes the next search number and cancels the previous search as a courtesy.
    private func beginSearch() -> Int {
        latestSearchNumber += 1
        searchTask?.cancel()
        return latestSearchNumber
    }

    private func startSearch() {
        let searchNumber = beginSearch()
        searchTask = Task { await runSearch(number: searchNumber) }
    }

    /// Later searches keep the state and the old cards until their result arrives,
    /// so the grid does not flicker. A cancelled or outdated search presents nothing,
    /// not even an error.
    private func runSearch(number searchNumber: Int) async {
        do {
            let previews = try await service.loadRecipes(matching: query)
            guard isCurrent(searchNumber) else { return }
            viewData = makeViewData(state: .loaded, cards: previews.map(Self.makeCard))
        } catch {
            guard isCurrent(searchNumber), !(error is CancellationError) else { return }
            let recipeError = error as? RecipeError ?? .unavailable
            viewData = makeViewData(state: .error(recipeError), cards: viewData.cards)
        }
    }

    private func isCurrent(_ searchNumber: Int) -> Bool {
        searchNumber == latestSearchNumber && !Task.isCancelled
    }

    private func makeViewData(state: ViewState, cards: [RecipeCardViewData]) -> RecipeLibraryViewData {
        RecipeLibraryViewData(state: state, cards: cards, activeFilterCount: query.activeFilterCount)
    }

    // MARK: - Mapping

    /// Builds a card's view data from a domain preview, once per recipe per load.
    static func makeCard(from preview: RecipePreview) -> RecipeCardViewData {
        RecipeCardViewData(
            id: preview.id,
            title: preview.title,
            servingsLabel: ServingsLabelFormatter.label(forServingCount: preview.servings),
            isVegetarian: preview.dietaryAttributes.isVegetarian,
            imageURL: preview.imageURL
        )
    }
}
