Created: 2026-10-04
Updated: 2026-10-04

# 004 Recipe Library: discovery

First UI spec. Builds **frame 1 of [design.html](design.html), "Library, loaded"**
(narrowed from the 003 snapshot), and nothing else: the Library screen in its
loaded state, with its view model, small components and the design tokens
listed in that file. Milestone C in [ROADMAP.md](../../product/ROADMAP.md).
`design.html` is frame 1 plus only the tokens this screen needs (see
"Prototype" below).

Inputs read: specs 001-003, `product/`, the domain and API layers, the design
snapshot (frame 1 and the design-system boards), and the user's SwiftUI/MVVM
reference code.

## Decisions

1. **Name: `RecipeLibrary`.** Views and view model are `RecipeLibraryView` and
   `RecipeLibraryViewModel`. It matches the design and the roadmap flow and
   keeps the screen apart from the data layer. `RecipeList*` in `API/` and
   `Domain/` is not renamed: it names the endpoint, not the screen.
2. **New `Presentation/` layer** beside `API/` and `Domain/`:
   - `Presentation/Library/` for the screen and its view model
   - `Presentation/Library/Components/` for the small custom views (card,
     image, vegetarian mark, chip). The search field is native, not a component.
   - `Presentation/Shared/` for `ViewState`
   - `Presentation/DesignTokens/` for colors, type, spacing, radii and sizes
   - Boundary: `Presentation/` imports `Domain` only, never `API/`. The only
     place that touches `API/` is `ReciMateApp`, the composition root.
3. **Only the loaded state is built.** The view model owns a full `ViewState`
   (`idle`, `loading`, `loaded`, `error(RecipeError)`) and tests all of
   it, but the view renders only the loaded grid. While loading or after a
   failure the screen is blank. Accepted for this spec.
4. **Every component in frame 1 is built, with dummy actions.** Search field,
   the three chips (Vegetarian, Servings, Filters) and the cards are all drawn.
   Search typing and chip taps only `print`. No filtering happens (milestone D).
   Cards are not tappable (Detail is milestone E).
5. **Light mode only.** The app is pinned to light appearance. Dark variants are
   in the backlog.
6. **Pluralization in the view model.** The servings label ("1 serving",
   "2 servings") is built in the mapper that builds the card view data (`RecipeCardViewData`), with unit tests. Moving
   it to a String Catalog plural variation is in the backlog.
7. **Tokens live apart from the screen, and are exactly the ones listed in
   `design.html`: all of them, and no others.** Green, Ink and Mist are
   asset-catalog colors used through Xcode's generated symbols (no
   `Color(hex:)` helper). The derived colors (ink at 66% and 8%), type roles,
   spacing, radii and sizes are small enums or extensions. Each kind sits in its
   own file in `DesignTokens/` so it ports into a design system later. Text uses
   system text styles, as the design says. A value the mock uses but the table
   omits is added to the table first (this happened with the icon sizes), not
   hardcoded in a view.
8. **State handling is a roadmap item, not backlog.** Loading, error, empty and
   no-results are mandatory. Recorded under milestone C in the roadmap: they use
   the `View+StateOverlay` pattern (overlay over a stable content view) with
   `ContentUnavailableView` for error and empty, on top of this spec's
   `ViewState`.
9. **Images:** `AsyncImage` with its phase API. A `nil` URL and a failed load
   both show the neutral placeholder tile. Two fixture photos were dead links
   (spec 003); they are replaced with working Wikimedia Commons images, so the
   failure path is shown in previews with a bad URL, not by the fixture.
10. **Grid:** `LazyVGrid` with an adaptive column (about 160pt minimum) instead of
    a fixed two columns. The card title uses `lineLimit(2, reservesSpace: true)`
    instead of the design's fixed 40pt height, so Dynamic Type works.
11. **View model:** `@MainActor @Observable final class`, injected into the view
    through `@State(initialValue:)`. The view calls `.task { await load() }`,
    and `load()` does nothing if already loaded.
12. **Navigation:** a `NavigationStack` with the "Recipes" large title, and no
    destinations yet.
13. **Two view data types: one per screen, one per small component.**
    Presentation values are named `...ViewData`: immutable structs holding
    exactly what a view shows, already formatted.
    - `RecipeCardViewData` (`Identifiable`, `Equatable`): what one card shows.
      A card that read the domain model would format in the view body.
    - `RecipeLibraryViewData` (`Equatable`): the screen's own value, holding
      the screen state (`state: ViewState`) and `cards: [RecipeCardViewData]`.
    `RecipeLibraryViewModel` exposes one `viewData`, replaced as a whole.
    Observation (evidence: [investigations.md](investigations.md),
    investigation 2): `@Observable` goes on the view model class only. It cannot be
    applied to a struct (compile error), and a struct property of an
    `@Observable` class is tracked as one property. `ViewState` is `Equatable`
    by carrying a `RecipeError` (already `Equatable`) in its error case instead
    of `any Error`; the view model maps any other thrown error to
    `.unavailable`, as the services already do.
    A static mapper (`RecipeCardViewDataMapper.map(_:)`), separate from the
    view model, builds a card once per recipe per data arrival; the view model
    only calls it and assembles the screen's view data. `@Observable` stays on
    view models, never on view data. Servings text comes from one small
    formatter, so the String Catalog move changes one function. Evidence: a
    benchmark ([investigations.md](investigations.md), investigation 1; backlog
    item "Formatting benchmark") showed that
    formatting each recipe once, not how functions are grouped, is what matters;
    at 9 recipes the difference is unmeasurable.
14. **A second, small view model for the chips.** `FilterChipsViewModel`
    (`@MainActor @Observable`) exposes `viewData: FilterChipsViewData` (`chips:
    [FilterChipViewData]`, each with id, title, icon, whether it shows a
    chevron). It is owned by `RecipeLibraryViewModel`, so the parent can own the
    shared filter state in milestone D (chips and the Filters sheet are two views
    of one filter state). Search stays on the screen view model until D, when
    search text and chips feed one query. Cards, the image and the vegetarian
    mark get no view model: they only display view data. Taps and search
    changes only `print`, each marked `// TODO(milestone D): ...` naming what
    replaces it.
15. **Search is native.** `.searchable`, not a hand-built field; the design says
    not to rebuild native controls, and iOS 26 draws it as glass. Typing and
    submitting print.

## Refactors this implies

1. Delete `ContentView.swift`. `ReciMateApp` shows `RecipeLibraryView`.
2. `ReciMateApp` builds `RemoteRecipeListService(baseURL:, client: LocalRecipeAPIClient())`
   and passes the view model in. Its "no service is wired to a view yet" comment
   goes.
3. `Assets.xcassets`: set `AccentColor` to Green and add `Ink` and `Mist`.
4. Pin light appearance (project or Info setting).
5. `ROADMAP.md`: milestone C renamed "Recipe Library", spec 004 added,
   remaining states recorded. **Done.**
6. `BACKLOG.md`: "Pluralization through String Catalogs" and "Dark mode".
   **Done.**
7. Optional: the header comment of `Domain/Interfaces/RecipeListService.swift`
   says `RRecipeListService.swift`.

## Assumptions to carry into the spec

- The design's frame 1 is the visual source. The chips and search field follow
  it, and may be inert.
- `Servings` chip shows a chevron but opens nothing yet.
- 1 serving is the only singular case. `servings` is at least 1 (the API layer
  enforces it), so "0 servings" cannot occur.
- iOS 27 SwiftUI additions seen in the WWDC26 guide (lazy `@State` macro,
  `AsyncImage` HTTP caching) are not used. Our deployment target is 26.5;
  check availability with Apple's docs before relying on them.
- Contrast from spec 003 applies: Green is never body text on Mist. The
  vegetarian leaf is an icon, so green on Mist is allowed.

## Open questions

None that block the spec.

## Tests the spec should plan for

Scope: the view model layer only (view model and the `RecipeCardViewData` mapper). Views and
components are checked by previews and a manual simulator pass; snapshot and
ViewInspector tests are in the backlog.

- View model: `load()` moves `idle -> loading -> loaded` with the previews,
  `idle -> loading -> error` on a thrown `RecipeError`, and does not reload once
  loaded.
- Servings label: 1 gives "1 serving", 2 and larger give "N servings".
- Previews for every component and for the screen (the project asks for
  previews as the UI check).

## Prototype

No new directions were explored: the direction was locked in spec 003, and this
spec builds one of its frames. The only prototype work was narrowing it.

Read-only design snapshot: `specs/004-recipe-library/design.html`. It is frame 1
of the 003 snapshot (`specs/003-design-all-screens/design.html`, "Library,
loaded") plus a table of only the tokens this screen uses: Green, Ink, Mist,
White, ink at 66% and 8%; four text styles; the card radius, capsule chips and
the 4/8/12/16/20 spacing steps; the 44pt touch target, the card photo height,
the grid column minimum and three icon sizes (18, 14, 36). Left out on purpose:
separator, switch, scrim, sheet radius, Title 2, Headline and the 24 step. It is
regenerated by hand from the 003 snapshot and goes stale if that, or the live
003 canvas (the source of truth), is edited afterward.

Two things the narrowing surfaced:

- The mock puts the three chips at about 400pt wide inside a 350pt content area
  (390pt screen, 20pt gutters), so the row overflows. In SwiftUI the chips row
  is a horizontal `ScrollView` with hidden indicators.
- The card body's 10pt top padding is off the spacing scale, so SwiftUI uses 12.

