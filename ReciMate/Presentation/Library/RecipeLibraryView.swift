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
private struct RecipeListServiceStub: RecipeListService {
    func loadRecipes() async throws -> [RecipePreview] {
        let photoURL = PreviewImage.fileURL
        return [
            RecipePreview(id: "petit-gateau", title: "Petit Gâteau", summary: "", servings: 4,
                          dietaryAttributes: DietaryAttributes(isVegetarian: true), imageURL: photoURL),
            RecipePreview(id: "lemon-chicken", title: "Lemon Herb Chicken", summary: "", servings: 4,
                          dietaryAttributes: DietaryAttributes(isVegetarian: false), imageURL: photoURL),
            RecipePreview(id: "tomato-pasta", title: "Creamy Tomato Pasta", summary: "", servings: 1,
                          dietaryAttributes: DietaryAttributes(isVegetarian: true), imageURL: photoURL),
            RecipePreview(id: "salmon", title: "Sheet Pan Salmon with Roasted Vegetables and Herbs", summary: "", servings: 4,
                          dietaryAttributes: DietaryAttributes(isVegetarian: false), imageURL: PreviewImage.failingURL),
            RecipePreview(id: "couscous", title: "Roasted Vegetable Couscous", summary: "", servings: 6,
                          dietaryAttributes: DietaryAttributes(isVegetarian: true), imageURL: nil),
        ]
    }
}

#Preview("Library, stub service") {
    RecipeLibraryView(viewModel: RecipeLibraryViewModel(service: RecipeListServiceStub()))
}

#Preview("Library, stub service, large Dynamic Type") {
    RecipeLibraryView(viewModel: RecipeLibraryViewModel(service: RecipeListServiceStub()))
        .dynamicTypeSize(.accessibility2)
}
#endif
