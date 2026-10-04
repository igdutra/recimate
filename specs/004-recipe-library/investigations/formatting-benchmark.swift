// Investigation 1 (spec 004): format each recipe once in one mapper, or per property?
// Run:  swiftc -O formatting-benchmark.swift -o /tmp/formatting-benchmark && /tmp/formatting-benchmark
// See ../investigations.md for the results and the conclusion.
import Foundation

struct RecipePreview {
    let id: String
    let title: String
    let summary: String
    let servings: Int
    let isVegetarian: Bool
    let imageURL: URL?
}

struct RecipeCardViewData: Equatable, Identifiable {
    let id: String
    let title: String
    let servingsLabel: String
    let isVegetarian: Bool
    let imageURL: URL?
}

enum ServingsFormatter {
    static func label(servings: Int) -> String { servings == 1 ? "1 serving" : "\(servings) servings" }
}

enum RecipeCardViewDataMapper {
    static func map(_ preview: RecipePreview) -> RecipeCardViewData {
        RecipeCardViewData(
            id: preview.id,
            title: preview.title,
            servingsLabel: ServingsFormatter.label(servings: preview.servings),
            isVegetarian: preview.isVegetarian,
            imageURL: preview.imageURL
        )
    }
}

func makePreviews(count: Int) -> [RecipePreview] {
    (0..<count).map { index in
        RecipePreview(id: "recipe-\(index)", title: "Recipe number \(index)", summary: "Summary \(index)",
                      servings: 1 + index % 6, isVegetarian: index % 2 == 0,
                      imageURL: URL(string: "https://example.com/\(index).jpg"))
    }
}

let clock = ContinuousClock()
var checksum = 0

/// Median nanoseconds per call of `work`, over several timed rounds.
func measure(rounds: Int = 9, iterations: Int, _ work: () -> Int) -> Double {
    var samples: [Double] = []
    for _ in 0..<rounds {
        let elapsed = clock.measure { for _ in 0..<iterations { checksum &+= work() } }
        let nanoseconds = Double(elapsed.components.attoseconds) / 1e9 + Double(elapsed.components.seconds) * 1e9
        samples.append(nanoseconds / Double(iterations))
    }
    return samples.sorted()[samples.count / 2]
}

func format(_ nanoseconds: Double) -> String {
    nanoseconds >= 1000 ? String(format: "%9.1f µs", nanoseconds / 1000) : String(format: "%9.0f ns", nanoseconds)
}

// The user's scenario: servings filter changes from "any" to "3-4".
let servingsRange = 3...4
print("Scenario: servings filter changes to 3-4. Median time per filter change.\n")
print("recipes | A remap survivors each change | B dictionary lookup (unfair) | C map once, filter cached | ratio A/C")
for recipeCount in [9, 1_000, 100_000] {
    let previews = makePreviews(count: recipeCount)
    let iterations = max(1, 200_000 / recipeCount)

    // A: every filter change filters the previews, then runs the whole mapper again on the survivors.
    let remapEverything = measure(iterations: iterations) {
        previews.filter { preview in servingsRange.contains(preview.servings) }.map(RecipeCardViewDataMapper.map).count
    }

    // B: map everything once (outside the timed region); a filter change only filters cached view data.
    let cachedViewData = previews.map(RecipeCardViewDataMapper.map)
    let previewByID = Dictionary(uniqueKeysWithValues: previews.map { preview in (preview.id, preview.servings) })
    let filterCached = measure(iterations: iterations) {
        cachedViewData.filter { cachedCard in servingsRange.contains(previewByID[cachedCard.id]!) }.count
    }

    // C: same as B but the filter is a cheap lookup of a precomputed servings value (no dictionary).
    let cachedPairs = zip(previews, cachedViewData).map { preview, viewData in (servings: preview.servings, viewData: viewData) }
    let filterPairs = measure(iterations: iterations) {
        cachedPairs.filter { pair in servingsRange.contains(pair.servings) }.count
    }
    print(String(format: "%7d | %@ | %@ | %@ | %.1fx", recipeCount, format(remapEverything), format(filterCached), format(filterPairs), remapEverything / filterPairs))
}

// Heavier formatter: String(localized:) goes through the localization machinery (what a String Catalog would use).
func localizedLabel(servings: Int) -> String {
    String(localized: "\(servings) servings")
}
struct CachedCard { let servings: Int; let viewData: RecipeCardViewData }
print("\nSame scenario with heavier String(localized:) formatting. Time per filter change.")
print("recipes | A2 remap ALL then filter | A1 filter then remap survivors | B map once, filter cached")
for recipeCount in [9, 1_000, 100_000] {
    let previews = makePreviews(count: recipeCount)
    let iterations = max(1, 100_000 / recipeCount)
    func mapHeavy(_ preview: RecipePreview) -> CachedCard {
        CachedCard(servings: preview.servings, viewData: RecipeCardViewData(id: preview.id, title: preview.title,
            servingsLabel: localizedLabel(servings: preview.servings), isVegetarian: preview.isVegetarian, imageURL: preview.imageURL))
    }
    let remapAllThenFilter = measure(iterations: iterations) { previews.map(mapHeavy).filter { cachedCard in servingsRange.contains(cachedCard.servings) }.count }
    let filterThenRemap = measure(iterations: iterations) { previews.filter { preview in servingsRange.contains(preview.servings) }.map(mapHeavy).count }
    let cache = previews.map(mapHeavy)
    let filterCache = measure(iterations: iterations) { cache.filter { cachedCard in servingsRange.contains(cachedCard.servings) }.count }
    print(String(format: "%7d | %@ | %@ | %@", recipeCount, format(remapAllThenFilter), format(filterThenRemap), format(filterCache)))
}

// Unified vs individual formatting: cost of rebuilding the whole view data vs one property.
let onePreview = makePreviews(count: 1)[0]
let fullRebuild = measure(iterations: 2_000_000) { RecipeCardViewDataMapper.map(onePreview).servingsLabel.utf8.count }
let oneLabelOnly = measure(iterations: 2_000_000) { ServingsFormatter.label(servings: onePreview.servings).utf8.count }
print("\nOne card: full mapper \(format(fullRebuild))  vs  servings label only \(format(oneLabelOnly))  (difference \(format(fullRebuild - oneLabelOnly)))")

// Formatting in the view body: every body evaluation re-formats each visible card.
let nine = makePreviews(count: 9)
let formatInBody = measure(iterations: 200_000) { nine.map { preview in ServingsFormatter.label(servings: preview.servings).utf8.count }.reduce(0, +) }
let readPrecomputed = measure(iterations: 200_000) { nine.map(RecipeCardViewDataMapper.map).map { viewData in viewData.servingsLabel.utf8.count }.reduce(0, +) }
let precomputedViewData = nine.map(RecipeCardViewDataMapper.map)
let readOnly = measure(iterations: 200_000) { precomputedViewData.map { viewData in viewData.servingsLabel.utf8.count }.reduce(0, +) }
print("9 cards, per body evaluation: format in body \(format(formatInBody)), map+read \(format(readPrecomputed)), read precomputed only \(format(readOnly))")

// Equatable diff: SwiftUI skips a card whose view data is unchanged.
let oldCards = makePreviews(count: 100_000).map(RecipeCardViewDataMapper.map)
var newCards = oldCards
newCards[500] = RecipeCardViewData(id: oldCards[500].id, title: oldCards[500].title, servingsLabel: "9 servings", isVegetarian: true, imageURL: nil)
let diff = measure(rounds: 5, iterations: 20) { zip(oldCards, newCards).filter { oldCard, newCard in oldCard != newCard }.count }
print("Equatable diff of 100,000 cards where 1 changed: \(format(diff))")
print("\n(checksum \(checksum))")
