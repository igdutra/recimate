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
            RootView(router: router, libraryViewModel: Self.makeLibraryViewModel())
        }
    }

    static func makeLibraryViewModel() -> RecipeLibraryViewModel {
        let service = RemoteRecipeListService(baseURL: apiBaseURL, client: LocalRecipeAPIClient())
        return RecipeLibraryViewModel(service: service)
    }
}

// MARK: - Preview

// Lives here, not in `Presentation/`, because it builds an `API/` type.
#if DEBUG
#Preview("Root, local client") {
    RootView(router: AppRouter(), libraryViewModel: ReciMateApp.makeLibraryViewModel())
}
#endif
