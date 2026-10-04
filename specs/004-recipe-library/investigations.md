Created: 2026-10-04
Updated: 2026-10-04

# 004 Recipe Library: investigations

Two design questions in this spec were settled by running code, not by opinion.
This file is the readme for the scripts in [`investigations/`](investigations/):
what each one asks, how to run it, what it printed, and what we decided. The
decisions are folded into [SPEC.md](SPEC.md); this file keeps the evidence so
the decisions can be re-checked.

Environment for every number below: Apple M1 Pro, Swift 6.3.2, Xcode 26.5,
`swiftc -O`, run from a terminal on a Mac (not a device). Timings vary by about
10-20% between runs, so read them as orders of magnitude.

| # | Question | Script | Verdict |
|---|---|---|---|
| 1 | One formatting function, or one per property? | `formatting-benchmark.swift` | Format each recipe once in one mapper; do not build per-property relabel paths |
| 2 | Where does `@Observable` go, and should the view data be `Equatable`? | `observable-on-struct.swift`, `observation-tracking.swift`, `observation-equatable.swift`, `viewstate-equatable.swift` | `@Observable` on view models only; make all view data and `ViewState` `Equatable` |

Related backlog item: [Formatting benchmark](../../product/BACKLOG.md#formatting-benchmark-kept-as-a-check)
(re-run investigation 1 when the servings label moves to a String Catalog).

---

## 1. One formatting function, or one per property?

**Context.** The Library formats each recipe into a card (`RecipeCardViewData`,
with a "1 serving" / "N servings" label). The question: when the user changes a
filter (for example servings to 3-4), should we re-run one mapper that rebuilds
the whole card, or keep individual functions and redo only the property that
changed? And is it better to map once and keep the result?

**Script.** [`investigations/formatting-benchmark.swift`](investigations/formatting-benchmark.swift)

```
swiftc -O formatting-benchmark.swift -o /tmp/formatting-benchmark && /tmp/formatting-benchmark
```

It mimics `RecipePreview` and a card view-data struct, and times (median over 9
rounds, with a checksum so the optimizer cannot drop the work):

- filter change to 3-4 at 9, 1,000 and 100,000 recipes, three ways: remap
  everything then filter, filter then remap the survivors, map once and filter
  the cached view data
- the same again with a heavier formatter, `String(localized:)`, the machinery a
  String Catalog uses
- one card rebuilt in full versus one label only
- formatting inside the view body versus reading precomputed view data (9 cards)
- an `Equatable` diff of 100,000 cards where one changed

**Results** (time per filter change):

| Recipes | Remap survivors | Map once, filter cached |
|---|---|---|
| 9 | 0.95 µs | 0.68 µs |
| 1,000 | 103 µs | 74 µs |
| 100,000 | 14 ms | 7.7 ms |

With `String(localized:)`:

| Recipes | Remap all, then filter | Filter, then remap survivors | Map once, filter cached |
|---|---|---|---|
| 9 | 85 µs | 28 µs | 0.7 µs |
| 1,000 | 9.2 ms | 3.2 ms | 73 µs |
| 100,000 | 932 ms | 307 ms | 7.8 ms |

Other measurements: a full card rebuild is 85 ns against 4 ns for one label (a
gap of about 80 ns); formatting 9 cards in the body costs about 0.6 µs per body
evaluation against 0.4 µs reading precomputed values; an `Equatable` diff of
100,000 cards with one change takes about 19 ms.

**Reading.**

- With cheap formatting every option is under 1 µs at 9 recipes. It does not
  matter.
- Grouping is not the cost. Per-property functions save about 80 ns per card.
  What costs is how many times the formatter runs: with `String(localized:)`,
  mapping once is roughly 40-100x cheaper than remapping on every change.
- Search goes through the endpoint in milestone D (see the roadmap), so results
  arrive as fresh previews; that is the "remap survivors" row, still cheap at
  the dataset size here.

**Decision.** One static mapper, `RecipeCardViewDataMapper.map(_:)`, called once
per recipe per data arrival, with servings text from one `ServingsLabelFormatter`.
No per-property relabel path. Add memoization by recipe id only if a profile
shows the heavier formatter matters.

**Limits.** It measures mapping and diffing only, not SwiftUI's own body work.
It ran on a Mac, not a device. Re-run it when the formatting changes.

---

## 2. Where does `@Observable` go, and should the view data be `Equatable`?

**Context.** The screen has a view model (`RecipeLibraryViewModel`) and view data
structs (`RecipeLibraryViewData`, holding `state: ViewState` and
`cards: [RecipeCardViewData]`). Coming from `ObservableObject` and `@Published`,
three things were unclear: does each struct need `@Observable` too, is the view
model's `@Observable` enough, and does `Equatable` have anything to do with
whether a change reaches the view?

**Sources.** Apple's docs, read with the `/apple-doc` skill:
[`Observable()`](https://developer.apple.com/documentation/observation/observable())
(the macro; its example is a class, and its declaration lists
`shouldNotifyObservers`),
[`Observable`](https://developer.apple.com/documentation/observation/observable)
(the protocol), and
[Migrating from the Observable Object protocol to the Observable macro](https://developer.apple.com/documentation/swiftui/migrating-from-the-observable-object-protocol-to-the-observable-macro)
(drop `@Published`; SwiftUI updates a view only when a property its body reads
changes).

**Scripts** (all in [`investigations/`](investigations/); the run command is in
each file's header):

| Script | Asks | Result |
|---|---|---|
| `observable-on-struct.swift` | Can `@Observable` go on a struct? | Compile error: `'@Observable' cannot be applied to struct type` |
| `observation-tracking.swift` | How fine is tracking for a struct property inside an `@Observable` class? | Tracked as one property (table below) |
| `observation-equatable.swift` | Does `Equatable` change when a set notifies? | Yes (table below) |
| `viewstate-equatable.swift` | Can `ViewState` be `Equatable` with `error(any Error)`? | No; with `error(RecipeError)` it compiles |

### Finding A: `@Observable` goes on the view model class, never on the structs

It does not compile on a struct. So `RecipeCardViewData` and
`RecipeLibraryViewData` are plain value types. The class's `@Observable` is
enough: Observation records which properties of the view model a view's `body`
reads, and re-evaluates that body when one of them is set.

### Finding B: tracking granularity is the class property, not the struct's fields

```
reads viewData.state; VM mutates viewData.state in place:  FIRED
reads viewData.cards; VM replaces whole viewData:          FIRED
reads viewData;       VM changes an UNRELATED property:    did not fire
```

`viewData` is one tracked property. Changing any field inside it counts as
setting `viewData`, so every view that reads `viewData` is invalidated, even a
view that reads only `viewData.cards` when only `state` changed. Properties of
the view model that were not read are not involved.

### Finding C: `Equatable` does not stop a real change; it stops a redundant one

This is the point that is easy to get backwards. `Equatable` never causes a
change to be missed. The generated setter compares old and new only when the
type is `Equatable`:

```
Equatable value,     assigned an EQUAL value:       did not fire
Equatable value,     assigned a DIFFERENT value:    FIRED
Non-Equatable value, assigned an EQUAL value:       FIRED
Non-Equatable value, assigned a DIFFERENT value:    FIRED
```

- A different value always fires, `Equatable` or not.
- If the type is not `Equatable`, every assignment fires, including assigning
  the same data again. Nothing is lost; it is just wasted work (a body
  re-evaluation for no visible change).
- If the type is `Equatable`, assigning an equal value is skipped.

So "if we do not make it `Equatable`, changes will not fire" is the reverse of
what happens. Without `Equatable`, more fires, not fewer.

### Finding D: `ViewState` can be `Equatable` if its error is a `RecipeError`

`case error(any Error & Sendable)` blocks the synthesized conformance, because
`any Error` is not `Equatable` (compiler: "associated value type 'any Error'
does not conform to protocol 'Equatable'"). Options:

| Option | What it means | Verdict |
|---|---|---|
| A. `error(RecipeError)` | `RecipeError` is already `Equatable` and `Sendable`, so conformance is synthesized. The view model maps any other thrown error to `.unavailable`, as the services already do | **Chosen** |
| B. Hand-written `==` that compares only the case | Two different errors compare equal, so an error message that changes would not update the view | Rejected: hides real changes |
| C. Leave `ViewState` not `Equatable` | Then `RecipeLibraryViewData` cannot be `Equatable`, and every assignment of `viewData` fires | Rejected: loses the redundant-set skip and the card diff |

### Decision

- `@Observable` on view models only (`RecipeLibraryViewModel`,
  `FilterChipsViewModel`). No `@Observable` on any `...ViewData`.
- Every view data type is `Equatable`: `RecipeCardViewData`,
  `RecipeLibraryViewData`, `FilterChipViewData`, `FilterChipsViewData`, plus
  `ViewState` through option A.
- The view model exposes one `private(set) var viewData`, replaced or mutated
  as a whole.

### Trade-offs of that decision

| Gain | Cost |
|---|---|
| Re-assigning equal data (a reload that returns the same recipes, a repeated `.loaded`) does not invalidate any view | Every set of `viewData` compares the whole struct, including all cards. About 0.2 µs at 9 cards; the 100,000-card diff measured about 19 ms |
| `Equatable` cards let SwiftUI compare card values and skip unchanged ones ([Fatbobman](https://fatbobman.com/en/posts/avoid_repeated_calculations_of_swiftui_views/)) | Any field change invalidates every view that reads `viewData` directly, because tracking is per class property (finding B). Here only `RecipeLibraryView` reads it; cards get their data by value and are diffed through `Equatable`, so in practice this costs nothing today |
| `Equatable` view data is trivially unit-testable (`#expect(viewData == expected)`) | The error case carries only a `RecipeError`: an unexpected error type loses its detail when mapped to `.unavailable` |
| One observed property keeps the view model simple | `ViewState` in `Presentation/Shared` now depends on the domain `RecipeError`. Allowed (`Presentation` imports `Domain`), but a screen that wants a different error type needs a generic `ViewState` |

For context, this is what `@Observable` already buys over `ObservableObject`: a
view re-renders only when a property its body reads changes, not when any
published property changes ([Nil Coalescing](https://nilcoalescing.com/blog/ObservableInSwiftUI/),
[WWDC23 10149](https://developer.apple.com/videos/play/wwdc2023/10149)). The
finer split inside `viewData` is a separate, smaller question.

The two costs that could grow are the whole-struct comparison and views that
read `viewData` directly. Both are negligible at this size and have the same fix
when they are not: expose `state` and `cards` as two observed properties on the view model
so a state change neither compares nor invalidates the cards. That would
replace the single `viewData` property, so it is a deliberate non-choice for
now, to be revisited only after a profile or after pagination (backlog) makes
the list large. The loss of error detail has its own home in the backlog item
"Observability".

### Open: not verified here

- Whether SwiftUI skips re-evaluating a card's `body` when the card's view data
  is unchanged is described by the Fatbobman article linked above, but this
  investigation did not measure SwiftUI's own diffing. Check with the
  `Self._printChanges()` pass at the simulator step of the spec if it matters.
