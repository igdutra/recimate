import SwiftUI

/// Owns the navigation stack and the sheet, and builds the first screen.
struct RootView: View {
    @Bindable private var router: AppRouter
    private let libraryViewModel: RecipeLibraryViewModel

    init(router: AppRouter, libraryViewModel: RecipeLibraryViewModel) {
        self.router = router
        self.libraryViewModel = libraryViewModel
    }

    var body: some View {
        NavigationStack(path: $router.path) {
            RecipeLibraryView(viewModel: libraryViewModel, router: router)
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .details(let recipeID):
                        RecipeDetailsView(recipeID: recipeID)
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
        libraryViewModel: RecipeLibraryViewModel(service: PreviewRecipeListService())
    )
}
#endif
