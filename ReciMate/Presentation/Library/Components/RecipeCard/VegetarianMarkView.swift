import SwiftUI

/// The leaf shown on vegetarian recipes. Green is only ever an icon color.
struct VegetarianMarkView: View {
    var body: some View {
        Image(systemName: "leaf")
            .font(.system(size: Sizing.icon, weight: .medium))
            .foregroundStyle(Color.accentColor)
            .accessibilityLabel("Vegetarian")
    }
}

// MARK: - Preview

#Preview("Vegetarian mark") {
    VegetarianMarkView()
}
