import SwiftUI

/// Colors from the design. `AccentColor`, `Ink` and `Mist` live in the asset
/// catalog and are used through Xcode's generated symbols (`Color.ink`,
/// `Color.mist`, `.accentColor`). Only the derived ones (ink at a fixed
/// opacity) are declared here. White is the system background.
extension Color {
    /// Secondary text (servings) and icons on the placeholder tile.
    static let inkSecondary = Color.ink.opacity(0.66)
    /// The no-image placeholder tile.
    static let placeholderFill = Color.ink.opacity(0.08)
    /// Ingredient row dividers, and (single scroll layout only) the rule under servings.
    static let separator = Color.ink.opacity(0.12)
}
