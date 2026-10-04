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
    /// unused until a real client replaces it. No service is wired to a view yet (003).
    static let apiBaseURL = URL(string: "https://api.recimate.example")!

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
