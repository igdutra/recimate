import SwiftUI

/// System text styles only, no custom scale, so Dynamic Type works.
enum Typography {
    static let screenTitle = Font.largeTitle
    static let searchText = Font.body
    static let chipLabel = Font.subheadline.weight(.medium)
    static let cardTitle = Font.subheadline.weight(.semibold)
    static let cardDetail = Font.footnote
    /// Recipe title on the details screen.
    static let detailsTitle = Font.title.bold()
    /// Section titles, single scroll layout only.
    static let sectionTitle = Font.title2.bold()
    /// Summary, ingredient name and quantity, step text.
    static let detailsBody = Font.body
    static let servings = Font.subheadline.weight(.medium)
    static let badgeLabel = Font.footnote.weight(.semibold)
    static let stepNumber = Font.subheadline.weight(.semibold)
}
