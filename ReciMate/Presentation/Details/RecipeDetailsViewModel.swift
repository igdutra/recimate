import Observation

@MainActor
@Observable
final class RecipeDetailsViewModel {
    private(set) var viewData = RecipeDetailsViewData(state: .loading, content: .placeholder)

    @ObservationIgnored private let recipeID: String
    @ObservationIgnored private let service: any RecipeDetailsService
    /// Starts as `.loading`, so the state cannot tell a load in flight from one not
    /// started yet; this flag does.
    @ObservationIgnored private var isLoadInFlight = false

    init(recipeID: String, service: any RecipeDetailsService) {
        self.recipeID = recipeID
        self.service = service
    }

    /// Loads the recipe once. Returns at once if already loaded or a load is in flight;
    /// runs again after an error. A cancelled load is not special-cased: it ends as
    /// `.error` (see backlog, "Cancellation handling").
    func load() async {
        guard !viewData.state.isLoaded, !isLoadInFlight else { return }
        isLoadInFlight = true
        defer { isLoadInFlight = false }
        // `content` is still `.placeholder` here: the guard lets only a first load or a
        // retry after an error through, and neither ever had content.
        viewData.state = .loading
        do {
            let recipe = try await service.loadRecipe(id: recipeID)
            viewData.content = Self.makeContent(from: recipe)
            viewData.state = .loaded
        } catch let recipeError as RecipeError {
            viewData.state = .error(recipeError)
        } catch {
            viewData.state = .error(.unavailable)
        }
    }

    // MARK: - Mapping

    /// Builds the page's view data from a domain recipe, once per load.
    static func makeContent(from recipe: RecipeDetails) -> RecipeDetailsContentViewData {
        RecipeDetailsContentViewData(
            title: recipe.title,
            summary: recipe.summary,
            servingsLabel: ServingsLabelFormatter.label(forServingCount: recipe.servings),
            isVegetarian: recipe.dietaryAttributes.isVegetarian,
            imageURL: recipe.imageURL,
            ingredients: recipe.ingredients.map {
                IngredientRowViewData(id: $0.id, name: $0.name, quantity: $0.quantity)
            },
            steps: recipe.instructions.map {
                StepRowViewData(number: $0.step, text: $0.text)
            }
        )
    }
}
