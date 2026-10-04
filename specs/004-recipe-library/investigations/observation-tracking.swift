// Investigation 2b (spec 004): how fine is Observation's tracking when the observed
// property is a struct inside an @Observable class?
// Run:  swiftc -O -swift-version 5 observation-tracking.swift -o /tmp/observation-tracking && /tmp/observation-tracking
// (Swift 5 mode only because the closures in this test are not Sendable-annotated.)
import Observation
import Foundation
enum RecipeError: Error, Equatable, Sendable { case unavailable }
enum ViewState: Equatable, Sendable { case idle, loading, loaded, error(RecipeError) }
struct CardViewData: Equatable, Identifiable, Sendable { let id: String; let title: String }
struct LibraryViewData: Equatable, Sendable { var state: ViewState = .idle; var cards: [CardViewData] = [] }

@MainActor @Observable final class LibraryViewModel {
    private(set) var viewData = LibraryViewData()
    var unrelated = 0
    func setLoading() { viewData.state = .loading }
    func setLoaded() { viewData = LibraryViewData(state: .loaded, cards: [CardViewData(id: "a", title: "A")]) }
    func touchUnrelated() { unrelated += 1 }
}

final class FiredFlag: @unchecked Sendable { var value = false }

@MainActor func run() {
    let viewModel = LibraryViewModel()
    var results: [String] = []
    func watch(_ label: String, _ read: () -> Void, then change: () -> Void) {
        let flag = FiredFlag()
        withObservationTracking({ read() }, onChange: { flag.value = true })
        change()
        results.append("\(label): \(flag.value ? "FIRED" : "did not fire")")
    }
    watch("reads viewData.state; VM mutates viewData.state in place", { _ = viewModel.viewData.state }, then: { viewModel.setLoading() })
    watch("reads viewData.cards; VM replaces whole viewData      ", { _ = viewModel.viewData.cards }, then: { viewModel.setLoaded() })
    watch("reads viewData;       VM changes an UNRELATED property ", { _ = viewModel.viewData }, then: { viewModel.touchUnrelated() })
    results.forEach { print($0) }
}
MainActor.assumeIsolated { run() }
