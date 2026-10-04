import CoreGraphics

enum Sizing {
    /// Chip height.
    static let touchTarget: CGFloat = 44
    static let cardPhotoHeight: CGFloat = 140
    /// Smallest grid column; a 390pt screen fits two.
    static let gridColumnMinimum: CGFloat = 160
    /// Chip icons, vegetarian leaf.
    static let icon: CGFloat = 18
    /// Servings chip chevron.
    static let iconSmall: CGFloat = 14
    /// No-image tile icon.
    static let iconPlaceholder: CGFloat = 36
    /// Servings people icon.
    static let iconMedium: CGFloat = 20
    /// How far the details body rises over the hero.
    static let heroOverlap: CGFloat = 28
    /// Details hero, measured from the top of the screen (status bar included).
    static let heroHeight: CGFloat = 280
    /// Single scroll layout only.
    static let heroHeightSingleScroll: CGFloat = 320
    /// Minimum heights, so Dynamic Type can grow the row.
    static let ingredientRowMinimumHeight: CGFloat = 52
    /// Single scroll layout only.
    static let ingredientRowMinimumHeightSingleScroll: CGFloat = 48
    /// Step number circle diameter.
    static let stepNumber: CGFloat = 28
}
