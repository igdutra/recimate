import SwiftUI

/// System text styles only, no custom scale, so Dynamic Type works.
enum Typography {
    static let screenTitle = Font.largeTitle
    static let searchText = Font.body
    static let chipLabel = Font.subheadline.weight(.medium)
    static let cardTitle = Font.subheadline.weight(.semibold)
    static let cardDetail = Font.footnote
}
