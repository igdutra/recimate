import SwiftUI

// MARK: - View data

/// The servings picker's value: any serving count, or exactly one.
enum ServingsChoice: Hashable, Sendable {
    case any
    case count(Int)

    /// The picker offers "Any" and 1 to 8. Assumption: the data holds 2 to 6 and any
    /// upper bound is arbitrary, so a server holding other values would not be reachable.
    static let all: [ServingsChoice] = [.any] + (1...8).map(ServingsChoice.count)
}

/// Everything the Filters sheet shows. Unlike the other screens' view data, it is derived
/// in full from one value, the filters, so it is rebuilt from them on every change: one
/// action can move several fields (a term added to one list leaves the other).
struct FiltersSheetViewData: Equatable {
    let isVegetarianOnly: Bool
    let servingsChoice: ServingsChoice
    let includedTerms: [String]
    let excludedTerms: [String]
    let isResetEnabled: Bool
}

// MARK: - FiltersSheetView

/// The filters of the brief. Changes apply as they happen, so there is no Apply
/// button; Done only closes the sheet.
struct FiltersSheetView: View {
    /// Not `@State`: the Library view model owns it and outlives the sheet.
    private let viewModel: FiltersViewModel
    @State private var includeDraft = ""
    @State private var excludeDraft = ""
    private let router: AppRouter

    init(viewModel: FiltersViewModel, router: AppRouter) {
        self.viewModel = viewModel
        self.router = router
    }

    var body: some View {
        NavigationStack {
            Form {
                dietarySection
                servingsSection
                termsSection(
                    title: "Include ingredients",
                    draft: $includeDraft,
                    terms: viewModel.viewData.includedTerms,
                    submit: viewModel.submitIncludedTerm,
                    remove: viewModel.removeIncludedTerm
                )
                termsSection(
                    title: "Exclude ingredients",
                    draft: $excludeDraft,
                    terms: viewModel.viewData.excludedTerms,
                    submit: viewModel.submitExcludedTerm,
                    remove: viewModel.removeExcludedTerm
                )
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reset", action: viewModel.reset)
                        .disabled(!viewModel.viewData.isResetEnabled)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done", action: router.dismissSheet)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private var dietarySection: some View {
        Section("Dietary") {
            Toggle(
                "Vegetarian only",
                isOn: Binding(
                    get: { viewModel.viewData.isVegetarianOnly },
                    set: { viewModel.setVegetarianOnly($0) }
                )
            )
        }
    }

    private var servingsSection: some View {
        Section("Servings") {
            Picker(
                "Exactly",
                selection: Binding(
                    get: { viewModel.viewData.servingsChoice },
                    set: { viewModel.chooseServings($0) }
                )
            ) {
                ForEach(ServingsChoice.all, id: \.self) { choice in
                    Text(choice.label).tag(choice)
                }
            }
            .pickerStyle(.menu)
        }
    }

    private func termsSection(
        title: String,
        draft: Binding<String>,
        terms: [String],
        submit: @escaping (String) -> Void,
        remove: @escaping (String) -> Void
    ) -> some View {
        Section(title) {
            TextField("Add ingredient", text: draft)
                .submitLabel(.done)
                .autocorrectionDisabled()
                .onSubmit {
                    submit(draft.wrappedValue)
                    draft.wrappedValue = ""
                }
            if !terms.isEmpty {
                WrappingLayout(spacing: 8) {
                    ForEach(terms, id: \.self) { term in
                        TermChipView(term: term) { remove(term) }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}

private extension ServingsChoice {
    var label: String {
        switch self {
        case .any: "Any"
        case .count(let servingCount): String(servingCount)
        }
    }
}

// MARK: - TermChipView

/// An ingredient term with a button to remove it.
private struct TermChipView: View {
    let term: String
    let remove: () -> Void

    var body: some View {
        Button(action: remove) {
            HStack(spacing: 6) {
                Text(term)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.ink)
                    .lineLimit(1)
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.inkSecondary)
            }
            .padding(.vertical, 8)
            .padding(.leading, 12)
            .padding(.trailing, 10)
            .background(Color.mist, in: .capsule)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(term)
        .accessibilityHint("Removes it")
    }
}

// MARK: - WrappingLayout

/// Places its children left to right and starts a new row when one does not fit,
/// so a few long terms wrap instead of running off the sheet. `SwiftUI.Layout` is
/// spelled out because the project has its own `Layout` enum.
private struct WrappingLayout: SwiftUI.Layout {
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = makeRows(maxWidth: proposal.width ?? .infinity, subviews: subviews)
        let height = rows.map(\.height).reduce(0, +) + spacing * CGFloat(max(rows.count - 1, 0))
        let width = rows.map(\.width).max() ?? 0
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var originY = bounds.minY
        for row in makeRows(maxWidth: bounds.width, subviews: subviews) {
            var originX = bounds.minX
            for item in row.items {
                subviews[item.index].place(
                    at: CGPoint(x: originX, y: originY),
                    proposal: ProposedViewSize(item.size)
                )
                originX += item.size.width + spacing
            }
            originY += row.height + spacing
        }
    }

    private struct Row {
        var items: [(index: Int, size: CGSize)] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func makeRows(maxWidth: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = [Row()]
        for index in subviews.indices {
            // A chip wider than the row is squeezed to the row, never wider than it.
            let idealSize = subviews[index].sizeThatFits(.unspecified)
            let size = CGSize(width: min(idealSize.width, maxWidth), height: idealSize.height)
            let widthWithChip = rows[rows.count - 1].width + (rows[rows.count - 1].items.isEmpty ? 0 : spacing) + size.width
            if widthWithChip > maxWidth, !rows[rows.count - 1].items.isEmpty {
                rows.append(Row())
            }
            let rowIndex = rows.count - 1
            rows[rowIndex].width += (rows[rowIndex].items.isEmpty ? 0 : spacing) + size.width
            rows[rowIndex].height = max(rows[rowIndex].height, size.height)
            rows[rowIndex].items.append((index, size))
        }
        return rows
    }
}

// MARK: - Preview

#if DEBUG
@MainActor
private func makeSheet(filters: RecipeSearchQuery = .empty) -> some View {
    FiltersSheetView(viewModel: FiltersViewModel(filters: filters), router: AppRouter())
}

#Preview("Filters, default") {
    makeSheet()
}

#Preview("Filters, choices on") {
    makeSheet(filters: RecipeSearchQuery(
        onlyVegetarian: true,
        servings: 2,
        includedIngredients: ["cream"],
        excludedIngredients: ["mushrooms"]
    ))
}

#Preview("Filters, many long terms") {
    makeSheet(filters: RecipeSearchQuery(
        includedIngredients: ["extra virgin olive oil", "sun-dried tomatoes", "fresh basil leaves", "parmigiano reggiano", "balsamic vinegar of Modena", "pine nuts"],
        excludedIngredients: ["unsalted butter", "double cream", "a very long ingredient name that cannot fit on one row of the sheet at all", "eggs"]
    ))
}

#Preview("Filters, large Dynamic Type") {
    makeSheet(filters: RecipeSearchQuery(
        onlyVegetarian: true,
        servings: 4,
        includedIngredients: ["cream", "tomato"],
        excludedIngredients: ["mushrooms"]
    ))
    .dynamicTypeSize(.accessibility2)
}
#endif
