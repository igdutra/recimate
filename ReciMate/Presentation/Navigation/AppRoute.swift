/// Where a push can go. A route carries ids only: each screen loads what it shows.
enum AppRoute: Hashable {
    case details(recipeID: String)
}
