//
//  ReciMateApp.swift
//  ReciMate
//
//  Created by Ivo on 03/10/26.
//

import SwiftUI

@main
struct ReciMateApp: App {
    /// Placeholder. `LocalRecipeAPIClient` ignores scheme and host, so this is
    /// unused until a real client replaces it.
    static let apiBaseURL = URL(string: "https://api.recimate.example")!

    var body: some Scene {
        WindowGroup {
            RecipeLibraryView(viewModel: Self.makeLibraryViewModel())
        }
    }

    /// The only place an `API/` type is built; `Presentation/` sees `Domain` only.
    static func makeLibraryViewModel() -> RecipeLibraryViewModel {
        let service = RemoteRecipeListService(baseURL: apiBaseURL, client: LocalRecipeAPIClient())
        return RecipeLibraryViewModel(service: service)
    }
}

// MARK: - Preview

// MARK: - Preview

// Lives here, not in `Presentation/`, because it builds an `API/` type.
#Preview("Library, local client") {
    RecipeLibraryView(viewModel: ReciMateApp.makeLibraryViewModel())
}
