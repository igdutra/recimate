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
    @State private var searchText: String
    private let router: AppRouter

    /// `searchText` is only for previews, to show the field already filled.
    init(viewModel: RecipeLibraryViewModel, router: AppRouter, searchText: String = "") {
        _viewModel = State(initialValue: viewModel)
        _searchText = State(initialValue: searchText)
        self.router = router
    }

    var body: some View {
        // The title, search field and toolbar are always there, so the screen keeps its
        // shape while loading and when nothing matches. The scroll view also gives
        // `.task` a view to attach to. The loading and error views are a later spec.
        ScrollView {
            RecipeGrid(cards: viewModel.viewData.cards, router: router)
        }
        .searchable(text: $searchText, prompt: "Search instructions")
        // After `.searchable`, so the system view can read the query from the field.
        .overlay {
            if viewModel.viewData.hasNoResults {
                ContentUnavailableView.search
            }
        }
        .onChange(of: searchText) { _, newSearchText in
            viewModel.didChangeSearch(newSearchText)
        }
        .navigationTitle("Recipes")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                FiltersButton(activeFilterCount: viewModel.viewData.activeFilterCount) {
                    router.present(.filters)
                }
            }
        }
        .task {
            await viewModel.load()
        }
    }
}

// MARK: - FiltersButton

/// The toolbar button that opens the Filters sheet. Prominent while any filter is on,
/// and VoiceOver hears how many. Search text is not a filter, so it never changes it.
private struct FiltersButton: View {
    let activeFilterCount: Int
    let action: () -> Void

    private var isActive: Bool { activeFilterCount > 0 }

    var body: some View {
        if isActive {
            filtersButton.buttonStyle(.borderedProminent)
        } else {
            filtersButton.buttonStyle(.automatic)
        }
    }

    private var filtersButton: some View {
        Button("Filters", systemImage: "slider.horizontal.3", action: action)
            .accessibilityLabel(isActive ? "Filters, \(activeFilterCount) active" : "Filters")
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
private extension RecipeLibraryView {
    /// A Library over sample recipes. `previews` is what every search returns.
    static func preview(
        previews: [RecipePreview] = RecipePreview.previewSamples,
        searchText: String = "",
        configure: (RecipeLibraryViewModel) -> Void = { _ in }
    ) -> some View {
        let viewModel = RecipeLibraryViewModel(service: PreviewRecipeListService(previews: previews))
        configure(viewModel)
        return NavigationStack {
            RecipeLibraryView(viewModel: viewModel, router: AppRouter(), searchText: searchText)
        }
    }
}

#Preview("Library, sample recipes") {
    RecipeLibraryView.preview()
}

#Preview("Library, filtered, button active") {
    RecipeLibraryView.preview(previews: Array(RecipePreview.previewSamples.prefix(2))) { viewModel in
        viewModel.filtersViewModel.setVegetarianOnly(true)
        viewModel.filtersViewModel.chooseServings(.count(2))
    }
}

#Preview("Library, no results from text") {
    RecipeLibraryView.preview(previews: [], searchText: "tofu lasagna")
}

#Preview("Library, no results from filters only") {
    RecipeLibraryView.preview(previews: []) { viewModel in
        viewModel.filtersViewModel.setVegetarianOnly(true)
        viewModel.filtersViewModel.chooseServings(.count(5))
    }
}

#Preview("Library, sample recipes, large Dynamic Type") {
    RecipeLibraryView.preview()
        .dynamicTypeSize(.accessibility2)
}
#endif
