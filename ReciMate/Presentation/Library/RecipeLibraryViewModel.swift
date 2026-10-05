import Observation

@MainActor
@Observable
final class RecipeLibraryViewModel {
    private(set) var viewData = RecipeLibraryViewData(state: .loading, cards: [])

    @ObservationIgnored private let service: any RecipeListService
    /// Starts as `.loading`, so the state cannot tell a load in flight from one not
    /// started yet; this flag does.
    @ObservationIgnored private var isLoadInFlight = false

    init(service: any RecipeListService) {
        self.service = service
    }

    /// Loads the recipes once. Returns at once if already loaded or a load is in flight.
    /// A cancelled load is not special-cased: it ends as `.error` (see backlog,
    /// "Cancellation handling").
    func load() async {
        guard !viewData.state.isLoaded, !isLoadInFlight else { return }
        isLoadInFlight = true
        defer { isLoadInFlight = false }
        viewData = RecipeLibraryViewData(state: .loading, cards: viewData.cards)
        do {
            let previews = try await service.loadRecipes()
            let cards = previews.map(Self.makeCard)
            viewData = RecipeLibraryViewData(state: .loaded, cards: cards)
        } catch let recipeError as RecipeError {
            viewData = RecipeLibraryViewData(state: .error(recipeError), cards: viewData.cards)
        } catch {
            viewData = RecipeLibraryViewData(state: .error(.unavailable), cards: viewData.cards)
        }
    }

    func didChangeSearch(_ searchText: String) {
        // TODO(milestone D): replace with the search query in the shared filter state.
        print("Search text changed: \(searchText)")
    }

    func didSubmitSearch() {
        // TODO(milestone D): replace with running the search from the shared filter state.
        print("Search submitted")
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
