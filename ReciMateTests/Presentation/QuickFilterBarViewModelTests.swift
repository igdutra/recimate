import Testing
@testable import ReciMate

@MainActor
struct QuickFilterBarViewModelTests {
    @Test func viewData_listsVegetarianServingsInOrder() {
        let viewModel = QuickFilterBarViewModel()

        #expect(viewModel.viewData.chips.map(\.id) == [.vegetarian, .servings])
        #expect(viewModel.viewData.chips.map(\.title) == ["Vegetarian", "Servings"])
    }

    @Test func viewData_showsChevronOnlyOnServings() {
        let viewModel = QuickFilterBarViewModel()

        let chipsWithChevron = viewModel.viewData.chips.filter(\.showsChevron).map(\.id)

        #expect(chipsWithChevron == [.servings])
    }

    @Test func viewData_usesAccentIconOnlyOnVegetarian() {
        let viewModel = QuickFilterBarViewModel()

        let chipsWithAccentIcon = viewModel.viewData.chips.filter(\.usesAccentIcon).map(\.id)

        #expect(chipsWithAccentIcon == [.vegetarian])
    }

    @Test func didTapChip_changesNothing() {
        let viewModel = QuickFilterBarViewModel()
        let viewDataBeforeTap = viewModel.viewData

        viewModel.didTapChip(.servings)

        #expect(viewModel.viewData == viewDataBeforeTap)
    }
}
