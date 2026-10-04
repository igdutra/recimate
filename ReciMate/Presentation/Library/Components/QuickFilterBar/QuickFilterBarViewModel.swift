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
        FilterChipViewData(
            id: .filters,
            title: "Filters",
            symbolName: "slider.horizontal.3",
            showsChevron: false,
            usesAccentIcon: false
        ),
    ])

    func didTapChip(_ chipID: FilterChipViewData.ID) {
        // TODO(milestone D): replace with chip selection state, the servings range
        // and the Filters sheet, all driven by the shared filter state.
        print("Tapped chip: \(chipID)")
    }
}
