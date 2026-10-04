import Testing
@testable import ReciMate

// No helpers: the formatter is a pure function with nothing to build.
@Suite(.hangGuard)
@MainActor
struct ServingsLabelFormatterTests {
    @Test(arguments: [(1, "1 serving"), (2, "2 servings"), (5, "5 servings")])
    func label_formatsServingCount(servingCount: Int, expectedLabel: String) {
        #expect(ServingsLabelFormatter.label(forServingCount: servingCount) == expectedLabel)
    }
}
