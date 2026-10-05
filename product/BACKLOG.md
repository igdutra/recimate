# Backlog

Ideas outside the challenge brief ([REQUIREMENTS.md](REQUIREMENTS.md)), not yet
scheduled in [ROADMAP.md](ROADMAP.md). Each gets scoped when it moves there.

## Pagination

Load the recipe list in pages instead of all at once, for example a 100-recipe
JSON read 10 at a time as the user scrolls. The service and view model only see
pages; the local client does the slicing, like a server would.

## Cancellation handling

Make a cancelled load (a `.task` that goes away, a search keystroke in milestone D) not
show up as `unavailable`. The local client cannot throw `CancellationError`, so
milestone B (spec 002) dropped the handling and its tests. Add it back, with a test,
together with the URLSession client: rethrow `CancellationError` (and map
`URLError(.cancelled)` to it) before the services' catch-all.

Test side, from the Essential Developer course's async spy pattern: `ServiceSpy`
(`ReciMateTests/Helpers/`) leaves cancellation out. When this lands, have it record a
third outcome, `cancelled`, when the awaiting task was cancelled (check `Task.isCancelled`
in the catch), and let a test wait for that outcome with the same bounded `Task.yield()`
loop. A view model that owns a task must cancel it in `deinit` and check
`Task.isCancelled` before presenting, because releasing a `Task` cancels nothing (unlike
an `AnyCancellable`). If the view model starts its work from a synchronous `load()`,
`Task.immediate` (iOS 26 and later) registers the request before the next line of the
test; with a plain `Task` the request registers one main-actor turn later.

## Search by title / description

Free-text search over recipe title and description. The brief only asks for
search within instruction text (S6), so this is extra scope. Spec 008's search
field searches instructions only, and its prompt says so. If wanted, it needs its
own requirement ID before moving to the roadmap.

## Features that need new recipe data

Each needs its data contract and UI defined before it is scheduled. None can be
built truthfully from the current fixture.

| Feature | Why defer it | Required new data |
| --- | --- | --- |
| Vegan / gluten-free / allergens | Useful, but beyond the required vegetarian filter | Dietary flags and reliable allergen handling |
| Difficulty | Helpful discovery filter | A consistently authored difficulty value |
| Course and cuisine | Common discovery filters, but adds taxonomy work | Course and cuisine values per recipe |
| Prep / cook time | Useful metadata | Prep and cook durations per recipe |
| Favourites | Requires persisted user state | Favourite storage and UI state |
| Cooking Mode | Outside the agreed scope | Step-progress state, timers, screen-awake behavior |
| Nutrition / calories | Requires trustworthy nutrition data | Nutrition facts per serving |

## Observability

Logging (for example `os.Logger`, injected into the services) and analytics: see
what failed in the field, such as the `reason` of an `invalidData` or the cause
behind an `unavailable`, without the services validating or masking the
backend's data. Not part of the challenge; nothing in the data layer logs today.

## Loading and empty-collection states

The Library's loading state (placeholders or a spinner while the first load runs)
and its empty-collection state (no recipes at all, which is different from no
results). The brief asks only for error handling, so error and no-results (E1) are
built and these two are not. The local JSON loads instantly, so loading is rarely
visible; both matter once a real network client replaces it.

## Quick filter chips

A horizontal row of chips above the Library grid (Vegetarian, Servings) that
duplicates two of the Filters sheet's controls. Built in spec 004, removed in spec
008 because the brief does not ask for it. The code is retrievable from git: the
last commit that changed those files is `59650c7`, so
`git show 59650c7:ReciMate/Presentation/Library/Components/QuickFilterBar/QuickFilterBar.swift`
(also `QuickFilterBarViewModel.swift`, `FilterChipView.swift` and
`ReciMateTests/Presentation/QuickFilterBarViewModelTests.swift`). The commit that
deletes them is noted here when spec 008 lands.

## Native search tokens and suggestions

Quick filters through the search field itself instead of chips: `searchable` with
`tokens`, plus `searchSuggestions` shown when the field is tapped (iOS 16 and later;
Apple's HIG recommends tokens for common filters and pairing them with suggestions).
Vegetarian, a servings value and include/exclude ingredients ("with eggs") fit as
tokens; tokens do not enforce one servings value, so that needs code. Open risks to
test first: whether active tokens stay visible after search is dismissed, and where
the iOS 26 iPhone search field sits. On iOS 26, `searchToolbarBehavior(.minimized)`
collapses the field into a toolbar button.

## Servings ranges

The 1–2, 3–4 and 5+ buckets from the spec 003 design pass. The brief only says
"servings filter", so spec 008 filters on an exact serving count.

## Apply button and result count

Filters applied on an "Apply Filters" button, optionally showing how many recipes
match ("Apply Filters, 12 recipes"). A live count needs a count query against the
search endpoint. Spec 008 applies changes live, with no button.

## Ingredient picker

Choosing include/exclude ingredients from a list of known ingredient ids instead of
typing them. Spec 008 uses free text. A picker needs a source of known ingredients,
which the search fixture could provide.

## URL handling and path security

Check the URL path conventions and security concerns (client-side path
traversal) when building URLs from ids. Ids are trusted for the MVP; a guard
for blank, `.` and `..` ids was removed from spec 002.

## Pluralization through String Catalogs

Spec 004 builds the servings label ("1 serving", "2 servings") in the view
model, with unit tests, to keep the first screen small. The native way is a
String Catalog (`Localizable.xcstrings`) with a plural variation on a
`%lld servings` key, which also brings localization for free. Move the label
there, keeping the view model tests (they then assert the localized output).

## Dark mode

The design (spec 003) and the first screen (spec 004) are light only. Define
dark variants for the Green, Ink and Mist asset-catalog colors, check contrast
(the measured pairs in spec 003 are light-mode only), and remove the light-only
lock. Until then the app is pinned to light appearance.

## View tests: snapshot and ViewInspector

Spec 004 unit tests only the view model layer; the Library views and components
are checked by previews and a manual pass. Add automated view tests: snapshot
tests (card, chip, placeholder, the whole Library at default and large Dynamic
Type) to catch visual regressions, and ViewInspector tests for structure and
behavior (the leaf shows only for vegetarian recipes, chip taps reach their
handlers). Each needs a package or a reference-image workflow, so decide the
tools when it is scheduled. Revisit when the state, search and filter views land,
since more views make regressions more likely.

## Accessibility pass

Spec 005 made each recipe card a plain-style `Button` around a card that is one
combined accessibility element, and did not check it with VoiceOver. Do a proper
pass: confirm a card reads as a button with its title, servings and the
vegetarian mark; the Filters toolbar button reads as "Filters"; the details and
sheet placeholders announce their screen; focus order; and large Dynamic Type.
Check the card's pressed state too (the plain style removes the highlight).
Revisit when the real Details and Filters screens land.

Added from spec 006 (Recipe Details), built but not verified:
- Large Dynamic Type on Details (spec AC15): long titles and steps wrap, rows grow,
  nothing is clipped, hero and sheet overlap hold.
- The native segmented `Picker` (Ingredients / Steps) at accessibility text sizes: it
  may truncate its labels; the fix would be a menu style, a design change. Also check
  that the UIKit appearance tint (green selected segment) survives iOS 26 and Larger Text.
- VoiceOver on Details: the badge, servings line, ingredient row (name and quantity
  read together) and step row ("Step N" then the text) each read as one element; the
  back button; heading order; the hero photo is not announced.
- Contrast: step numbers white on green (5.05:1) and secondary ink on white, on a device.

## Navigation tests with ViewInspector

The views call the `AppRouter` directly (injected by initializer at the
composition root), so there is no view model seam to unit test navigation. Add
ViewInspector tests that build a view with a real `AppRouter`, tap the card or
the filter button, and assert `router.path` or `router.sheet`. Also unit test the
router itself (push, pop, pop to root, present, dismiss). If the view tests prove
awkward, fall back to injecting the router into the view models. Part of the
wider view tests item above, so pick the package once for both.

## Formatting benchmark (kept as a check)

Spec 004 chose "format each recipe once, in one mapper" from a benchmark, not
from memory. The script and the full results are checked in:
[`formatting-benchmark.swift`](../specs/004-recipe-library/investigations/formatting-benchmark.swift),
explained in [investigation 1](../specs/004-recipe-library/investigations.md).
Re-run it when the formatting changes, mainly when the servings label moves to
a String Catalog. What it is: a standalone Swift file compiled with
`swiftc -O`, mimicking `RecipePreview` and a card view-data struct, using
`ContinuousClock` over several rounds and reporting the median, with a checksum
so the optimizer cannot drop the work. It times three things for a servings
filter change to 3-4, at 9, 1,000 and 100,000 recipes:

- remap everything, then filter
- filter, then remap only the survivors
- map once, then filter the cached view data

It runs once with cheap `"\(n) servings"` formatting and once with
`String(localized:)`, and also compares a full card rebuild with relabeling a
single property, and an `Equatable` diff of 100,000 cards where one changed.

Result on an M1 Pro, Swift 6.3.2, `-O`: with cheap formatting every option is
under 1 µs at 9 recipes. With `String(localized:)` at 9 recipes: remap all 80 µs,
survivors only 27 µs, cached 0.7 µs; at 100,000 recipes 947 ms, 312 ms and 8 ms.
A full card rebuild is 85 ns against 4 ns for one label, so per-property
formatters buy nothing; the number of formatter calls is what matters.
Limits: it measures mapping and diffing only, not SwiftUI's own body work, and
it ran on a Mac, not a device.

## Library scroll performance: `ScrollView` + `LazyVGrid`

Spec 004 builds the Library grid as a `ScrollView` with a `LazyVGrid` (an
adaptive two-column grid, which `List` cannot do). Check that it holds up at
150 to 200 recipes before the data grows.

What is known. Apple documents that a lazy grid creates its items "only as
needed" ([`LazyVGrid`](https://developer.apple.com/documentation/swiftui/lazyvgrid)),
and that you should start with the eager container and move to a lazy one when
profiling shows a gain ([Creating performant scrollable
stacks](https://developer.apple.com/documentation/swiftui/creating-performant-scrollable-stacks)).
Apple does not document whether lazy views are released once they scroll off
screen. Developer reports say it differs by OS version (released on iOS 18 and
later, kept on iOS 17; see the [forum
thread](https://developer.apple.com/forums/thread/775204)), and that
`@State` held inside cells and `AsyncImage` in large grids are the usual causes
of growth. `UICollectionView` still recycles more predictably at very large
sizes (1,000 or more items, fast scrolling). The reports are forum and blog
evidence, not measurements of this app.

What to do:

- Profile with Instruments (SwiftUI template: View Body, View Properties; plus
  Allocations) on a device, scrolling a fixture of about 200 recipes with real
  photos, up and down, at default and a large Dynamic Type size.
- Watch live card views and memory against the number scrolled past. A curve
  that keeps rising points at images or per-card state, not the grid.
- Keep cards free of `@State` and keep ids stable (they are today: cards are
  `Equatable` view data keyed by recipe id).
- Only if the numbers are bad, in this order: image downsampling or caching
  (next item), then a `UICollectionView` wrapper.

## Card photos: caching and downsampling

`RecipeImageView` uses `AsyncImage` for now, as a deliberate stand-in: it is the
fastest way to put real photos on the first screen. It is not the component to
ship with. Developers widely treat `AsyncImage` as prototype and sample-app
grade, and the limits below are why. That is community opinion: Apple's
`AsyncImage` documentation has no statement that it should not be used in
production, and no Apple engineer statement turned up in a search, so do not
cite it as Apple's position. Before iOS 27 it keeps no decoded images in memory
(a card that scrolls back into view reloads its photo), it decodes at full
resolution, it relies on the shared `URLCache`, and it offers no control over
retries, cancellation, prefetching or the placeholder beyond its phases. Photos
are the likely memory cost of the Library, not the grid.

Scoped for later: replace `AsyncImage` with a real image-loading component when
this is prepared to ship (options below).

iOS 27 changes this. At WWDC26 Apple said `AsyncImage` now supports standard
HTTP caching by default, respecting the server's cache headers, "enabled
automatically for every app" ([What's new in SwiftUI, 21:18](https://developer.apple.com/videos/play/wwdc2026/269/)).
It also adds `AsyncImage(request:)` for a custom `URLRequest` (for example a
cache policy) and the `asyncImageURLSession(_:)` modifier for a custom
`URLSession` with a larger `URLCache` ([API, iOS 27.0 and later](https://developer.apple.com/documentation/swiftui/view/asyncimageurlsession(_:))).
iOS 27 was released on September 14, 2026, so it is available now. It needs the
deployment target raised from 26.5 to 27.0, or `#available(iOS 27, *)` branches
that keep the old behavior below it. The Apple page does not say anything about
downsampling: large photos would still be decoded at full size.

Options for the replacement, to decide when preparing to ship (profiling in the
previous item says how urgent it is):

- Raise the target to iOS 27 and take the default cache, tuning the
  `URLSession` and `URLCache` only if needed. This fixes caching only; the
  other limits above remain, so it may not count as "real".
- Keep 26.5 and write a small image loader with an `NSCache` and downsampling
  (`CGImageSourceCreateThumbnailAtIndex`) to the card's pixel size.
- Ask the server for a smaller image (a size parameter or thumbnail URL) in the
  data contract, which fixes both memory and network.
- A third-party library (Kingfisher, SDWebImage) only if the above is not enough.

Also revisit the spec 004 risk about iOS 27 additions. `AsyncImage` caching is
iOS 27 only (the API page lists 27.0). The same WWDC session says classes held in
`@State` are now initialized lazily, and that this "has been back ported" to the
releases where `@Observable` appeared (iOS 17). That back-port is from a summary
of the session transcript; confirm it against Apple's documentation before
relying on it.

## Design system

Wanted for the long term, but too early. Specs 004 and 006 built a shared token
layer (spacing, typography, radius, sizing), and spec 007 removed it: with two
screens the tokens were mostly one-use names. Only `Colors.swift` stays shared.
Spacing, radius and sizing values now live in a `private extension` with a
`Constants` enum in each view, and fonts are set directly with the system text
styles.

Revisit once more screens exist and the same values keep repeating; those
repeats are the tokens. See
[the plan](../specs/007-postpone-desing-system/plan.md).
