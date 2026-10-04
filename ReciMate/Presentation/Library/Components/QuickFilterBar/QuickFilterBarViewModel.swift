import Observation

@MainActor
@Observable
final class QuickFilterBarViewModel {
    private(set) var viewData = QuickFilterBarViewData(chips: [
        FilterChipViewData(
            id: .vegetarian,
            title: "Vegetarian",
            symbolName: "leaf",
            showsChevron: false,
            usesAccentIcon: true
        ),
        FilterChipViewData(
            id: .servings,
            title: "Servings",
            symbolName: "person.2",
            showsChevron: true,
            usesAccentIcon: false
        ),
    ])

    func didTapChip(_ chipID: FilterChipViewData.ID) {
        // TODO(milestone D): replace with chip selection state, the servings range
        // all driven by the shared filter state.
        print("Tapped chip: \(chipID)")
    }
}
