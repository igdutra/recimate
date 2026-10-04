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
}
