import Foundation
import Testing
@testable import ReciMate

@Suite(.hangGuard)
@MainActor
struct RecipeDetailsViewModelTests {
    // MARK: - Initial state

    @Test func init_startsLoadingWithNoContent() {
        let (sut, _) = makeSUT()

        #expect(sut.viewData == RecipeDetailsViewData(state: .loading, content: .placeholder))
    }

    // MARK: - Happy path

    @Test func load_onSuccess_deliversContentForTheRecipe() async {
        let (sut, spy) = makeSUT(recipeID: "petit-gateau")

        await load(sut, on: spy, completingWith: .petitGateau)

        #expect(sut.viewData.state == .loaded)
        #expect(sut.viewData.content == RecipeDetailsViewModel.makeContent(from: .petitGateau))
        #expect(spy.requestedIDs == ["petit-gateau"])
    }

    @Test func load_onSuccess_staysLoadingUntilServiceReturnsThenLoaded() async {
        let (sut, spy) = makeSUT()

        let loadTask = await startLoad(of: sut, on: spy)
        #expect(sut.viewData == RecipeDetailsViewData(state: .loading, content: .placeholder))

        await spy.complete(with: .petitGateau)
        await loadTask.value
        #expect(sut.viewData.state == .loaded)
        #expect(sut.viewData.content != .placeholder)
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
        #expect(sut.viewData == RecipeDetailsViewData(state: .error(recipeError), content: .placeholder))
    }

    @Test func load_onNonRecipeError_movesToUnavailable() async {
        struct UnrelatedError: Error {}
        let (sut, spy) = makeSUT()

        await load(sut, on: spy, failingWith: UnrelatedError())

        #expect(sut.viewData == RecipeDetailsViewData(state: .error(.unavailable), content: .placeholder))
    }

    // MARK: - Repeated loads

    @Test func load_whenAlreadyLoaded_doesNotCallServiceAgain() async {
        let (sut, spy) = makeSUT()
        await load(sut, on: spy, completingWith: .petitGateau)

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

        await spy.complete(with: .petitGateau)
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
        await spy.complete(with: .petitGateau, at: 1)
        await retryLoadTask.value

        #expect(spy.requestCount == 2)
        #expect(sut.viewData.state == .loaded)
    }

    // MARK: - Mapping

    @Test func makeContent_keepsTitleSummaryAndImageURL() {
        let content = RecipeDetailsViewModel.makeContent(from: .lemonHerbChicken)

        #expect(content.title == "Lemon Herb Chicken")
        #expect(content.summary == "Roasted chicken with bright lemon and herbs.")
        #expect(content.imageURL == RecipeDetails.lemonHerbChicken.imageURL)
        #expect(content.imageURL != nil)
    }

    @Test func makeContent_keepsNilImageURL() {
        let content = RecipeDetailsViewModel.makeContent(from: .fixture(imageURL: nil))

        #expect(content.imageURL == nil)
    }

    @Test(arguments: [(1, "1 serving"), (2, "2 servings"), (5, "5 servings")])
    func makeContent_formatsServingsLabel(servingCount: Int, expectedLabel: String) {
        let content = RecipeDetailsViewModel.makeContent(from: .fixture(servings: servingCount))

        #expect(content.servingsLabel == expectedLabel)
    }

    @Test(arguments: [true, false])
    func makeContent_carriesVegetarianFlag(isVegetarian: Bool) {
        let content = RecipeDetailsViewModel.makeContent(from: .fixture(isVegetarian: isVegetarian))

        #expect(content.isVegetarian == isVegetarian)
    }

    @Test func makeContent_keepsIngredientOrderAndNilQuantity() {
        let content = RecipeDetailsViewModel.makeContent(from: .fixture(ingredients: [.salt, .eggs, .chicken]))

        #expect(content.ingredients == [
            IngredientRowViewData(id: "salt", name: "Salt", quantity: nil),
            IngredientRowViewData(id: "eggs", name: "Eggs", quantity: "2"),
            IngredientRowViewData(id: "chicken", name: "Chicken", quantity: "1 whole"),
        ])
    }

    @Test func makeContent_keepsStepNumbersAndOrder() {
        let content = RecipeDetailsViewModel.makeContent(from: .fixture(instructions: [
            .fixture(step: 3, text: "Third."),
            .fixture(step: 7, text: "Seventh."),
        ]))

        #expect(content.steps == [
            StepRowViewData(number: 3, text: "Third."),
            StepRowViewData(number: 7, text: "Seventh."),
        ])
        #expect(content.steps.map(\.id) == [3, 7])
    }

    @Test func makeContent_onEmptyIngredientsAndSteps_mapsToEmptyLists() {
        let content = RecipeDetailsViewModel.makeContent(from: .fixture(ingredients: [], instructions: []))

        #expect(content.ingredients.isEmpty)
        #expect(content.steps.isEmpty)
    }
}

// MARK: - Helpers

private extension RecipeDetailsViewModelTests {
    typealias SUTBundle = (sut: RecipeDetailsViewModel, spy: RecipeDetailsServiceSpy)

    func makeSUT(recipeID: String = "petit-gateau") -> SUTBundle {
        let spy = RecipeDetailsServiceSpy()
        let sut = RecipeDetailsViewModel(recipeID: recipeID, service: spy)
        return (sut, spy)
    }

    /// Starts a load and waits until the service has received the request,
    /// so the test can look at the view model while the load is in flight.
    func startLoad(
        of sut: RecipeDetailsViewModel,
        on spy: RecipeDetailsServiceSpy,
        expectedRequestCount: Int = 1
    ) async -> Task<Void, Never> {
        let loadTask = Task { await sut.load() }
        await spy.waitUntilRequested(count: expectedRequestCount)
        return loadTask
    }

    /// A whole load that succeeds, for tests that only care about the end state.
    func load(_ sut: RecipeDetailsViewModel, on spy: RecipeDetailsServiceSpy, completingWith recipe: RecipeDetails) async {
        let loadTask = await startLoad(of: sut, on: spy)
        await spy.complete(with: recipe)
        await loadTask.value
    }

    /// A whole load that fails, for tests that only care about the end state.
    func load(_ sut: RecipeDetailsViewModel, on spy: RecipeDetailsServiceSpy, failingWith error: any Error) async {
        let loadTask = await startLoad(of: sut, on: spy)
        await spy.fail(with: error)
        await loadTask.value
    }
}
