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

## Search by title / description

Free-text search over recipe title and description. The brief only asks for
search within instruction text (S6), so this is extra scope. Undecided: if
wanted, it needs its own requirement ID before moving to the roadmap.

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

## Ingredient entry for include/exclude filters

How the user enters ingredients in the Filters sheet: free text, comma-separated
tokens, or a picker over known ingredient ids. A picker needs a source of known
ingredients, but list previews carry none and only 3 recipes have a details file,
so the choice depends on the data. Not scoped in the design pass (spec 003);
the design draws the rows as plain placeholders. Decide in milestone D.

## Filter apply behaviour and result count

Whether the Filters sheet applies changes live or on an "Apply Filters" button,
and whether the button shows how many recipes match ("Apply Filters, 12
recipes"). A live count needs a count query against the search endpoint. The
design pass draws a plain "Apply Filters" button with no count; the count is
optional polish.

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
