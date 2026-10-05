Created: 2026-10-04
Updated: 2026-10-04

# 008 Search + filtering: spec

## Context / Why

The Library shows every recipe but cannot search or filter them, and the brief's
core feature (a search endpoint with vegetarian, servings, include/exclude
ingredient and instruction-text filters) does not exist yet. This spec builds that
endpoint behind the data layer and the minimal UI that drives it, and removes what
earlier specs built that the brief does not ask for (the quick filter chips and the
separate list endpoint). Milestone D in [ROADMAP.md](../../product/ROADMAP.md);
closes S1 to S6, the filter side of E3, and the no-results half of E1.

Visual reference: [design.html](design.html) (approved). Decisions and the research
behind them: [discovery.html](discovery.html). Scope rule: only what the brief asks for
is built; everything else is in [BACKLOG.md](../../product/BACKLOG.md).

## Requirements / What

- The Library opens with all recipes, a search field reading "Search instructions",
  and a Filters button in the toolbar. There is no chip row.
- Typing in the search field narrows the recipes to those whose cooking instructions
  contain the typed text, ignoring case and accents. Clearing the text brings every
  recipe back. For example "ramekins" leaves only Petit Gâteau.
- The Filters button opens a sheet with: a "Vegetarian only" switch, a servings
  choice ("Any" or a number), an "Include ingredients" field and an "Exclude
  ingredients" field, plus Reset and Done.
- Changes in the sheet update the recipes behind it as they happen. Done, or
  swiping the sheet down, closes it. There is no Apply button.
- Vegetarian only keeps only vegetarian recipes. A servings number keeps only
  recipes with exactly that many servings.
- Typing an ingredient and submitting adds it as a removable chip under the field.
  A recipe must contain every included ingredient and none of the excluded ones.
  Ingredients match by name, ignoring case and accents, and a typed word matches
  inside a name ("cream" matches "Cooking cream").
- An ingredient can never be in both lists: adding it to one removes it from the
  other. Blank entries and repeats are ignored.
- Reset clears every filter and keeps the search text.
- When at least one filter is on, the Filters button looks active (prominent) and
  reads "Filters, N active" to VoiceOver. Search text alone does not make it active.
- When nothing matches, the Library shows the system "no results" screen
  (`ContentUnavailableView.search`), unchanged, whether the cause is the search
  text, the filters, or both.
- If several searches overlap (fast typing), the screen always ends up showing the
  results of the latest one.
- Opening a recipe still works as before, including the recipes that fail on
  purpose.

## Decisions / Architecture

1. **The Library loads through search; `/recipe-list` is retired.** S1 says a search
   with no filters returns everything, so the list endpoint is redundant. Removed:
   `RecipeListService` (replaced by `RecipeSearchService`), `RecipeEndpoint.list`,
   `recipe-list.json`, and the `API/List` folder's names (they become
   `API/Search`). Rejected: keeping both (two paths to the same data, dead code).
2. **Query type in the domain: `RecipeSearchQuery`.** A value type with
   `instructionText`, `onlyVegetarian`, `servings: Int?`, `includedIngredients` and
   `excludedIngredients` (ordered, no repeats), `static let empty`, a
   `hasFilters`/`activeFilterCount` (vegetarian counts 1, servings counts 1, each
   ingredient term counts 1, search text counts 0), and mutating helpers that hold
   the rules: add/remove a term (trim, drop blanks, ignore repeats ignoring case and
   accents, remove it from the opposite list) and `resetFilters()` (keeps the text).
   The sheet's rules live here so they are unit-tested without a view.
3. **Endpoint contract: `GET /recipe-search`** with optional query items, each
   omitted when unset: `vegetarian=true`, `servings=<n>`, repeated
   `include=<term>`, repeated `exclude=<term>`, `instructions=<text>`. Built with
   `URLComponents` in `RecipeEndpoint.search(query:)`; blank values are dropped
   there, in one place. Rejected: a comma-separated `include` (ambiguous when a
   term holds a comma), a POST body (the brief says query filters).
4. **The fake server filters; a new full-record fixture feeds it.** A new bundled
   `recipe-catalog.json` holds all 9 recipes in full (the former list fields plus
   ingredients and cooking instructions) and replaces `recipe-list.json` as the
   source of the search results. `LocalRecipeAPIClient` routes `recipe-search`
   requests to a separate type (`LocalRecipeSearchServer`) that parses the query
   items, filters the catalog and returns list-shaped JSON (the preview fields only,
   no ingredients or steps). Details files and the intentional E2 failure are
   untouched. `RecipePreviewDTO` and `DietaryAttributesDTO` become `Codable` so the
   server can encode its answer. Rejected: filtering on the device after loading
   everything (the brief wants an endpoint); filtering only the 3 recipes with
   details files.
5. **Matching rules (the E3 answers, all documented):**
   - Instruction text: one phrase, case- and diacritic-insensitive "contains",
     against the recipe's steps (any single step). Not word-by-word.
   - Include terms: AND. Exclude terms: a recipe is dropped if any term matches.
     Both match as case- and diacritic-insensitive "contains" on ingredient
     *names* (not ids).
   - Same term included and excluded: nothing can satisfy it, so the result is
     empty (this falls out of the rules; no error type).
   - A recipe with no ingredient or step data fails an include filter and passes an
     exclude filter (the catalog's ingredient and step arrays are optional and
     default to empty).
   - Servings is an exact match; a value below 1 matches nothing.
   - Vegetarian off is no filter, never "non-vegetarian only".
   - Results keep catalog order.
6. **Service shape: `RecipeSearchService`** (domain protocol) with
   `searchRecipes(matching: RecipeSearchQuery) async throws -> [RecipePreview]`;
   `RemoteRecipeSearchService` implements it with the existing pipeline (client,
   data mapper to DTO, mapper to domain, failures to `RecipeError`).
7. **Library view model owns the query and runs searches.** It keeps the search text
   and the filters, builds one `RecipeSearchQuery`, and runs a search on load and on
   every change. Each search takes a sequence number and only the latest one may
   present its result (so out-of-order replies and cancelled work never show), and
   the previous search task is cancelled as a courtesy. Rejected: debounce (local
   data answers at once; the README notes a network client would debounce).
8. **State during a new search:** the first load goes `.loading` then `.loaded`.
   Later searches keep `.loaded` and the old cards until the new result arrives
   (no flicker). A failure sets `.error` and a later successful search sets
   `.loaded` again. A cancelled or outdated search never sets `.error`. No error
   view is built (out of scope), so the screen shows only the title and search
   field after a failure. Loading is also not drawn.
9. **Filters sheet view model: `FiltersViewModel`, owned by the Library view
   model.** Same ownership as the old quick bar view model. It holds the filter
   part of the query, exposes view data (vegetarian flag, servings choice, the two
   term lists, whether Reset is enabled) replaced as a whole, takes the user's
   actions (toggle, choose servings, submit/remove a term, reset), applies the
   query rules, and reports every change through an `onChange` closure that the
   Library view model sets. The sheet view receives the view model and the router
   by initializer; Done calls `router.dismissSheet()`. Rejected: one big Library
   view model (the sheet logic would double it); Observation tracking between two
   models (clumsy); `@Environment` for the router (settled in spec 005).
10. **Sheet UI: native `Form`**, sections for Dietary (`Toggle`), Servings (a menu
    `Picker` labelled "Exactly": Any, 1 to 8), Include and Exclude (`TextField` plus
    removable term chips in a small wrapping layout). Navigation-bar items: Reset
    (leading, disabled when nothing is set) and Done (trailing). **Assumption:** the
    servings choices are a fixed 1 to 8 (the data holds 2 to 6); documented as a
    limitation, since a server could hold other values. Rejected: values derived
    from data (needs another source), the 1–2 / 3–4 / 5+ ranges (backlog).
11. **Library screen:** the search field, title and toolbar move out of the
    "loaded" branch so they are always present, and the grid sits under them. The
    no-results view is an overlay applied after `.searchable`, so the system view
    can read the query from the field. The toolbar button uses the prominent style
    when `activeFilterCount > 0` and an accessibility label that carries the count.
    Rejected: a custom no-results view or a Clear Filters button (system view as is,
    Reset is in the sheet).
12. **No-results wording is the system's.** With empty search text and filters on,
    the system text is whatever the OS shows; it is checked on the simulator and
    recorded, not replaced. Rejected: the generic initializer with custom text
    (gives up the out-of-the-box rule).
13. **Names:** `RecipeSearchQuery`, `RecipeSearchService`, `RemoteRecipeSearchService`,
    `RecipeSearchDataMapper`, `RecipeSearchMapper`, `RecipeSearchResultDTO`,
    `LocalRecipeSearchServer`, `FiltersViewModel`, `FiltersSheetViewData`,
    `RecipeSearchServiceSpy`, `PreviewRecipeSearchService`. Variable names are
    descriptive, no abbreviations (global rule).
14. **Mock-only tests live together and are marked for deletion.** The fake server,
    the catalog fixture and the drift check exist only because the data is mocked.
    Their tests go in one folder, `ReciMateTests/API/Mock/`
    (`LocalRecipeSearchServerTests`, `RecipeCatalogFixtureTests`,
    `RecipeCatalogDriftTests`), and each file opens with a comment saying it tests
    the mock only and is deleted, with `API/Infrastructure/` (the fake server, the
    catalog, the details fixtures, `LocalRecipeAPIClient`), when a real backend or
    database replaces the mock. The catalog's duplication of the details data is
    the reason the drift test exists: with one real source of truth it has nothing
    to check. Rejected: mixing these tests into the service tests (they would
    outlive the mock and need picking out later).

## Approach / How

**Fixed, from earlier specs:** the router is built at the composition root and
passed by initializer, views call it directly; view models are
`@MainActor @Observable`, view data is immutable, `Equatable` and replaced as a
whole; the API layer is the only place an `API/` type is built (`ReciMateApp`);
`_DevelopmentAssets` files are `#if DEBUG`; tests use Swift Testing with the
`ServiceSpy` and `hangGuard` helpers; every screen has previews.

**Removed (in the first step, its own commit):** `Presentation/Library/Components/QuickFilterBar/`
(`QuickFilterBar`, `QuickFilterBarViewModel`, `FilterChipView`),
`QuickFilterBarViewModelTests`, the `quickFilterBar` property and its test in the
Library view model, the README mention of the chips folder. The commit's hash is
then written into the backlog entry "Quick filter chips".

**Domain:** add `RecipeSearchQuery` (and its term-normalizing helper, shared with
the fake server); replace `RecipeListService.swift` with `RecipeSearchService.swift`.
Update the doc comment on `Ingredient.id` (filters match on names, not ids).

**API:** `RecipeEndpoint` swaps `.list` for `.search(query:)`; `API/List` becomes
`API/Search` with `RemoteRecipeSearchService`, `RecipeSearchDataMapper`,
`RecipeSearchMapper`, `RecipeSearchResultDTO` (same shape as before); DTOs become
`Codable`. `Infrastructure/` gains `LocalRecipeSearchServer.swift` and
`RecipeSearch/recipe-catalog.json`, and loses `RecipeList/recipe-list.json`.
`LocalRecipeAPIClient` routes by the last path component as today and sends
`recipe-search` to the server; its `#Playground` is updated to search.

**Catalog content (authoring constraints):** 9 recipes, ids, titles, servings,
vegetarian flags and image URLs exactly as in the old list. The three recipes with
details files carry the same ingredients and steps as those files (for the
intentionally malformed Creamy Tomato Pasta, the corrected step 2); the other six get
authored ingredients (several each, with plausible names) and 3 to 5 steps. The word
"ramekins" appears only in Petit Gâteau's steps. Mushroom Risotto has both a cream
and a mushroom ingredient, and Creamy Tomato Pasta has "Cooking cream", so
vegetarian + servings 2 + include "cream" + exclude "mushrooms" leaves only the pasta.

**Presentation:** `RecipeLibraryViewModel` takes a `RecipeSearchService`, owns a
`FiltersViewModel`, and exposes `RecipeLibraryViewData` (state, cards,
`activeFilterCount`, with a derived `hasNoResults`: loaded and no cards). It keeps
`didChangeSearch(_:)`; the `didSubmitSearch()` print stub is removed (typing already
searches). `FiltersSheetView` is rebuilt as described in decision 10, with a small
wrapping `Layout` for the term chips. `RootView` passes
`libraryViewModel.filtersViewModel` and the router to the sheet. `ReciMateApp` builds
`RemoteRecipeSearchService` in place of the list service. `PreviewRecipeSearchService`
replaces the preview list service.

**Tests (all Swift Testing):**
- `RecipeSearchQueryTests`: term trimming, blanks, repeats ignoring case and accents,
  moving a term between lists, the active count, `resetFilters` keeping text.
- `RecipeEndpointTests` (updated): the search URL for no filters, each filter, repeated
  include/exclude, blank values dropped, base URL with a path prefix, encoding of
  spaces, accents and `&`.
- `RecipeSearchServiceTests` (replaces the list service tests): requests the search
  URL for the query, maps in order, empty result, not found, undecodable data, other
  errors become `unavailable`.
- **Mock-only tests**, all in `ReciMateTests/API/Mock/` (see decision 14):
  - `LocalRecipeSearchServerTests`: query-item round trip (endpoint encodes, server
    parses back the same query), then one parameterized case per matching rule in
    decision 5 against a small in-test catalog.
  - `RecipeCatalogDriftTests`: the catalog's ingredients and steps equal the two
    well-formed details files (Petit Gâteau and Lemon Herb Chicken). It exists only
    because the same data sits in two mock files; a real backend has one source.
  - `RecipeCatalogFixtureTests`: the bundled catalog decodes and has the 9 ids; and
    end to end through `LocalRecipeAPIClient` and `RemoteRecipeSearchService`: empty
    query returns 9, vegetarian only returns the 5 vegetarian ids, "ramekins"
    returns Petit Gâteau, vegetarian + servings 2 returns the pasta and the
    risotto, and the frame-7 query returns only the pasta.
- **Tests that stay with a real backend** (not mock-only): `RecipeSearchQueryTests`,
  `RecipeEndpointTests`, `RecipeSearchServiceTests`, `FiltersViewModelTests` and
  `RecipeLibraryViewModelTests`.
- `RecipeLibraryViewModelTests` (updated, spy renamed `RecipeSearchServiceSpy` and
  recording each query): the first load searches with the empty query; the existing
  load, error, repeated-load and card-mapping cases still hold; typing and filter
  changes search with the right query; out-of-order replies show the latest; a
  cancelled or outdated failure is not an error; an empty result sets `hasNoResults`;
  cards stay during a re-search; an error is cleared by the next successful search;
  `activeFilterCount` follows the filters, not the text.
- `FiltersViewModelTests`: each action updates the view data, reports exactly one
  `onChange` with the new filters, conflicts move, reset enables and clears, the
  servings choices are Any and 1 to 8.

**Visual and manual checks:** previews for the Library (loaded, filtered with an
active button, no results from text, no results from filters only, large Dynamic
Type) and for the sheet (default, choices on, many long terms, large Dynamic Type);
then a simulator pass for what previews and unit tests cannot show: the system
no-results wording, the prominent toolbar button, where the search field sits on
iOS 26, and typing and chip entry in the sheet.

## Out of Scope

- The Library's error view and Try Again, including for a failed search: built with
  the Details error state in one shared pass under milestone E, with the
  `View+StateOverlay` extension (see ROADMAP). The loading view and the
  empty-collection view are backlog.
- Search tokens and suggestions, quick chips, an Apply button or result count,
  servings ranges, title or description search, an ingredient picker (all backlog).
- Debounce, the URLSession client and its cancellation mapping, pagination.
- Details screen states (milestone E), accessibility pass, dark mode, snapshot and
  ViewInspector tests.
- README sections R2 to R6 (milestone F); only the stale chips mention is fixed here.

## Steps

1. Delete the quick filter chips and their test, and remove the `quickFilterBar`
   property, its test and its use from the Library; fix the README mention. Build and
   run the Library view model tests. Commit alone ("refactor: remove quick filter
   chips"), so its hash can be recorded.
2. `RecipeSearchQuery` and its tests.
3. `RecipeEndpoint.search(query:)` replacing `.list`, with its tests (update
   `RecipeEndpointTests`).
4. Author `recipe-catalog.json`; make the DTOs `Codable`; write
   `LocalRecipeSearchServer`, route it from `LocalRecipeAPIClient`, update the
   playground; the mock-only tests in `ReciMateTests/API/Mock/` (server, drift and
   catalog fixture; the end-to-end ones come after step 5), each file headed with the
   delete-when-real-backend comment.
5. Replace the list service with `RecipeSearchService` and `RemoteRecipeSearchService`
   (rename `API/List` to `API/Search`, rename the mappers and DTO alias), delete
   `recipe-list.json` and the old service tests, add the new service tests, rename
   the spy and the preview service, and update `ReciMateApp`. Then the end-to-end
   catalog tests.
6. `FiltersViewModel` and its tests.
7. `RecipeLibraryViewModel` on search: sequence guard, state rules, owned
   `FiltersViewModel`, view data additions; update its tests.
8. Views: Library (always-present search field and toolbar, active button style,
   no-results overlay), `FiltersSheetView` with chips layout, `RootView` wiring;
   previews for every state listed above.
9. Simulator pass for the manual checks; record the system no-results wording.
10. Full test suite; greps for the retired names (`recipe-list`, `RecipeListService`,
    `QuickFilter`, `FilterChip`, `loadRecipes`).
11. `implementation-notes.md` (assumptions, the E3 table as built, deviations, and
    the list of what to delete when the mock is replaced); ROADMAP
    status for milestone D; add the chip-removal commit hash to the backlog entry
    "Quick filter chips".

Task list: yes

## Open Questions / Risks

- **What does the servings control offer?** → A fixed Any plus 1 to 8. The data holds
  2 to 6 and any bound is arbitrary; deriving values needs another data source. Logged
  as a limitation in the README notes.
- **What does the no-results screen say when only filters are on?** → Whatever the
  system view says with an empty query, used as is (decision 12); verified on the
  simulator and recorded. If it reads oddly it goes in the README limitations, not
  replaced.
- **Retire the list endpoint?** → Yes (decision 1); S1 makes it redundant and the
  catalog supersedes its fixture.
- **Where does the filter state live, and which service shape?** → In a
  `FiltersViewModel` owned by the Library view model with an `onChange` closure
  (decision 9), and one `RecipeSearchService` (decision 6).
- **Is an error view part of this spec?** → No; the state exists and is tested, the
  screen has no error view yet (decision 8). Known gap for the README.
- **Is fast-typing cancellation in scope?** → Yes, the sequence guard plus a
  cancelled previous task (decision 7); the URLSession mapping stays backlog.
- Risk: `ContentUnavailableView.search` only reads the query inside a searchable
  hierarchy; the overlay must stay after `.searchable`. Covered by the simulator pass.
- Risk: the prominent toolbar button style and the wrapping chip layout were drawn
  in HTML, not rendered in SwiftUI; they are checked in previews and on the simulator.
- Risk: moving `.searchable` out of the loaded branch changes first-launch layout
  (the field shows while loading); checked on the simulator.
- Risk: the catalog repeats ingredients and steps that two details files also hold; a
  mock-only drift test pins them equal, but a third details file would need the same
  test. The test, the catalog and the fake server are deleted when a real backend
  replaces the mock.
- Risk: renaming the list pipeline touches many files and tests at once; steps 3 to 5
  keep the build green between commits.
- Risk: a `+` inside a query value is not percent-encoded by `URLComponents`, so a
  real server could read it as a space; irrelevant to the local server, noted as a
  limitation.

## Acceptance Criteria

- **AC1** The Library opens with all 9 recipes, a search field reading "Search
  instructions", a Filters toolbar button and no chip row.
- **AC2** Typing text shows only recipes whose steps contain it, ignoring case and
  accents; "ramekins" shows only Petit Gâteau; clearing the text shows all 9 again.
- **AC3** The Filters button opens a sheet with Vegetarian only, Servings, Include
  ingredients, Exclude ingredients, Reset and Done; Done and swiping down close it.
- **AC4** Each sheet change updates the results behind it with no Apply step.
- **AC5** Vegetarian only shows exactly the 5 vegetarian recipes; servings 2 shows
  Creamy Tomato Pasta and Mushroom Risotto.
- **AC6** Vegetarian + servings 2 + include "cream" + exclude "mushrooms" shows only
  Creamy Tomato Pasta.
- **AC7** Several included ingredients must all match; any excluded match removes the
  recipe; a typed word matches inside an ingredient name, ignoring case and accents.
- **AC8** An ingredient added to one list leaves the other; blank and repeated
  entries are ignored; a query holding the same term in both lists returns nothing.
- **AC9** Reset clears all filters and keeps the search text.
- **AC10** The Filters button is prominent and labelled "Filters, N active" exactly
  when N filters are on (vegetarian 1, servings 1, each ingredient 1); search text
  alone leaves it normal.
- **AC11** When nothing matches, the system `ContentUnavailableView.search` appears,
  with no custom view or button, for search text, filters, and both.
- **AC12** With overlapping searches, the displayed results are always those of the
  latest query, and a cancelled or outdated search never shows an error.
- **AC13** A search with no filters returns every recipe, and each filter works alone
  and combined (S1 to S6).
- **AC14** A recipe with no ingredient or step data fails an include filter and
  passes an exclude filter; servings below 1 matches nothing.
- **AC15** Opening any recipe behaves as before, including the intentional failure.
- **AC16** The bundled catalog matches the two well-formed details files in
  ingredients and steps.
- **AC17** The list endpoint, its service, mappers, fixture and tests, and the quick
  chips and their tests, are gone; nothing references them.
- **AC18** Every new Library and sheet state has a preview (Library loaded, filtered,
  no results from text, no results from filters only, large Dynamic Type; sheet
  default, choices on, many long terms, large Dynamic Type).
- **AC19** The full test suite passes.
- **AC20** `implementation-notes.md` records the matching rules, the servings cap,
  the no-results wording found on the simulator and the known gaps; ROADMAP D and
  the backlog chips entry (with the removal commit hash) are updated.
- **AC21** No third-party package is added and the router is not read from
  `@Environment`.
- **AC22** Every mock-only test (fake server, catalog fixture, drift) is in
  `ReciMateTests/API/Mock/` and its file starts with a comment that it tests the mock
  and is to be deleted, with `API/Infrastructure/`, when a real backend replaces it.

## Verification

- **AC1, AC3, AC10, AC11, AC18** Previews, then a simulator walk of the running app
  (screenshots of the Library loaded, the active button, both no-results cases and
  the sheet).
- **AC2, AC5, AC6, AC13, AC16** `scripts/test.sh ReciMateTests/RecipeCatalogFixtureTests`
  (end-to-end through the local client and the service).
- **AC7, AC14** `scripts/test.sh ReciMateTests/LocalRecipeSearchServerTests`.
- **AC8, AC9, AC10 (count)** `scripts/test.sh ReciMateTests/RecipeSearchQueryTests` and
  `ReciMateTests/FiltersViewModelTests`.
- **AC4, AC12** `scripts/test.sh ReciMateTests/RecipeLibraryViewModelTests`; AC4 also
  in the simulator walk.
- **AC13 (URL side)** `scripts/test.sh ReciMateTests/RecipeEndpointTests` and
  `ReciMateTests/RecipeSearchServiceTests`.
- **AC15** The existing `RecipeDetailsServiceTests` and `RecipeDetailsViewModelTests`
  stay green; a simulator tap on a recipe with and without details.
- **AC17** `rg -n "recipe-list|RecipeListService|loadRecipes|QuickFilter|FilterChip" ReciMate ReciMateTests`
  returns nothing (outside `specs/` and `product/`), and the retired files are
  absent from `git ls-files`.
- **AC19** `scripts/test.sh` (full suite) ends with `PASS`.
- **AC20** Read the notes, ROADMAP row D and the backlog entry.
- **AC21** `rg -n "@Environment" ReciMate/Presentation` shows no router use, and
  `ReciMate.xcodeproj` lists no package references.
- **AC22** `ls ReciMateTests/API/Mock` lists the three files, and
  `rg -L "delete" ReciMateTests/API/Mock` returns nothing (each file mentions it).
