import Foundation
import Testing
@testable import ReciMate

@Suite(.hangGuard)
@MainActor
struct RecipeLibraryViewModelTests {
    // MARK: - Initial state

    @Test func init_startsLoadingWithNoCards() {
        let (sut, _) = makeSUT()

        #expect(sut.viewData == RecipeLibraryViewData(state: .loading, cards: []))
    }

    @Test func quickFilterBar_isOwnedByTheViewModel() {
        let (sut, _) = makeSUT()

        #expect(sut.quickFilterBar.viewData.chips.map(\.id) == [.vegetarian, .servings, .filters])
    }

    // MARK: - Happy path

    @Test func load_onSuccess_deliversCardsInRecipeOrder() async {
        let previews: [RecipePreview] = [.petitGateau, .lemonHerbChicken, .roastedVegetableCouscous]
        let (sut, spy) = makeSUT()

        await load(sut, on: spy, completingWith: previews)

        #expect(sut.viewData.state == .loaded)
        #expect(sut.viewData.cards == previews.map(RecipeLibraryViewModel.makeCard))
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

        #expect(sut.viewData == RecipeLibraryViewData(state: .loaded, cards: []))
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
}

// MARK: - Helpers

private extension RecipeLibraryViewModelTests {
    typealias SUTBundle = (sut: RecipeLibraryViewModel, spy: RecipeListServiceSpy)

    func makeSUT() -> SUTBundle {
        let spy = RecipeListServiceSpy()
        let sut = RecipeLibraryViewModel(service: spy)
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
}
