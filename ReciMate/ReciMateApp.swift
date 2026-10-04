//
//  ReciMateApp.swift
//  ReciMate
//
//  Created by Ivo on 03/10/26.
//

import SwiftUI

/// Compositon Root:  The only place an `API/` type is built; `Presentation/` sees `Domain` only.
@main
struct ReciMateApp: App {
    /// Placeholder. `LocalRecipeAPIClient` ignores scheme and host, so this is
    /// unused until a real client replaces it.
    static let apiBaseURL = URL(string: "https://api.recimate.example")!

    @State private var router = AppRouter()

    var body: some Scene {
        WindowGroup {
            RootView(
                router: router,
                libraryViewModel: Self.makeLibraryViewModel(),
                makeDetailsViewModel: Self.makeDetailsViewModel
            )
        }
    }

    static func makeLibraryViewModel() -> RecipeLibraryViewModel {
        let service = RemoteRecipeListService(baseURL: apiBaseURL, client: LocalRecipeAPIClient())
        return RecipeLibraryViewModel(service: service)
    }

    static func makeDetailsViewModel(recipeID: String) -> RecipeDetailsViewModel {
        let service = RemoteRecipeDetailsService(baseURL: apiBaseURL, client: LocalRecipeAPIClient())
        return RecipeDetailsViewModel(recipeID: recipeID, service: service)
    }
}

// MARK: - Preview

// Lives here, not in `Presentation/`, because it builds an `API/` type.
#if DEBUG
#Preview("Root, local client") {
    RootView(
        router: AppRouter(),
        libraryViewModel: ReciMateApp.makeLibraryViewModel(),
        makeDetailsViewModel: ReciMateApp.makeDetailsViewModel
    )
}

#Preview("Details, local client") {
    NavigationStack {
        RecipeDetailsView(viewModel: ReciMateApp.makeDetailsViewModel(recipeID: "petit-gateau"))
    }
}
#endif
