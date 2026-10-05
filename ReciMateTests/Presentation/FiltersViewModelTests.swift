import Testing
@testable import ReciMate

@MainActor
struct FiltersViewModelTests {
    // MARK: - Initial state

    @Test func init_startsWithNothingChosenAndResetDisabled() {
        let (sut, recorder) = makeSUT()

        #expect(sut.viewData == FiltersSheetViewData(
            isVegetarianOnly: false,
            servingsChoice: .any,
            includedTerms: [],
            excludedTerms: [],
            isResetEnabled: false
        ))
        #expect(recorder.reportedFilters.isEmpty)
    }

    @Test func servingsChoices_areAnyAndOneToEight() {
        #expect(ServingsChoice.all == [.any] + (1...8).map(ServingsChoice.count))
    }

    // MARK: - Each action updates the view data and reports once

    @Test func setVegetarianOnly_updatesViewDataAndReportsOnce() {
        let (sut, recorder) = makeSUT()

        sut.setVegetarianOnly(true)

        #expect(sut.viewData.isVegetarianOnly)
        #expect(sut.viewData.isResetEnabled)
        #expect(recorder.reportedFilters == [RecipeSearchQuery(onlyVegetarian: true)])
    }

    @Test func chooseServings_updatesViewDataAndReportsOnce() {
        let (sut, recorder) = makeSUT()

        sut.chooseServings(.count(4))

        #expect(sut.viewData.servingsChoice == .count(4))
        #expect(recorder.reportedFilters == [RecipeSearchQuery(servings: 4)])
    }

    @Test func chooseServings_any_clearsTheChoice() {
        let (sut, recorder) = makeSUT()
        sut.chooseServings(.count(4))

        sut.chooseServings(.any)

        #expect(sut.viewData.servingsChoice == .any)
        #expect(!sut.viewData.isResetEnabled)
        #expect(recorder.reportedFilters.last == .empty)
        #expect(recorder.reportedFilters.count == 2)
    }

    @Test func submitIncludedTerm_addsTheTermAndReportsOnce() {
        let (sut, recorder) = makeSUT()

        sut.submitIncludedTerm(" cream ")

        #expect(sut.viewData.includedTerms == ["cream"])
        #expect(recorder.reportedFilters == [RecipeSearchQuery(includedIngredients: ["cream"])])
    }

    @Test func submitExcludedTerm_addsTheTermAndReportsOnce() {
        let (sut, recorder) = makeSUT()

        sut.submitExcludedTerm("mushrooms")

        #expect(sut.viewData.excludedTerms == ["mushrooms"])
        #expect(recorder.reportedFilters == [RecipeSearchQuery(excludedIngredients: ["mushrooms"])])
    }

    @Test func removeTerms_removeThemAndReportOncePerRemoval() {
        let (sut, recorder) = makeSUT()
        sut.submitIncludedTerm("eggs")
        sut.submitExcludedTerm("nuts")
        recorder.reportedFilters.removeAll()

        sut.removeIncludedTerm("eggs")
        sut.removeExcludedTerm("nuts")

        #expect(sut.viewData.includedTerms.isEmpty)
        #expect(sut.viewData.excludedTerms.isEmpty)
        #expect(recorder.reportedFilters.count == 2)
    }

    // MARK: - Rules

    @Test func submitIncludedTerm_movesTheTermOutOfExcludedWithOneReport() {
        let (sut, recorder) = makeSUT()
        sut.submitExcludedTerm("nuts")
        recorder.reportedFilters.removeAll()

        sut.submitIncludedTerm("Nuts")

        #expect(sut.viewData.includedTerms == ["Nuts"])
        #expect(sut.viewData.excludedTerms.isEmpty)
        #expect(recorder.reportedFilters.count == 1)
    }

    @Test func submitExcludedTerm_movesTheTermOutOfIncludedWithOneReport() {
        let (sut, recorder) = makeSUT()
        sut.submitIncludedTerm("nuts")
        recorder.reportedFilters.removeAll()

        sut.submitExcludedTerm("nuts")

        #expect(sut.viewData.excludedTerms == ["nuts"])
        #expect(sut.viewData.includedTerms.isEmpty)
        #expect(recorder.reportedFilters.count == 1)
    }

    @Test(arguments: ["", "   ", "cream", "CRÈAM"])
    func submitIncludedTerm_blankOrRepeatedChangesNothingAndReportsNothing(term: String) {
        let (sut, recorder) = makeSUT()
        sut.submitIncludedTerm("cream")
        recorder.reportedFilters.removeAll()

        sut.submitIncludedTerm(term)

        #expect(sut.viewData.includedTerms == ["cream"])
        #expect(recorder.reportedFilters.isEmpty)
    }

    @Test func setVegetarianOnly_toTheSameValueReportsNothing() {
        let (sut, recorder) = makeSUT()

        sut.setVegetarianOnly(false)

        #expect(recorder.reportedFilters.isEmpty)
    }

    // MARK: - Reset

    @Test func reset_clearsEveryFilterAndDisablesItself() {
        let (sut, recorder) = makeSUT()
        sut.setVegetarianOnly(true)
        sut.chooseServings(.count(2))
        sut.submitIncludedTerm("cream")
        sut.submitExcludedTerm("mushrooms")
        #expect(sut.viewData.isResetEnabled)
        recorder.reportedFilters.removeAll()

        sut.reset()

        #expect(sut.viewData == FiltersSheetViewData(
            isVegetarianOnly: false,
            servingsChoice: .any,
            includedTerms: [],
            excludedTerms: [],
            isResetEnabled: false
        ))
        #expect(recorder.reportedFilters == [.empty])
    }

    @Test func reset_whenNothingIsSet_reportsNothing() {
        let (sut, recorder) = makeSUT()

        sut.reset()

        #expect(recorder.reportedFilters.isEmpty)
    }

    // MARK: - Initial filters

    @Test func init_withFilters_showsThem() {
        let filters = RecipeSearchQuery(onlyVegetarian: true, servings: 3, includedIngredients: ["eggs"])
        let (sut, _) = makeSUT(filters: filters)

        #expect(sut.viewData.isVegetarianOnly)
        #expect(sut.viewData.servingsChoice == .count(3))
        #expect(sut.viewData.includedTerms == ["eggs"])
        #expect(sut.viewData.isResetEnabled)
    }
}

// MARK: - Helpers

@MainActor
private final class ChangeRecorder {
    var reportedFilters: [RecipeSearchQuery] = []
}

private extension FiltersViewModelTests {
    func makeSUT(filters: RecipeSearchQuery = .empty) -> (sut: FiltersViewModel, recorder: ChangeRecorder) {
        let recorder = ChangeRecorder()
        let sut = FiltersViewModel(filters: filters)
        sut.onChange = { reportedFilters in recorder.reportedFilters.append(reportedFilters) }
        return (sut, recorder)
    }
}
