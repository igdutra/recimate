import SwiftUI

/// Owns the navigation stack and the sheet, and builds the first screen.
struct RootView: View {
    @Bindable private var router: AppRouter
    /// Created here, not in `RecipeLibraryView`: the grid and the Filters sheet must share
    /// one instance, and this is the lowest view that holds both.
    @State private var libraryViewModel: RecipeLibraryViewModel
    /// Forwarded to each Details screen, which creates its own view model with it.
    private let detailsService: any RecipeDetailsService

    init(
        router: AppRouter,
        listService: any RecipeListService,
        detailsService: any RecipeDetailsService
    ) {
        self.router = router
        _libraryViewModel = State(initialValue: RecipeLibraryViewModel(service: listService))
        self.detailsService = detailsService
    }

    var body: some View {
        NavigationStack(path: $router.path) {
            RecipeLibraryView(viewModel: libraryViewModel, router: router)
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .details(let recipeID):
                        RecipeDetailsView(recipeID: recipeID, service: detailsService)
                    }
                }
        }
        .sheet(item: $router.sheet) { sheet in
            switch sheet {
            case .filters:
                FiltersSheetView(viewModel: libraryViewModel.filtersViewModel, router: router)
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Root, sample recipes") {
    RootView(
        router: AppRouter(),
        listService: PreviewRecipeListService(),
        detailsService: PreviewRecipeDetailsService()
    )
}
#endif
