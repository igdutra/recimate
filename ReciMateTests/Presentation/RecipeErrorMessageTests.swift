import Testing
@testable import ReciMate

struct RecipeErrorMessageTests {
    @Test(arguments: [
        (RecipeError.notFound, "We couldn't find what you were looking for."),
        (.invalidData(reason: "missing key"), "The data we received couldn't be read."),
        (.unavailable, "Something went wrong while loading."),
    ])
    func errorMessage_dependsOnTheErrorKind(recipeError: RecipeError, expectedMessage: String) {
        #expect(recipeError.errorMessage == expectedMessage)
    }

    @Test func errorMessage_ofInvalidData_ignoresTheReason() {
        let firstMessage = RecipeError.invalidData(reason: "missing key").errorMessage
        let secondMessage = RecipeError.invalidData(reason: "wrong type at step 2").errorMessage

        #expect(firstMessage == secondMessage)
    }
}
