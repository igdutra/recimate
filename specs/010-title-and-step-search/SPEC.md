Created: 2026-10-05
Updated: 2026-10-05

# 010 Title and step search: spec

## Context / Why

Spec 008 read S6 ("search within instruction text") literally: the Library's search
field searches cooking steps only, so typing a recipe's name ("Pet" for Petit Gâteau)
shows "No Results" while that recipe is on screen. That fails the brief's "logical and
intuitive user experience". The no-results view also never shows what was searched,
and gives search advice when only filters caused the empty result. This is the
milestone D follow-up in [ROADMAP.md](../../product/ROADMAP.md). Research and
reasoning: [discovery.md](discovery.md). Visual reference:
[design.html](design.html), a read-only snapshot of the chosen direction (B).

## Requirements / What

- The search field finds a recipe when its title or any one of its cooking steps
  contains the typed text, ignoring case, accents and surrounding spaces. "pet",
  "PET" and "gateau" all find Petit Gâteau.
- The typed text is matched as one phrase: "lemon chicken" does not find "Lemon Herb
  Chicken".
- While searching, recipes whose title matches come first, then recipes found only in
  their steps. Within each group the usual order is kept.
- A card found only in its steps shows one extra line under the servings: a small list
  icon and "Found in the steps". A card whose title matches looks exactly as it does
  today. With an empty search field, no card shows the line.
- VoiceOver reads "Found in the steps" as part of the card.
- The empty search field reads "Search titles and steps".
- When a search finds nothing:
  - with text and no filters on: "No Results for "<text>"" and "Check the spelling or
    try a new search." (the system's search message), no button.
  - with filters on and no text: "No Results" and "No recipes match these filters.",
    with a Clear Filters button.
  - with text and filters on: "No Results for "<text>"" and "No recipes match this
    search with these filters.", with a Clear Filters button.
- The text shown is the text that was actually searched, trimmed, even while the
  field already holds newer, not yet searched text.
- Clear Filters turns every filter off, keeps the search text, and searches again.
- Everything else behaves as before: the Filters sheet, loading, errors and Try Again,
  the debounce, Details.

## Decisions / Architecture

1. **One field searches titles and steps; no scope picker, no search tokens.** A
   picker and tokens were rejected in discovery (NN/g and the HIG: default to the
   broadest scope; tokens are for filter values, which the Filters sheet already does).
2. **Step-only matches carry a caption on the existing card (prototype direction B).**
   Rejected: two sections "Titles" / "In the steps" (direction A: heavier view data,
   two headers for nine recipes), a second cell type per match kind, prompt-only.
3. **The app decides "found only in the steps" on its own; the API response does not
   change.** A card is a step-only match when the searched text is non-blank and
   `SearchTextMatching.text(title, contains: searchedText)` is false. Same function the
   fake server uses, so the two cannot disagree here. Assumption, documented in code:
   a real backend with its own matching would have to return the match location.
4. **The endpoint gains `q=<text>` (title or any step) and keeps `instructions=<text>`
   (steps only) exactly as S6 says.** Both may be sent; each is one more AND condition.
   The field sends `q`. `instructions` stays for the API, not used by the UI.
5. **The fake server ranks: title matches first, only when `q` is present.** A stable
   partition of the filtered results; catalog order inside each group. With no `q`
   (including when only `instructions` is sent) the order is the catalog's, as today.
6. **Match rule: the existing phrase "contains"** (`SearchTextMatching`). Multi-word
   matching is in the backlog.
7. **No-results takes the searched text and filter state from the presented result,
   not from the live field or live filters.** New view data: `searchedText` and
   `searchedWithFilters`, captured from the query that produced the cards. Three cases
   (table in Requirements). The modifier-order comment in `RecipeLibraryView` is
   corrected: with explicit text, order no longer matters.
8. **Uneven card rows are accepted.** A caption card is one line taller; titles come
   first, so at most one row per search mixes the two. No reserved empty line.
9. **Prompt "Search titles and steps"** (was "Search instructions").

## Approach / How

Fixed, to respect: Swift 6, `@Observable` view models with `private(set) var viewData`,
view data in the view's file, mapping as `static` functions on the view model, router
injected through initializers, Swift Testing, `ContentUnavailableView`, descriptive
names (no single-letter or abbreviated names anywhere, tests included). Read
`RecipeLibraryViewModel.swift`, `RecipeLibraryView.swift` and their tests before
editing: the search-number, debounce and cancellation logic must not change.

**Domain, `ReciMate/Domain/RecipeSearchQuery.swift`**
- Add `var searchText: String` (default `""`), documented as "Matched against the
  title and every cooking step (the search field). Not a filter." Add it to `init` as
  the first parameter, before `instructionText`, so call sites read in field order.
- Keep `instructionText`; update its doc: "Matched against the cooking steps only (S6,
  the `instructions` query item). Not used by the UI."
- `activeFilterCount`, `hasFilters`, `resetFilters()`: unchanged. Neither text counts
  as a filter and `resetFilters()` keeps both. Update the type's doc comment.

**API, `ReciMate/API/RecipeEndpoint.swift`**
- Split `listURL(for:baseURL:)` in two: a `private static func queryItems(for query:
  RecipeSearchQuery) -> [URLQueryItem]` that builds the items in today's order
  (`vegetarian`, `servings`, `include`…, `exclude`…, `instructions`) plus the new
  `URLQueryItem(name: "q", value:)` for the trimmed, non-blank `searchText`, last; and
  `listURL`, which returns `collectionURL` when the items are empty and
  `collectionURL.appending(queryItems: items)` otherwise.
- `URL.appending(queryItems:)` (iOS 16+) replaces the `URLComponents` round trip: it
  is the current Foundation API, non-optional (the `guard var components` and the
  `?? collectionURL` fallback go away), and checked to encode exactly as
  `URLComponents.queryItems` did (spaces, `&`, accents, repeated items in order).
  Keep the empty check: with an empty array it leaves a trailing `?`. Keep the doc
  comment's `+` limitation: `appending(queryItems:)` also leaves `+` as is.
- Update the `list` case's doc comment to list `q=<text>`. Every existing
  `RecipeEndpointTests` expectation must pass unchanged; it is the proof the
  encoding did not move.

**API mock, `ReciMate/API/Infrastructure/LocalRecipeSearchServer.swift`**
- `query(from:)`: read `searchText` from `values(named: "q").first ?? ""`.
- `CatalogRecipe.matches(_:)`: when the folded `searchText` is non-empty, require
  `SearchTextMatching.text(preview.title, contains:)` or any step containing it.
- `response(for:)`: after filtering, when the folded `searchText` is non-empty, order
  title matches first, then the rest, each in catalog order (stable; e.g. filter twice
  and concatenate). Expose a `matchesTitle(_ text: String) -> Bool` on `CatalogRecipe`
  for this.
- Doc comment's matching rules: add the `q` rule and the ordering rule.

**Presentation, `ReciMate/Presentation/Library/RecipeCardView.swift`**
- `RecipeCardViewData` gains `let isStepOnlyMatch: Bool`.
- In `details`, under the servings `HStack`, when `isStepOnlyMatch`: an `HStack` with
  `Image(systemName: "list.bullet")` (footnote size, `Color.accentColor`) and
  `Text("Found in the steps")` (`.footnote`, `Color.inkSecondary`). It stays inside the
  card's `.accessibilityElement(children: .combine)`; hide the image from
  accessibility.
- Add a preview card variant with the caption.

**Presentation, `ReciMate/Presentation/Library/RecipeLibraryViewModel.swift`**
- `didChangeSearch(_:)`: compare with and write `query.searchText` (was
  `instructionText`).
- `runSearch(number:)`: capture `let searchedQuery = query` before the `await`; build
  the presented cards with `makeCard(from:searchedText: searchedQuery.searchText)` and
  the view data's `searchedText` / `searchedWithFilters` from `searchedQuery`.
- `makeViewData`: every other update (loading, error, filter change before its result)
  carries the current `viewData.searchedText` and `viewData.searchedWithFilters`
  unchanged. Only a presented result sets them.
- `static func makeCard(from preview: RecipePreview, searchedText: String = "")`: sets
  `isStepOnlyMatch` per Decision 3. The default keeps
  `RecipeCardViewData.previewSamples` compiling.
- New `func clearFilters()`: calls `filtersViewModel.reset()` (its `onChange` already
  runs the search; the search text is kept).

**Presentation, `ReciMate/Presentation/Library/RecipeLibraryView.swift`**
- `RecipeLibraryViewData` gains `let searchedText: String` and
  `let searchedWithFilters: Bool`, plus a computed `noResultsCause: NoResultsCause?`:
  `nil` unless `hasNoResults`; then `.text` (text, no filters), `.filters` (filters, no
  text) or `.textAndFilters`. Declare `enum NoResultsCause: Equatable { case text,
  filters, textAndFilters }` next to it. An empty result with neither text nor
  filters can only come from an empty catalog (the empty-collection state, out of
  the brief, see BACKLOG). It counts as `.text`, and `NoResultsView` shows the bare
  `ContentUnavailableView.search` when `searchedText` is empty, so it keeps showing
  "No Results" as today. Say so in a code comment.
- Keep `hasNoResults` as is (existing tests use it).
- Replace the no-results overlay with a private `NoResultsView(cause:searchedText:
  clearFilters:)`:
  - `.text`: `ContentUnavailableView.search(text: searchedText)`, or the bare
    `ContentUnavailableView.search` when `searchedText` is empty (empty catalog only).
  - `.filters`: `ContentUnavailableView { Label("No Results", systemImage:
    "magnifyingglass") } description: { Text("No recipes match these filters.") }
    actions: { Button("Clear Filters", action: clearFilters) }`.
  - `.textAndFilters`: same, with `Label("No Results for \"\(searchedText)\"", …)` and
    "No recipes match this search with these filters." Use the typographic quotes the
    system uses (“ ”).
  - The button style matches the Try Again button in `View+StateOverlay.swift`.
- `.searchable(text: $searchText, prompt: "Search titles and steps")`.
- Rewrite the comment above the overlay: the text now comes from the view data, so
  the overlay's position relative to `.searchable` does not matter.
- Previews: the field's initial `searchText` does not reach the view model
  (`onChange` does not fire for the initial value). Previews that need searched text
  must also call `viewModel.didChangeSearch(<text>)` in `configure`. Add or update:
  "Library, searching roast" (a couscous-like title match plus two step-only samples;
  build the preview recipes so the title rule gives one title match and two captions),
  the three no-results cases, and the large Dynamic Type preview with captions.

**Docs**
- `specs/010-title-and-step-search/implementation-notes.md` (new, same shape as spec
  009's): the decisions above that the code carries, the fixture titles matching
  "fails" / "data" (harmless), and any deviation.
- `product/ROADMAP.md`: the milestone D follow-up bullet names spec 010 and its
  status; the D row in the milestone table lists 010.
- `product/BACKLOG.md`: "Search by title / description": title search done in spec
  010; description search still backlog.
- `README.md`: the Architecture decisions item for this change already exists (added
  in discovery). Check it still matches what was built; fix only what drifted. The
  intro's "instruction search" becomes "title and instruction search".

**Tests** (Swift Testing, extend the existing files)
- `ReciMateTests/Domain/RecipeSearchQueryTests.swift`: `resetFilters()` keeps
  `searchText`; `searchText` does not count as a filter.
- `ReciMateTests/API/RecipeEndpointTests.swift`: `searchText` encodes as `?q=`; blank
  `searchText` is dropped; `q` and `instructions` both present.
- `ReciMateTests/API/Mock/LocalRecipeSearchServerTests.swift`: add `searchText` to the
  round-trip arguments; `q` matching (title only, step only, neither, case and accent
  on titles); title-first order with a catalog where a step match comes before a title
  match in catalog order; `instructions` alone keeps catalog order; `q` and
  `instructions` together are AND. Extend the small test catalog if needed (keep
  existing expectations passing).
- `ReciMateTests/API/Mock/RecipeCatalogFixtureTests.swift`, real catalog:
  `q` "roast" → `["roasted-vegetable-couscous", "lemon-herb-chicken",
  "sheet-pan-salmon"]`; `instructions` "roast" → `["lemon-herb-chicken",
  "sheet-pan-salmon", "roasted-vegetable-couscous"]`; `q` "Pet" and "gateau" →
  `["petit-gateau"]`; `q` "ramekins" → `["petit-gateau"]`.
- `ReciMateTests/Presentation/RecipeLibraryViewModelTests.swift`: rename every
  `instructionText:` expectation that comes from `didChangeSearch` to `searchText:`;
  `makeCard` caption true / false / blank searched text; `searchedText` is the
  presented query's text, not a newer keystroke's; `searchedWithFilters` follows the
  presented result; the three `noResultsCause` cases and `nil` when there are results;
  `clearFilters()` resets the filters, keeps the text and searches again.

## Out of Scope

- Scope picker, search tokens, search suggestions, recent searches.
- Multi-word matching, description search, ingredient search through the field.
- A snippet of the matching step, highlighting the matched text.
- Any change to the list response shape or `RecipePreview`.
- Encoding `+` in query values (stays a documented limitation).
- Two-section results (direction A), a second card type.
- The empty-collection state.
- Changes to the Filters sheet, Details, loading or error handling.

## Steps

1. Domain: `searchText` on `RecipeSearchQuery`, docs, query tests. Run
   `RecipeSearchQueryTests`.
2. Endpoint: move to `URL.appending(queryItems:)` first and run
   `RecipeEndpointTests` with no test changes (must pass as is); then add the `q`
   query item, docs and new endpoint tests. Run `RecipeEndpointTests` again.
3. Fake server: parse `q`, match title or step, title-first order, doc comment,
   server tests. Run `LocalRecipeSearchServerTests`.
4. Fixture tests against the real catalog. Run `RecipeCatalogFixtureTests` and
   `RecipeCatalogDriftTests`.
5. Card view data and caption row in `RecipeCardView`, card preview.
6. View model: `searchText`, captured query, `makeCard(from:searchedText:)`,
   `searchedText` / `searchedWithFilters`, `clearFilters()`; view data fields and
   `noResultsCause` (including the empty-text, no-filters case as `.text`). Update and
  add tests. Run `RecipeLibraryViewModelTests`.
7. Library view: prompt, `NoResultsView` with the three cases and Clear Filters,
   corrected comment, previews.
8. Simulator check on iPhone 17: type "pet", "roast", "tofu lasagna"; turn on
   Vegetarian + 5 servings with an empty field; then type "roast" with them on; tap
   Clear Filters. Compare the "roast" screen with [design.html](design.html).
9. Docs: implementation notes, roadmap, backlog, README check.
10. Full suite: `scripts/test.sh`.

Task list: yes

## Open Questions / Risks

- **Scope picker, tokens or one field?** → One field, title or steps. Research (NN/g,
  HIG) favors the broad default; tokens duplicate the Filters sheet (backlog note).
- **How to show why a step-only match is there?** → A caption on the card (prototype
  B), chosen by the user over sections (A).
- **Phrase or each-word matching?** → Phrase, the existing `SearchTextMatching` rule;
  each-word is in the backlog. The user asked for the simple "contains".
- **Who orders title matches first?** → The fake server, only when `q` is sent:
  ranking belongs to the search engine.
- **Does the caption need an API change?** → No. The app reuses the server's matching
  function on the title it already has; the assumption is documented.
- **Which text and filters does no-results show?** → Those of the presented result,
  kept in the view data; never the live field (debounce) or live filters.
- **Keep `instructions=`?** → Yes, unchanged for S6; `q` is added beside it.
- **How should the endpoint build the growing query?** → `URL.appending(queryItems:)`,
  Foundation's current API (Apple docs, iOS 16+), over `URLComponents`, with the items
  built in their own function. Checked to encode identically; the `+` limitation and
  the empty-query check stay.
- **What shows when an empty search with no filters finds nothing (empty catalog)?**
  → The bare system "No Results", as today. Out of the brief, so behavior is kept
  rather than changed to a blank screen.
- **Reserve a caption line on every card?** → No; uneven rows accepted, at most one
  mixed row per search.
- Risk: renaming the view model's search from `instructionText` to `searchText` touches
  many existing tests; a missed one still compiles and fails. Run the whole
  `RecipeLibraryViewModelTests` suite after step 6.
- Risk: the debounce and search-number logic is easy to break while threading the
  searched query through `runSearch`. The existing cancellation tests must pass
  unchanged.
- Risk: previews show no captions or no-results text if they set only the field's
  initial text (see Approach, Previews).
- Risk: `.search(text:)` copy and quotes are the system's; on a non-English device they
  are localized while the custom cases stay English (the app is English-only).

## Acceptance Criteria

- **AC1** Typing a recipe's title, or part of it, finds that recipe, ignoring case and
  accents ("pet", "PET", "gateau" find Petit Gâteau).
- **AC2** Typing text that appears only in a recipe's steps still finds it ("ramekins"
  finds Petit Gâteau).
- **AC3** With search text, title matches are listed before step-only matches, each
  group in catalog order ("roast": Roasted Vegetable Couscous, then Lemon Herb Chicken,
  then Sheet Pan Salmon).
- **AC4** A step-only match shows "Found in the steps" with a list icon under the
  servings; a title match and every card with an empty field do not.
- **AC5** VoiceOver reads "Found in the steps" as part of a step-only card.
- **AC6** The empty search field shows "Search titles and steps".
- **AC7** No results from text alone shows "No Results for “<text>”" with the system's
  description and no button.
- **AC8** No results from filters alone shows "No Results", "No recipes match these
  filters." and a Clear Filters button.
- **AC9** No results from text and filters shows "No Results for “<text>”", "No recipes
  match this search with these filters." and a Clear Filters button.
- **AC10** The text in AC7 and AC9 is the trimmed text that produced the result, not
  newer typing that has not been searched yet.
- **AC11** Clear Filters turns every filter off, keeps the search text and shows the
  new result.
- **AC12** The endpoint accepts `q` (title or step) and still accepts `instructions`
  (steps only); together they must both match.
- **AC13** The text is matched as one phrase ("lemon chicken" does not find Lemon Herb
  Chicken).
- **AC14** Filters, loading, errors, Try Again, debounce and Details behave as before.
- **AC15** Every changed screen state has a preview: searching with captions, the three
  no-results cases, the caption card, large Dynamic Type.
- **AC16** The README, roadmap, backlog and implementation notes describe what was
  built.
- **AC17** The full test suite passes.

## Verification

- **AC1, AC2, AC3, AC13** `LocalRecipeSearchServerTests` (rules and order) and
  `RecipeCatalogFixtureTests` (real catalog: "Pet", "gateau", "ramekins", "roast",
  "lemon chicken" → none); simulator: type "pet" and "roast".
- **AC4** `RecipeLibraryViewModelTests` (`makeCard` caption cases); card preview;
  simulator "roast" compared with `design.html`.
- **AC5** Simulator with VoiceOver, or the Accessibility Inspector, on a "roast"
  step-only card.
- **AC6** Simulator: empty field.
- **AC7, AC8, AC9** `RecipeLibraryViewModelTests` (`noResultsCause`); the three
  previews; simulator: "tofu lasagna"; Vegetarian + 5 servings with an empty field;
  "roast" with those filters on.
- **AC10** `RecipeLibraryViewModelTests`: a search presented, then a newer keystroke
  before its result; `searchedText` stays the presented one.
- **AC11** `RecipeLibraryViewModelTests` (`clearFilters()`); simulator: tap Clear
  Filters.
- **AC12** `RecipeEndpointTests`, `LocalRecipeSearchServerTests` (round trip, AND).
- **AC14** Existing suites unchanged and passing; simulator: open a recipe, open the
  Filters sheet.
- **AC15** Open each preview in Xcode.
- **AC16** Read the four documents against the code.
- **AC17** `scripts/test.sh`, ending in `PASS`.
