import Foundation
import Testing
@testable import ReciMate

@Suite(.hangGuard)
@MainActor
struct RecipeLibraryViewModelTests {
    // MARK: - Initial state

    @Test func init_startsLoadingWithNoCards() {
        let (sut, _) = makeSUT()

        #expect(sut.viewData == RecipeLibraryViewData(
            state: .loading, cards: [], activeFilterCount: 0, searchedText: "", searchedWithFilters: false
        ))
    }

    // MARK: - Happy path

    @Test func load_onSuccess_deliversCardsInRecipeOrder() async {
        let previews: [RecipePreview] = [.petitGateau, .lemonHerbChicken, .roastedVegetableCouscous]
        let (sut, spy) = makeSUT()

        await load(sut, on: spy, completingWith: previews)

        #expect(sut.viewData.state == .loaded)
        #expect(sut.viewData.cards == previews.map { RecipeLibraryViewModel.makeCard(from: $0) })
        #expect(sut.viewData.cards.map(\.id) == ["petit-gateau", "lemon-herb-chicken", "roasted-vegetable-couscous"])
    }

    @Test func load_onSuccess_staysLoadingUntilServiceReturnsThenLoaded() async {
        let (sut, spy) = makeSUT()
        #expect(sut.viewData.state == .loading)

        let loadTask = await startLoad(of: sut, on: spy)
        #expect(sut.viewData.state == .loading)

        await spy.complete(with: [.petitGateau])
        await loadTask.value
        #expect(sut.viewData.state == .loaded)
    }

    @Test func load_onEmptyList_isLoadedWithNoCards() async {
        let (sut, spy) = makeSUT()

        await load(sut, on: spy, completingWith: [])

        #expect(sut.viewData == RecipeLibraryViewData(
            state: .loaded, cards: [], activeFilterCount: 0, searchedText: "", searchedWithFilters: false
        ))
    }

    // MARK: - Failure modes

    @Test(arguments: [
        RecipeError.notFound,
        .invalidData(reason: "missing key"),
        .unavailable,
    ])
    func load_onRecipeError_staysLoadingUntilServiceThrowsThenError(recipeError: RecipeError) async {
        let (sut, spy) = makeSUT()

        let loadTask = await startLoad(of: sut, on: spy)
        #expect(sut.viewData.state == .loading)

        await spy.fail(with: recipeError)
        await loadTask.value
        #expect(sut.viewData.state == .error(recipeError))
        #expect(sut.viewData.cards.isEmpty)
    }

    @Test func load_onNonRecipeError_movesToUnavailable() async {
        struct UnrelatedError: Error {}
        let (sut, spy) = makeSUT()

        await load(sut, on: spy, failingWith: UnrelatedError())

        #expect(sut.viewData.state == .error(.unavailable))
    }

    // MARK: - Repeated loads

    @Test func load_whenAlreadyLoaded_doesNotCallServiceAgain() async {
        let (sut, spy) = makeSUT()
        await load(sut, on: spy, completingWith: [.petitGateau])

        await sut.load()

        #expect(spy.requestCount == 1)
    }

    @Test func load_whileLoading_doesNotCallServiceAgain() async {
        let (sut, spy) = makeSUT()
        let firstLoadTask = await startLoad(of: sut, on: spy)

        let secondLoadTask = Task { await sut.load() }
        await Task.yield()
        // Asserted before anything is awaited: without the guard a second request
        // would wait for the spy forever.
        #expect(spy.requestCount == 1)

        await spy.complete(with: [.petitGateau])
        await spy.failPendingRequests()
        await firstLoadTask.value
        await secondLoadTask.value
        #expect(sut.viewData.state == .loaded)
    }

    @Test func load_afterError_callsServiceAgain() async {
        let (sut, spy) = makeSUT()
        await load(sut, on: spy, failingWith: RecipeError.unavailable)
        #expect(sut.viewData.state == .error(.unavailable))

        let retryLoadTask = await startLoad(of: sut, on: spy, expectedRequestCount: 2)
        await spy.complete(with: [.petitGateau], at: 1)
        await retryLoadTask.value

        #expect(spy.requestCount == 2)
        #expect(sut.viewData.state == .loaded)
    }

    // MARK: - Search queries

    @Test func load_searchesWithTheEmptyQuery() async {
        let (sut, spy) = makeSUT()

        await load(sut, on: spy, completingWith: [.petitGateau])

        #expect(spy.requestedQueries == [.empty])
    }

    @Test func didChangeSearch_searchesWithTheTypedText() async {
        let (sut, spy) = makeSUT()
        await load(sut, on: spy, completingWith: [.petitGateau])

        sut.didChangeSearch("ramekins")
        await spy.waitUntilRequested(count: 2)

        #expect(spy.requestedQueries.last == RecipeSearchQuery(searchText: "ramekins"))
        await finishSearch(on: spy, at: 1, with: [.petitGateau])
    }

    @Test func didChangeSearch_withTheSameText_doesNotSearchAgain() async {
        let (sut, spy) = makeSUT()
        await load(sut, on: spy, completingWith: [.petitGateau])
        sut.didChangeSearch("ramekins")
        await spy.waitUntilRequested(count: 2)
        await finishSearch(on: spy, at: 1, with: [.petitGateau])

        sut.didChangeSearch("ramekins")
        await Task.yield()

        #expect(spy.requestCount == 2)
    }

    @Test func clearingTheText_searchesWithTheEmptyQueryAgain() async {
        let (sut, spy) = makeSUT()
        await load(sut, on: spy, completingWith: [.petitGateau, .lemonHerbChicken])
        sut.didChangeSearch("ramekins")
        await spy.waitUntilRequested(count: 2)
        await finishSearch(on: spy, at: 1, with: [.petitGateau])

        sut.didChangeSearch("")
        await spy.waitUntilRequested(count: 3)
        await finishSearch(on: spy, at: 2, with: [.petitGateau, .lemonHerbChicken])

        #expect(spy.requestedQueries.last == .empty)
        #expect(sut.viewData.cards.count == 2)
    }

    @Test func filterChange_searchesWithTheFiltersAndKeepsTheText() async {
        let (sut, spy) = makeSUT()
        await load(sut, on: spy, completingWith: [.petitGateau])
        sut.didChangeSearch("bake")
        await spy.waitUntilRequested(count: 2)
        await finishSearch(on: spy, at: 1, with: [.petitGateau])

        sut.filtersViewModel.setVegetarianOnly(true)
        await spy.waitUntilRequested(count: 3)
        await finishSearch(on: spy, at: 2, with: [.petitGateau])

        #expect(spy.requestedQueries.last == RecipeSearchQuery(searchText: "bake", onlyVegetarian: true))
    }

    @Test func typingAfterAFilterChange_keepsTheFilters() async {
        let (sut, spy) = makeSUT()
        await load(sut, on: spy, completingWith: [.petitGateau])
        sut.filtersViewModel.chooseServings(.count(4))
        sut.filtersViewModel.submitIncludedTerm("eggs")
        // The first filter's search is cancelled before it reaches the service.
        await spy.waitUntilRequested(count: 2)

        sut.didChangeSearch("bake")
        await spy.waitUntilRequested(count: 3)

        #expect(spy.requestedQueries.last == RecipeSearchQuery(
            searchText: "bake", servings: 4, includedIngredients: ["eggs"]
        ))
        await spy.failPendingRequests()
    }

    @Test func filtersReset_searchesWithoutFiltersAndKeepsTheText() async {
        let (sut, spy) = makeSUT()
        await load(sut, on: spy, completingWith: [.petitGateau])
        sut.didChangeSearch("bake")
        await spy.waitUntilRequested(count: 2)
        sut.filtersViewModel.setVegetarianOnly(true)
        await spy.waitUntilRequested(count: 3)

        sut.filtersViewModel.reset()
        await spy.waitUntilRequested(count: 4)

        #expect(spy.requestedQueries.last == RecipeSearchQuery(searchText: "bake"))
        await spy.failPendingRequests()
    }

    // MARK: - Debounce and trimming

    @Test func typing_threeKeystrokesInARow_reachTheServiceOnceWithTheLastText() async {
        let (sut, spy) = makeSUT(searchDebounce: .milliseconds(50))
        await load(sut, on: spy, completingWith: [.petitGateau])

        sut.didChangeSearch("r")
        sut.didChangeSearch("ra")
        sut.didChangeSearch("ram")
        await spy.waitUntilRequested(count: 2)
        await settle()

        #expect(spy.requestedQueries == [.empty, RecipeSearchQuery(searchText: "ram")])
        await spy.failPendingRequests()
    }

    @Test func typing_withALongDebounce_requestsNothingYet() async {
        let (sut, spy) = makeSUT(searchDebounce: .seconds(1))
        await load(sut, on: spy, completingWith: [.petitGateau])

        sut.didChangeSearch("ramekins")
        await settle()

        #expect(spy.requestCount == 1)
    }

    @Test func didChangeSearch_withTextThatDiffersOnlyBySpaces_doesNotSearchAgain() async {
        let (sut, spy) = makeSUT()
        await load(sut, on: spy, completingWith: [.petitGateau])
        sut.didChangeSearch("ramekins")
        await spy.waitUntilRequested(count: 2)
        await finishSearch(on: spy, at: 1, with: [.petitGateau])

        sut.didChangeSearch("ramekins ")
        sut.didChangeSearch("  ramekins")
        await settle()

        #expect(spy.requestCount == 2)
    }

    @Test func filterChange_isNotDebounced() async {
        let (sut, spy) = makeSUT(searchDebounce: .seconds(60))
        await load(sut, on: spy, completingWith: [.petitGateau])

        sut.filtersViewModel.setVegetarianOnly(true)
        await spy.waitUntilRequested(count: 2)

        #expect(spy.requestedQueries.last == RecipeSearchQuery(onlyVegetarian: true))
        await spy.failPendingRequests()
    }

    // MARK: - Overlapping searches

    @Test func overlappingSearches_showTheLatestWhateverTheReplyOrder() async {
        let (sut, spy) = makeSUT()
        await load(sut, on: spy, completingWith: [.petitGateau])
        sut.didChangeSearch("r")
        await spy.waitUntilRequested(count: 2)
        sut.didChangeSearch("ra")
        await spy.waitUntilRequested(count: 3)

        await spy.complete(with: [.lemonHerbChicken], at: 2)
        await spy.complete(with: [.petitGateau], at: 1)
        await settle()

        #expect(sut.viewData.cards.map(\.id) == ["lemon-herb-chicken"])
        #expect(sut.viewData.state == .loaded)
    }

    @Test func outdatedSearchFailure_isNotAnError() async {
        let (sut, spy) = makeSUT()
        await load(sut, on: spy, completingWith: [.petitGateau])
        sut.didChangeSearch("r")
        await spy.waitUntilRequested(count: 2)
        sut.didChangeSearch("ra")
        await spy.waitUntilRequested(count: 3)

        await spy.fail(with: RecipeError.unavailable, at: 1)
        await settle()
        #expect(sut.viewData.state == .loaded)

        await spy.complete(with: [.lemonHerbChicken], at: 2)
        await settle()
        #expect(sut.viewData.state == .loaded)
        #expect(sut.viewData.cards.map(\.id) == ["lemon-herb-chicken"])
    }

    @Test func cancelledSearchFailure_isNotAnError() async {
        let (sut, spy) = makeSUT()
        await load(sut, on: spy, completingWith: [.petitGateau])
        sut.didChangeSearch("r")
        await spy.waitUntilRequested(count: 2)

        await spy.fail(with: CancellationError(), at: 1)
        await settle()

        #expect(sut.viewData.state == .loaded)
        #expect(sut.viewData.cards.map(\.id) == ["petit-gateau"])
    }

    // MARK: - State during a new search

    @Test func newSearch_keepsLoadedStateAndOldCardsUntilTheResultArrives() async {
        let (sut, spy) = makeSUT()
        await load(sut, on: spy, completingWith: [.petitGateau, .lemonHerbChicken])

        sut.didChangeSearch("ramekins")
        await spy.waitUntilRequested(count: 2)

        #expect(sut.viewData.state == .loaded)
        #expect(sut.viewData.cards.map(\.id) == ["petit-gateau", "lemon-herb-chicken"])

        await finishSearch(on: spy, at: 1, with: [.petitGateau])
        #expect(sut.viewData.cards.map(\.id) == ["petit-gateau"])
    }

    @Test func emptyResult_setsHasNoResults() async {
        let (sut, spy) = makeSUT()
        await load(sut, on: spy, completingWith: [.petitGateau])
        #expect(!sut.viewData.hasNoResults)

        sut.didChangeSearch("tofu lasagna")
        await spy.waitUntilRequested(count: 2)
        await finishSearch(on: spy, at: 1, with: [])

        #expect(sut.viewData.hasNoResults)
    }

    @Test func hasNoResults_isFalseWhileLoadingAndAfterAnError() async {
        let (sut, spy) = makeSUT()
        #expect(!sut.viewData.hasNoResults)

        await load(sut, on: spy, failingWith: RecipeError.unavailable)

        #expect(!sut.viewData.hasNoResults)
    }

    @Test func searchFailure_setsErrorAndANextSuccessfulSearchClearsIt() async {
        let (sut, spy) = makeSUT()
        await load(sut, on: spy, completingWith: [.petitGateau])

        sut.didChangeSearch("r")
        await spy.waitUntilRequested(count: 2)
        await spy.fail(with: RecipeError.notFound, at: 1)
        await settle()
        #expect(sut.viewData.state == .error(.notFound))

        sut.didChangeSearch("ra")
        await spy.waitUntilRequested(count: 3)
        await finishSearch(on: spy, at: 2, with: [.lemonHerbChicken])

        #expect(sut.viewData.state == .loaded)
        #expect(sut.viewData.cards.map(\.id) == ["lemon-herb-chicken"])
    }

    // MARK: - Active filter count

    @Test func activeFilterCount_followsTheFiltersNotTheText() async {
        let (sut, spy) = makeSUT()
        await load(sut, on: spy, completingWith: [.petitGateau])

        sut.didChangeSearch("bake")
        #expect(sut.viewData.activeFilterCount == 0)

        sut.filtersViewModel.setVegetarianOnly(true)
        sut.filtersViewModel.chooseServings(.count(2))
        sut.filtersViewModel.submitIncludedTerm("cream")
        #expect(sut.viewData.activeFilterCount == 3)

        sut.filtersViewModel.reset()
        #expect(sut.viewData.activeFilterCount == 0)
        await spy.failPendingRequests()
    }

    // MARK: - Card mapping

    @Test(arguments: [(1, "1 serving"), (2, "2 servings"), (5, "5 servings")])
    func makeCard_formatsServingsLabel(servingCount: Int, expectedLabel: String) {
        let card = RecipeLibraryViewModel.makeCard(from: .fixture(servings: servingCount))

        #expect(card.servingsLabel == expectedLabel)
    }

    @Test(arguments: [true, false])
    func makeCard_carriesVegetarianFlag(isVegetarian: Bool) {
        let card = RecipeLibraryViewModel.makeCard(from: .fixture(isVegetarian: isVegetarian))

        #expect(card.isVegetarian == isVegetarian)
    }

    @Test func makeCard_passesImageURLThrough() {
        let card = RecipeLibraryViewModel.makeCard(from: .lemonHerbChicken)

        #expect(card.imageURL == RecipePreview.lemonHerbChicken.imageURL)
        #expect(card.imageURL != nil)
    }

    @Test func makeCard_keepsNilImageURL() {
        let card = RecipeLibraryViewModel.makeCard(from: .fixture(imageURL: nil))

        #expect(card.imageURL == nil)
    }

    @Test func makeCard_keepsIdAndTitle() {
        let card = RecipeLibraryViewModel.makeCard(from: .lemonHerbChicken)

        #expect(card.id == "lemon-herb-chicken")
        #expect(card.title == "Lemon Herb Chicken")
    }
    // MARK: - Caption and no-results state

    @Test(arguments: [
        ("Pet", false),
        ("gateau", false),
        ("ramekins", true),
        ("", false),
        ("   ", false),
    ])
    func makeCard_marksAStepOnlyMatch(searchedText: String, expectedIsStepOnlyMatch: Bool) {
        let card = RecipeLibraryViewModel.makeCard(from: .petitGateau, searchedText: searchedText)

        #expect(card.isStepOnlyMatch == expectedIsStepOnlyMatch)
    }

    @Test func search_presentsCaptionsOnlyForStepOnlyMatches() async {
        let (sut, spy) = makeSUT()
        await load(sut, on: spy, completingWith: [.petitGateau])

        sut.didChangeSearch("roast")
        await spy.waitUntilRequested(count: 2)
        await finishSearch(on: spy, at: 1, with: [.roastedVegetableCouscous, .lemonHerbChicken])

        #expect(sut.viewData.cards.map(\.isStepOnlyMatch) == [false, true])
    }

    @Test func searchedText_isThePresentedQueriesTextNotANewerKeystroke() async {
        let (sut, spy) = makeSUT()
        await load(sut, on: spy, completingWith: [.petitGateau])
        sut.didChangeSearch("tofu")
        await spy.waitUntilRequested(count: 2)
        sut.didChangeSearch("tofu lasagna")
        await spy.waitUntilRequested(count: 3)
        // The reply to "tofu" is outdated; the one to "tofu lasagna" is still in flight.
        await spy.complete(with: [], at: 1)
        await settle()
        #expect(sut.viewData.searchedText == "")

        await spy.complete(with: [], at: 2)
        await settle()
        sut.didChangeSearch("tofu lasagna with cheese")
        await spy.waitUntilRequested(count: 4)

        #expect(sut.viewData.searchedText == "tofu lasagna")
        await spy.failPendingRequests()
    }

    @Test func searchedWithFilters_followsThePresentedResultNotTheLiveFilters() async {
        let (sut, spy) = makeSUT()
        await load(sut, on: spy, completingWith: [.petitGateau])
        #expect(!sut.viewData.searchedWithFilters)

        sut.filtersViewModel.setVegetarianOnly(true)
        await spy.waitUntilRequested(count: 2)
        #expect(sut.viewData.activeFilterCount == 1)
        #expect(!sut.viewData.searchedWithFilters)

        await finishSearch(on: spy, at: 1, with: [])
        #expect(sut.viewData.searchedWithFilters)
    }

    @Test func noResultsCause_isNilWhileThereAreResults() async {
        let (sut, spy) = makeSUT()

        await load(sut, on: spy, completingWith: [.petitGateau])

        #expect(sut.viewData.noResultsCause == nil)
    }

    @Test func noResultsCause_fromTextAlone_isText() async {
        let (sut, spy) = makeSUT()
        await load(sut, on: spy, completingWith: [.petitGateau])

        sut.didChangeSearch("tofu lasagna")
        await spy.waitUntilRequested(count: 2)
        await finishSearch(on: spy, at: 1, with: [])

        #expect(sut.viewData.noResultsCause == .text)
    }

    @Test func noResultsCause_fromFiltersAlone_isFilters() async {
        let (sut, spy) = makeSUT()
        await load(sut, on: spy, completingWith: [.petitGateau])

        sut.filtersViewModel.setVegetarianOnly(true)
        await spy.waitUntilRequested(count: 2)
        await finishSearch(on: spy, at: 1, with: [])

        #expect(sut.viewData.noResultsCause == .filters)
    }

    @Test func noResultsCause_fromTextAndFilters_isTextAndFilters() async {
        let (sut, spy) = makeSUT()
        await load(sut, on: spy, completingWith: [.petitGateau])
        sut.didChangeSearch("roast")
        await spy.waitUntilRequested(count: 2)
        await finishSearch(on: spy, at: 1, with: [.lemonHerbChicken])

        sut.filtersViewModel.setVegetarianOnly(true)
        await spy.waitUntilRequested(count: 3)
        await finishSearch(on: spy, at: 2, with: [])

        #expect(sut.viewData.noResultsCause == .textAndFilters)
    }

    @Test func noResultsCause_withNeitherTextNorFilters_countsAsText() async {
        let (sut, spy) = makeSUT()

        await load(sut, on: spy, completingWith: [])

        #expect(sut.viewData.noResultsCause == .text)
    }

    @Test func clearFilters_turnsFiltersOffKeepsTheTextAndSearchesAgain() async {
        let (sut, spy) = makeSUT()
        await load(sut, on: spy, completingWith: [.petitGateau])
        sut.didChangeSearch("roast")
        await spy.waitUntilRequested(count: 2)
        sut.filtersViewModel.setVegetarianOnly(true)
        await spy.waitUntilRequested(count: 3)
        await finishSearch(on: spy, at: 2, with: [])
        #expect(sut.viewData.noResultsCause == .textAndFilters)

        sut.clearFilters()
        await spy.waitUntilRequested(count: 4)
        await finishSearch(on: spy, at: 3, with: [.lemonHerbChicken])

        #expect(spy.requestedQueries.last == RecipeSearchQuery(searchText: "roast"))
        #expect(sut.viewData.activeFilterCount == 0)
        #expect(sut.viewData.cards.map(\.id) == ["lemon-herb-chicken"])
        #expect(sut.viewData.noResultsCause == nil)
    }
}

// MARK: - Helpers

private extension RecipeLibraryViewModelTests {
    typealias SUTBundle = (sut: RecipeLibraryViewModel, spy: RecipeListServiceSpy)

    func makeSUT(searchDebounce: Duration = .zero) -> SUTBundle {
        let spy = RecipeListServiceSpy()
        let sut = RecipeLibraryViewModel(service: spy, searchDebounce: searchDebounce)
        return (sut, spy)
    }

    /// Starts a load and waits until the service has received the request,
    /// so the test can look at the view model while the load is in flight.
    func startLoad(
        of sut: RecipeLibraryViewModel,
        on spy: RecipeListServiceSpy,
        expectedRequestCount: Int = 1
    ) async -> Task<Void, Never> {
        let loadTask = Task { await sut.load() }
        await spy.waitUntilRequested(count: expectedRequestCount)
        return loadTask
    }

    /// A whole load that succeeds, for tests that only care about the end state.
    func load(_ sut: RecipeLibraryViewModel, on spy: RecipeListServiceSpy, completingWith previews: [RecipePreview]) async {
        let loadTask = await startLoad(of: sut, on: spy)
        await spy.complete(with: previews)
        await loadTask.value
    }

    /// A whole load that fails, for tests that only care about the end state.
    func load(_ sut: RecipeLibraryViewModel, on spy: RecipeListServiceSpy, failingWith error: any Error) async {
        let loadTask = await startLoad(of: sut, on: spy)
        await spy.fail(with: error)
        await loadTask.value
    }

    /// Completes a search that is the latest one and waits for the view model to present it.
    func finishSearch(on spy: RecipeListServiceSpy, at requestIndex: Int, with previews: [RecipePreview]) async {
        await spy.complete(with: previews, at: requestIndex)
        await settle()
    }

    /// Gives the view model's tasks turns to react to what the spy just finished.
    func settle() async {
        for _ in 0..<10 { await Task.yield() }
    }
}
