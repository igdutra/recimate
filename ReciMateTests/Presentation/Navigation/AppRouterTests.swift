import Testing
@testable import ReciMate

@MainActor
struct AppRouterTests {
    @Test func push_addsRouteToPath() {
        let router = AppRouter()

        router.push(.details(recipeID: "creamy-tomato-pasta"))

        #expect(router.path == [.details(recipeID: "creamy-tomato-pasta")])
    }

    @Test func pop_removesLastRoute() {
        let router = AppRouter()
        router.push(.details(recipeID: "creamy-tomato-pasta"))
        router.push(.details(recipeID: "petit-gateau"))

        router.pop()

        #expect(router.path == [.details(recipeID: "creamy-tomato-pasta")])
    }

    @Test func pop_onEmptyPath_doesNothing() {
        let router = AppRouter()

        router.pop()

        #expect(router.path.isEmpty)
    }

    @Test func popToRoot_emptiesPath() {
        let router = AppRouter()
        router.push(.details(recipeID: "creamy-tomato-pasta"))
        router.push(.details(recipeID: "petit-gateau"))

        router.popToRoot()

        #expect(router.path.isEmpty)
    }

    @Test func present_setsSheet() {
        let router = AppRouter()

        router.present(.filters)

        #expect(router.sheet == .filters)
    }

    @Test func dismissSheet_clearsSheet() {
        let router = AppRouter()
        router.present(.filters)

        router.dismissSheet()

        #expect(router.sheet == nil)
    }
}
