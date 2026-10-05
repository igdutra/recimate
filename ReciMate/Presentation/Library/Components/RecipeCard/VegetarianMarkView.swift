import SwiftUI

// MARK: - VegetarianMarkView

/// The leaf shown on vegetarian recipes. Green is only ever an icon color.
struct VegetarianMarkView: View {
    /// Also the card's detail row height, so cards match with or without the leaf.
    static let iconSize: CGFloat = 18

    var body: some View {
        Image(systemName: "leaf")
            .font(.system(size: Self.iconSize, weight: .medium))
            .foregroundStyle(Color.accentColor)
            .accessibilityLabel("Vegetarian")
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Vegetarian mark") {
    VegetarianMarkView()
}
#endif
