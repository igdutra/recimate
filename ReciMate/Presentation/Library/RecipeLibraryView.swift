import SwiftUI

// MARK: - View data

/// Everything the Library screen shows, replaced as a whole on every change.
struct RecipeLibraryViewData: Equatable {
    let state: ViewState
    let cards: [RecipeCardViewData]
    /// How many filters are on (search text is not a filter); drives the Filters button.
    let activeFilterCount: Int

    /// A finished search with nothing to show, whether the text, the filters or both
    /// caused it.
    var hasNoResults: Bool {
        state.isLoaded && cards.isEmpty
    }
}

// MARK: - RecipeLibraryView

struct RecipeLibraryView: View {
    @State private var viewModel: RecipeLibraryViewModel
    @State private var searchText = ""
    private let router: AppRouter

    init(viewModel: RecipeLibraryViewModel, router: AppRouter) {
        _viewModel = State(initialValue: viewModel)
        self.router = router
    }

    var body: some View {
        // The stack lives in `RootView`. A `Group` is transparent, so with no content (loading)
        // `.task` had nothing to attach to and never ran; the `ZStack` is a real view.
        // TODO: remove this `ZStack` when the loading state lands. The state overlay will
        // render the loading view while the first state is `.loading`, so the content is
        // never empty and `.task` has a view to attach to.
        ZStack {
            // Only the loaded grid is rendered; loading and error states are a later spec.
            // The search field is attached to the loaded content so it hides with it.
            if viewModel.viewData.state.isLoaded {
                ScrollView {
                    RecipeGrid(cards: viewModel.viewData.cards, router: router)
                }
                .searchable(text: $searchText, prompt: "Search recipes")
                .onChange(of: searchText) { _, newSearchText in
                    viewModel.didChangeSearch(newSearchText)
                }
                .navigationTitle("Recipes")
                .toolbar {
                    // Temporary entry point, replaced when the filters entry point is designed.
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Filters", systemImage: "slider.horizontal.3") {
                            router.present(.filters)
                        }
                    }
                }
            }
        }
        .task {
            await viewModel.load()
        }
    }
}

// MARK: - RecipeGrid

private struct RecipeGrid: View {
    let cards: [RecipeCardViewData]
    let router: AppRouter

    private let columns = [
        GridItem(.adaptive(minimum: Constants.columnMinimumWidth), spacing: Constants.gridSpacing, alignment: .top)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: Constants.gridSpacing) {
            ForEach(cards) { card in
                Button {
                    router.push(.details(recipeID: card.id))
                } label: {
                    RecipeCardView(card: card)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Layout.screenGutter)
    }
}

private extension RecipeGrid {
    enum Constants {
        /// Smallest grid column; a 390pt screen fits two.
        static let columnMinimumWidth: CGFloat = 160
        static let gridSpacing: CGFloat = 16
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Library, sample recipes") {
    NavigationStack {
        RecipeLibraryView(viewModel: RecipeLibraryViewModel(service: PreviewRecipeListService()), router: AppRouter())
    }
}

#Preview("Library, sample recipes, large Dynamic Type") {
    NavigationStack {
        RecipeLibraryView(viewModel: RecipeLibraryViewModel(service: PreviewRecipeListService()), router: AppRouter())
    }
    .dynamicTypeSize(.accessibility2)
}
#endif
