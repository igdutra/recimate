import SwiftUI

// MARK: - View data

/// Everything the Library screen shows, replaced as a whole on every change.
struct RecipeLibraryViewData: Equatable {
    let state: ViewState
    let cards: [RecipeCardViewData]
    /// How many filters are on (search text is not a filter); drives the Filters button.
    let activeFilterCount: Int
    /// The trimmed text of the search that produced `cards`, not the live field, which
    /// may already hold newer text that has not been searched yet.
    let searchedText: String
    /// Whether that search had filters on, not the live filters.
    let searchedWithFilters: Bool

    /// A finished search with nothing to show, whether the text, the filters or both
    /// caused it.
    var hasNoResults: Bool {
        state.isLoaded && cards.isEmpty
    }

    /// Why a finished search found nothing; `nil` while there is something to show.
    /// Neither text nor filters can only come from an empty catalog (the
    /// empty-collection state is out of the brief, see BACKLOG); it counts as `.text`,
    /// and the view then shows the bare system "No Results", as before.
    var noResultsCause: NoResultsCause? {
        guard hasNoResults else { return nil }
        let hasSearchedText = !searchedText.isEmpty
        switch (hasSearchedText, searchedWithFilters) {
        case (true, true): return .textAndFilters
        case (false, true): return .filters
        case (_, false): return .text
        }
    }
}

enum NoResultsCause: Equatable {
    case text
    case filters
    case textAndFilters
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
        // shape while loading, after a failure and when nothing matches. The scroll view also
        // gives `.task` a view to attach to.
        ScrollView {
            // Only the grid is covered: fading the scroll view would fade the large title too.
            RecipeGrid(cards: viewModel.viewData.cards, router: router)
                .coveredBy(state: viewModel.viewData.state)
        }
        // Before `.searchable`, so nothing here reaches the search field.
        .stateOverlay(state: viewModel.viewData.state, hidesContent: false) {
            Task { await viewModel.load() }
        }
        .searchable(text: $searchText, prompt: "Search titles and steps")
        // The text comes from the view data, not from the field, so this overlay's
        // position relative to `.searchable` does not matter.
        .overlay {
            if let cause = viewModel.viewData.noResultsCause {
                NoResultsView(
                    cause: cause,
                    searchedText: viewModel.viewData.searchedText,
                    clearFilters: viewModel.clearFilters
                )
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

// MARK: - NoResultsView

/// What a finished search that found nothing says, by cause. The text case is the
/// system's search view; the cases with filters add a Clear Filters button, styled like
/// Try Again in `View+StateOverlay.swift`.
private struct NoResultsView: View {
    let cause: NoResultsCause
    let searchedText: String
    let clearFilters: () -> Void

    var body: some View {
        switch cause {
        case .text:
            if searchedText.isEmpty {
                ContentUnavailableView.search
            } else {
                ContentUnavailableView.search(text: searchedText)
            }
        case .filters:
            view(title: "No Results", description: "No recipes match these filters.")
        case .textAndFilters:
            view(
                title: "No Results for \u{201C}\(searchedText)\u{201D}",
                description: "No recipes match this search with these filters."
            )
        }
    }

    private func view(title: String, description: String) -> some View {
        ContentUnavailableView {
            Label(title, systemImage: "magnifyingglass")
        } description: {
            Text(description)
        } actions: {
            Button("Clear Filters", action: clearFilters)
                .buttonStyle(.bordered)
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
        outcome: PreviewOutcome = .loaded,
        searchText: String = "",
        configure: (RecipeLibraryViewModel) -> Void = { _ in }
    ) -> some View {
        let viewModel = RecipeLibraryViewModel(service: PreviewRecipeListService(previews: previews, outcome: outcome))
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

#Preview("Library, searching roast") {
    // One title match and two step-only matches, in the order the server answers.
    let previews = [
        RecipePreview.previewSamples[4],
        RecipePreview.previewSamples[1],
        RecipePreview(
            id: "sheet-pan-salmon",
            title: "Sheet Pan Salmon",
            summary: "Salmon, potatoes, and greens in one easy pan.",
            servings: 4,
            dietaryAttributes: DietaryAttributes(isVegetarian: false),
            imageURL: PreviewImage.fileURL
        ),
    ]
    return RecipeLibraryView.preview(previews: previews, searchText: "roast") { viewModel in
        viewModel.didChangeSearch("roast")
    }
}

#Preview("Library, no results from text") {
    RecipeLibraryView.preview(previews: [], searchText: "tofu lasagna") { viewModel in
        viewModel.didChangeSearch("tofu lasagna")
    }
}

#Preview("Library, no results from filters only") {
    RecipeLibraryView.preview(previews: []) { viewModel in
        viewModel.filtersViewModel.setVegetarianOnly(true)
        viewModel.filtersViewModel.chooseServings(.count(5))
    }
}

#Preview("Library, no results from text and filters") {
    RecipeLibraryView.preview(previews: [], searchText: "roast") { viewModel in
        viewModel.didChangeSearch("roast")
        viewModel.filtersViewModel.setVegetarianOnly(true)
        viewModel.filtersViewModel.chooseServings(.count(5))
    }
}

#Preview("Library, loading") {
    RecipeLibraryView.preview(outcome: .loading)
}

#Preview("Library, error") {
    RecipeLibraryView.preview(outcome: .failed(.unavailable))
}

#Preview("Library, error with search text") {
    RecipeLibraryView.preview(outcome: .failed(.unavailable), searchText: "ramekins")
}

#Preview("Library, sample recipes, large Dynamic Type") {
    RecipeLibraryView.preview()
        .dynamicTypeSize(.accessibility2)
}

#Preview("Library, searching roast, large Dynamic Type") {
    RecipeLibraryView.preview(
        previews: Array(RecipePreview.previewSamples.prefix(3)),
        searchText: "roast"
    ) { viewModel in
        viewModel.didChangeSearch("roast")
    }
    .dynamicTypeSize(.accessibility2)
}
#endif
