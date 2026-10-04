import SwiftUI

/// Owns the navigation stack and the sheet, and builds the first screen.
struct RootView: View {
    @Bindable private var router: AppRouter
    private let libraryViewModel: RecipeLibraryViewModel
    private let makeDetailsViewModel: (String) -> RecipeDetailsViewModel

    init(
        router: AppRouter,
        libraryViewModel: RecipeLibraryViewModel,
        makeDetailsViewModel: @escaping (String) -> RecipeDetailsViewModel
    ) {
        self.router = router
        self.libraryViewModel = libraryViewModel
        self.makeDetailsViewModel = makeDetailsViewModel
    }

    var body: some View {
        NavigationStack(path: $router.path) {
            RecipeLibraryView(viewModel: libraryViewModel, router: router)
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .details(let recipeID):
                        RecipeDetailsView(viewModel: makeDetailsViewModel(recipeID))
                    }
                }
        }
        .sheet(item: $router.sheet) { sheet in
            switch sheet {
            case .filters:
                FiltersSheetView()
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Root, sample recipes") {
    RootView(
        router: AppRouter(),
        libraryViewModel: RecipeLibraryViewModel(service: PreviewRecipeListService()),
        makeDetailsViewModel: { recipeID in
            RecipeDetailsViewModel(recipeID: recipeID, service: PreviewRecipeDetailsService())
        }
    )
}
#endif
