// Investigation 2d (spec 004): can ViewState be Equatable?
// Run the failing case:   swiftc -typecheck -swift-version 6 -D FAILS viewstate-equatable.swift
// Run the working case:   swiftc -typecheck -swift-version 6 viewstate-equatable.swift
enum RecipeError: Error, Equatable, Sendable {
    case notFound
    case invalidData(reason: String)
    case unavailable
}

#if FAILS
// error: type 'ViewState' does not conform to protocol 'Equatable'
// (associated value type 'any Error' does not conform to protocol 'Equatable')
enum ViewState: Equatable {
    case idle, loading, loaded
    case error(any Error & Sendable)
}
#else
enum ViewState: Equatable, Sendable {
    case idle, loading, loaded
    case error(RecipeError)
}

struct RecipeCardViewData: Equatable, Identifiable, Sendable {
    let id: String
    let title: String
}

struct RecipeLibraryViewData: Equatable, Sendable {
    var state: ViewState
    var cards: [RecipeCardViewData]
}
#endif
