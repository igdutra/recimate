//
//  ReciMateApp.swift
//  ReciMate
//
//  Created by Ivo on 03/10/26.
//

import SwiftUI

/// Compositon Root:  The only place an `API/` type is built; `Presentation/` sees `Domain` only.
/// It builds the services and forwards them; each view model is created by the view that owns it.
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
                listService: Self.makeListService(),
                detailsService: Self.makeDetailsService()
            )
        }
    }

    static func makeListService() -> any RecipeListService {
        RemoteRecipeListService(baseURL: apiBaseURL, client: LocalRecipeAPIClient())
    }

    static func makeDetailsService() -> any RecipeDetailsService {
        RemoteRecipeDetailsService(baseURL: apiBaseURL, client: LocalRecipeAPIClient())
    }
}

// MARK: - Preview

// Lives here, not in `Presentation/`, because it builds an `API/` type.
#if DEBUG
#Preview("Root, local client") {
    RootView(
        router: AppRouter(),
        listService: ReciMateApp.makeListService(),
        detailsService: ReciMateApp.makeDetailsService()
    )
}

#Preview("Details, local client") {
    NavigationStack {
        RecipeDetailsView(recipeID: "petit-gateau", service: ReciMateApp.makeDetailsService())
    }
}
#endif
