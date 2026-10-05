import SwiftUI

// MARK: - View data

/// What the Details screen shows: where its data is, and the page once loaded.
struct RecipeDetailsViewData: Equatable {
    let state: ViewState
    /// `.placeholder` until loaded, and again after an error; the state overlay covers it.
    let content: RecipeDetailsContentViewData
}

/// The loaded page, already formatted for display.
struct RecipeDetailsContentViewData: Equatable {
    let title: String
    let summary: String
    let servingsLabel: String
    let isVegetarian: Bool
    let imageURL: URL?
    let ingredients: [IngredientRowViewData]
    let steps: [StepRowViewData]

    /// Blank page shown under the loading and error overlay.
    static let placeholder = RecipeDetailsContentViewData(
        title: "",
        summary: "",
        servingsLabel: "",
        isVegetarian: false,
        imageURL: nil,
        ingredients: [],
        steps: []
    )
}

/// One ingredient row. A `nil` quantity shows the name alone.
struct IngredientRowViewData: Identifiable, Equatable {
    let id: String
    let name: String
    let quantity: String?
}

/// One step row. The number is the recipe's own step number, not the array position.
struct StepRowViewData: Identifiable, Equatable {
    let number: Int
    let text: String

    var id: Int { number }
}

// MARK: - RecipeDetailsView

struct RecipeDetailsView: View {
    @State private var viewModel: RecipeDetailsViewModel

    init(viewModel: RecipeDetailsViewModel) {
        _viewModel = State(initialValue: viewModel)
        Self.styleSegmentedControl()
    }

    var body: some View {
        RecipeDetailsPage(content: viewModel.viewData.content)
            .stateOverlay(state: viewModel.viewData.state) {
                Task { await viewModel.load() }
            }
            .task { await viewModel.load() }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
    }
}

private extension RecipeDetailsView {
    /// SwiftUI has no modifier for a segmented `Picker`'s selected fill, so this sets UIKit's
    /// appearance proxy: green fill with white text for the selected segment, mist track,
    /// ink text otherwise. It applies to every segmented control in the app; this is the
    /// only one today. If a second appears, scope it with `whenContainedInInstancesOf`.
    static func styleSegmentedControl() {
        let appearance = UISegmentedControl.appearance()
        appearance.selectedSegmentTintColor = UIColor(Color.accentColor)
        appearance.backgroundColor = UIColor(Color.mist)
        appearance.setTitleTextAttributes([.foregroundColor: UIColor(Color.ink)], for: .normal)
        appearance.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
    }
}

// MARK: - RecipeDetailsPage

/// The loaded page: the photo under the status bar, with the content sheet rising over it.
private struct RecipeDetailsPage: View {
    let content: RecipeDetailsContentViewData

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                RecipeImageView(imageURL: content.imageURL, height: Constants.heroHeight)
                RecipeDetailsSheet(content: content)
                    .padding(.top, -Constants.heroOverlap)
            }
        }
        .ignoresSafeArea(edges: .top)
    }
}

private extension RecipeDetailsPage {
    enum Constants {
        /// Measured from the top of the screen (status bar included).
        static let heroHeight: CGFloat = 280
        /// How far the sheet rises over the hero.
        static let heroOverlap: CGFloat = 28
    }
}

// MARK: - RecipeDetailsSheet

/// The white sheet: badge, title, summary, servings, the segmented control and its list.
private struct RecipeDetailsSheet: View {
    private enum Segment: String, CaseIterable, Identifiable {
        case ingredients = "Ingredients"
        case steps = "Steps"

        var id: Self { self }
    }

    let content: RecipeDetailsContentViewData
    /// Pure UI state, so it lives here and not in the view model.
    @State private var selectedSegment = Segment.ingredients

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if content.isVegetarian {
                VegetarianBadgeView()
                    .padding(.bottom, 12)
            }
            Text(content.title)
                .font(.title.bold())
                .foregroundStyle(Color.ink)
            Text(content.summary)
                .font(.body)
                .foregroundStyle(Color.inkSecondary)
                .padding(.top, 8)
            ServingsLineView(label: content.servingsLabel)
                .padding(.top, 16)
            Picker("Section", selection: $selectedSegment) {
                ForEach(Segment.allCases) { segment in
                    Text(segment.rawValue).tag(segment)
                }
            }
            .pickerStyle(.segmented)
            .padding(.top, 20)
            selectedList
                .padding(.top, selectedSegment == .steps ? 20 : 8)
        }
        .padding(.horizontal, Layout.screenGutter)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: .rect(topLeadingRadius: 28, topTrailingRadius: 28))
    }

    @ViewBuilder
    private var selectedList: some View {
        switch selectedSegment {
        case .ingredients:
            VStack(spacing: 0) {
                ForEach(content.ingredients) { ingredient in
                    IngredientRowView(ingredient: ingredient)
                }
            }
        case .steps:
            VStack(alignment: .leading, spacing: 20) {
                ForEach(content.steps) { step in
                    StepRowView(step: step)
                }
            }
        }
    }
}

// MARK: - VegetarianBadgeView

/// "Vegetarian" in white on green: the badge above the title. The card keeps the icon-only mark.
struct VegetarianBadgeView: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "leaf")
                .font(.system(size: 14, weight: .medium))
                .accessibilityHidden(true)
            Text("Vegetarian")
                .font(.footnote.weight(.semibold))
        }
        .foregroundStyle(Color.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(Color.accentColor, in: .capsule)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - ServingsLineView

/// People icon and the servings label.
struct ServingsLineView: View {
    let label: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "person.2")
                .font(.system(size: 20))
                .foregroundStyle(Color.accentColor)
                .accessibilityHidden(true)
            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.ink)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - IngredientRowView

/// Name on the left, quantity on the right in secondary ink, with a rule underneath.
struct IngredientRowView: View {
    let ingredient: IngredientRowViewData

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            Text(ingredient.name)
                .font(.body)
                .foregroundStyle(Color.ink)
            Spacer(minLength: 0)
            if let quantity = ingredient.quantity {
                Text(quantity)
                    .font(.body)
                    .foregroundStyle(Color.inkSecondary)
                    .multilineTextAlignment(.trailing)
            }
        }
        .frame(minHeight: 52) // A minimum, so Dynamic Type can grow the row
        .overlay(alignment: .bottom) {
            Divider()
                .overlay(Color.separator)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - StepRowView

/// A numbered green circle and the step text.
struct StepRowView: View {
    let step: StepRowViewData

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text("\(step.number)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.white)
                .frame(minWidth: 28, minHeight: 28) // Minimums, so Dynamic Type can grow the circle
                .background(Color.accentColor, in: .circle)
                .accessibilityLabel("Step \(step.number)")
            Text(step.text)
                .font(.body)
                .foregroundStyle(Color.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Vegetarian badge") {
    VegetarianBadgeView()
}

#Preview("Servings line") {
    VStack(alignment: .leading, spacing: 16) {
        ServingsLineView(label: "1 serving")
        ServingsLineView(label: "4 servings")
    }
}

#Preview("Ingredient row") {
    VStack(spacing: 0) {
        IngredientRowView(ingredient: IngredientRowViewData(id: "dark-chocolate", name: "Dark chocolate", quantity: "200 g"))
        IngredientRowView(ingredient: IngredientRowViewData(id: "salt", name: "Salt", quantity: nil))
    }
    .padding(20)
}

#Preview("Step row") {
    VStack(alignment: .leading, spacing: 20) {
        StepRowView(step: StepRowViewData(number: 1, text: "Heat the oven to 220°C."))
        StepRowView(step: StepRowViewData(
            number: 2,
            text: "Fill the ramekins and bake for 8 to 10 minutes, until the edges set and the centers stay soft, then rest briefly."
        ))
    }
    .padding(20)
}

#Preview("Details, loaded") {
    NavigationStack {
        RecipeDetailsView(viewModel: RecipeDetailsViewModel(recipeID: "petit-gateau", service: PreviewRecipeDetailsService()))
    }
}

#Preview("Details, long title and step, not vegetarian") {
    NavigationStack {
        RecipeDetailsView(viewModel: RecipeDetailsViewModel(recipeID: "long", service: PreviewRecipeDetailsService(recipe: .previewSamples[1])))
    }
}

#Preview("Details, no image") {
    NavigationStack {
        RecipeDetailsView(viewModel: RecipeDetailsViewModel(recipeID: "no-image", service: PreviewRecipeDetailsService(recipe: .previewSamples[2])))
    }
}

#Preview("Details, failing image") {
    NavigationStack {
        RecipeDetailsView(viewModel: RecipeDetailsViewModel(recipeID: "failing-image", service: PreviewRecipeDetailsService(recipe: .previewSamples[3])))
    }
}

#Preview("Details, loading") {
    NavigationStack {
        RecipeDetailsView(viewModel: RecipeDetailsViewModel(
            recipeID: "petit-gateau",
            service: PreviewRecipeDetailsService(outcome: .loading)
        ))
    }
}

#Preview("Details, error") {
    NavigationStack {
        RecipeDetailsView(viewModel: RecipeDetailsViewModel(
            recipeID: "beef-tacos",
            service: PreviewRecipeDetailsService(outcome: .failed(.notFound))
        ))
    }
}

#Preview("Details, large Dynamic Type") {
    NavigationStack {
        RecipeDetailsView(viewModel: RecipeDetailsViewModel(recipeID: "petit-gateau", service: PreviewRecipeDetailsService(recipe: .previewSamples[1])))
    }
    .dynamicTypeSize(.accessibility3)
}
#endif
