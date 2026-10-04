import SwiftUI

/// Everything the Library screen shows, replaced as a whole on every change.
struct RecipeLibraryViewData: Equatable {
    let state: ViewState
    let cards: [RecipeCardViewData]
}

struct RecipeLibraryView: View {
    @State private var viewModel: RecipeLibraryViewModel
    @State private var searchText = ""

    init(viewModel: RecipeLibraryViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            // Only the loaded grid is rendered; loading and error states are a later spec.
            // The search field is attached to the loaded content so it hides with it.
            if viewModel.viewData.state.isLoaded {
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.extraLarge) {
                        QuickFilterBar(viewModel: viewModel.quickFilterBar)
                        RecipeGrid(cards: viewModel.viewData.cards)
                    }
                }
                .searchable(text: $searchText, prompt: "Search recipes")
                .onChange(of: searchText) { _, newSearchText in
                    viewModel.didChangeSearch(newSearchText)
                }
                .onSubmit(of: .search) {
                    viewModel.didSubmitSearch()
                }
                .navigationTitle("Recipes")
            }
        }
        .task {
            await viewModel.load()
        }
    }
}

private struct RecipeGrid: View {
    let cards: [RecipeCardViewData]

    private let columns = [
        GridItem(.adaptive(minimum: Sizing.gridColumnMinimum), spacing: Spacing.large, alignment: .top)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: Spacing.large) {
            ForEach(cards) { card in
                RecipeCardView(card: card)
            }
        }
        .padding(.horizontal, Spacing.extraLarge)
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Library, sample recipes") {
    RecipeLibraryView(viewModel: RecipeLibraryViewModel(service: PreviewRecipeListService()))
}

#Preview("Library, sample recipes, large Dynamic Type") {
    RecipeLibraryView(viewModel: RecipeLibraryViewModel(service: PreviewRecipeListService()))
        .dynamicTypeSize(.accessibility2)
}
#endif
