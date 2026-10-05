import Testing
@testable import ReciMate

struct RecipeSearchQueryTests {
    // MARK: - Terms

    @Test func addIncludedIngredient_trimsTheTerm() {
        var query = RecipeSearchQuery.empty

        query.addIncludedIngredient("  cream \n")

        #expect(query.includedIngredients == ["cream"])
    }

    @Test(arguments: ["", "   ", "\n\t"])
    func addIngredient_ignoresBlankTerms(blankTerm: String) {
        var query = RecipeSearchQuery.empty

        query.addIncludedIngredient(blankTerm)
        query.addExcludedIngredient(blankTerm)

        #expect(query == .empty)
    }

    @Test(arguments: ["cream", "CREAM", " Cream ", "crèam"])
    func addIncludedIngredient_ignoresRepeatsIgnoringCaseAndAccents(repeatedTerm: String) {
        var query = RecipeSearchQuery.empty
        query.addIncludedIngredient("cream")

        query.addIncludedIngredient(repeatedTerm)

        #expect(query.includedIngredients == ["cream"])
    }

    @Test func addIncludedIngredient_keepsInsertionOrderAndTypedSpelling() {
        var query = RecipeSearchQuery.empty

        query.addIncludedIngredient("Eggs")
        query.addIncludedIngredient("butter")

        #expect(query.includedIngredients == ["Eggs", "butter"])
    }

    @Test func addIncludedIngredient_removesTheTermFromExcluded() {
        var query = RecipeSearchQuery.empty
        query.addExcludedIngredient("Nuts")

        query.addIncludedIngredient("nuts")

        #expect(query.includedIngredients == ["nuts"])
        #expect(query.excludedIngredients.isEmpty)
    }

    @Test func addExcludedIngredient_removesTheTermFromIncluded() {
        var query = RecipeSearchQuery.empty
        query.addIncludedIngredient("nuts")

        query.addExcludedIngredient("Nuts")

        #expect(query.excludedIngredients == ["Nuts"])
        #expect(query.includedIngredients.isEmpty)
    }

    @Test func addExcludedIngredient_leavesOtherTermsAlone() {
        var query = RecipeSearchQuery.empty
        query.addIncludedIngredient("eggs")
        query.addIncludedIngredient("nuts")

        query.addExcludedIngredient("nuts")

        #expect(query.includedIngredients == ["eggs"])
    }

    @Test func removeIngredient_removesOnlyThatTerm() {
        var query = RecipeSearchQuery.empty
        query.addIncludedIngredient("eggs")
        query.addIncludedIngredient("butter")
        query.addExcludedIngredient("nuts")

        query.removeIncludedIngredient("EGGS")
        query.removeExcludedIngredient("nuts")

        #expect(query.includedIngredients == ["butter"])
        #expect(query.excludedIngredients.isEmpty)
    }

    // MARK: - Active count

    @Test func activeFilterCount_countsEachFilter() {
        var query = RecipeSearchQuery.empty
        #expect(query.activeFilterCount == 0)
        #expect(!query.hasFilters)

        query.onlyVegetarian = true
        #expect(query.activeFilterCount == 1)

        query.servings = 2
        #expect(query.activeFilterCount == 2)

        query.addIncludedIngredient("cream")
        query.addIncludedIngredient("tomato")
        query.addExcludedIngredient("mushrooms")
        #expect(query.activeFilterCount == 5)
        #expect(query.hasFilters)
    }

    @Test func activeFilterCount_ignoresSearchText() {
        let query = RecipeSearchQuery(instructionText: "ramekins")

        #expect(query.activeFilterCount == 0)
        #expect(!query.hasFilters)
    }

    // MARK: - Reset

    @Test func resetFilters_clearsEveryFilterAndKeepsTheText() {
        var query = RecipeSearchQuery(instructionText: "ramekins", onlyVegetarian: true, servings: 4)
        query.addIncludedIngredient("eggs")
        query.addExcludedIngredient("nuts")

        query.resetFilters()

        #expect(query == RecipeSearchQuery(instructionText: "ramekins"))
    }

    // MARK: - Text matching

    @Test(arguments: [
        ("Cooking cream", "cream"),
        ("Crème fraîche", "CREME"),
        ("Bake in ramekins", "RAMEKINS"),
        ("Bake the cakes", "  the cakes "),
    ])
    func textMatching_containsIgnoringCaseAndAccents(text: String, term: String) {
        #expect(SearchTextMatching.text(text, contains: term))
    }

    @Test func textMatching_doesNotMatchOtherText() {
        #expect(!SearchTextMatching.text("Cooking cream", contains: "butter"))
    }
}
