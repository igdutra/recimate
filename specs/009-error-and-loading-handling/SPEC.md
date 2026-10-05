Created: 2026-10-05
Updated: 2026-10-05

# 009 Error and loading handling: spec

## Context / Why

Both screens already track where their data is (loading, loaded, error) and the view
models are tested, but neither screen draws loading or error. Details shows a blank
screen for 7 of the 9 recipes (6 have no detail file, one is malformed on purpose), and
the Library shows an empty grid while it loads or after a failed search. This spec draws
both states on both screens, with one shared overlay. It also fixes the mock data so
that only two recipes fail, on purpose and labelled as such, one for each way a detail
can fail. And because the mock now waits before answering, the search field gets a
debounce. Milestone E's shared error pass in [ROADMAP.md](../../product/ROADMAP.md);
closes E1 (error half) and E2, and takes the loading half out of the backlog. Decisions
and the research behind them: [discovery.md](discovery.md). Visual reference:
[design.html](design.html), a read-only snapshot of the eight frames (Library loading,
load failed, search failed, retrying, two no-results; Details loading and load failed).

## Requirements / What

- Opening the Library shows a spinner, centered, until the recipes arrive. The title,
  search field and Filters button are on screen the whole time.
- Opening a recipe shows a spinner, centered, until its page arrives.
- If the Library's first load fails, or a search fails, the grid is replaced by an
  error message with a Try Again button. The search field and Filters button stay
  usable, so the search can be changed instead of retried.
- Every recipe opens its page, except two that fail on purpose and say so in their
  title: "Creamy Tomato Pasta (Fails: Data)" (its detail is malformed) and
  "Beef Tacos (Fails: Not Found)" (it has no detail). Tapping either shows the error
  view, with the message for its error kind and Try Again, on the Details screen, with
  the native back button still available to leave.
- Try Again shows the spinner again, then either the content or the error again. For
  the two failing recipes it fails every time; that is expected.
- Typing in the search field, or changing a filter, does not show the spinner. The
  current recipes stay until the new result arrives.
- A search starts 0.3 seconds after the last keystroke, not on every keystroke. Text
  that differs only by leading or trailing spaces does not search again.
- A search with no matches still shows "No Results" as before.
- The mock takes one second to answer every request, so the spinner is visible when
  running the app.

## Decisions / Architecture

1. **`ContentUnavailableView` built directly, with a message per error kind.** One
   title, one symbol and a bordered "Try Again" button for every error ("Couldn't
   Load", `exclamationmark.triangle`); the message depends on the `RecipeError`:
   - `notFound`: "We couldn't find what you were looking for."
   - `invalidData`: "The data we received couldn't be read."
   - `unavailable`: "Something went wrong while loading."

   The messages fit both screens (the modifier does not know which one it covers) and
   promise nothing about the retry, so they stay true when a retry cannot help. They
   live in Presentation, as `RecipeError.errorMessage` in
   `Presentation/Shared/RecipeError+ErrorMessage.swift`; the domain type stays free of
   UI copy. `invalidData(reason:)` never shows its reason. Try Again shows for every
   kind (E2 asks for it on the failure screen); Try Again by kind stays backlog.
2. **One `stateOverlay(state:retry:)` view modifier**, in `Presentation/Shared/`. It
   hides and disables the content while loading or in error and overlays a
   `ProgressView` or the error view. An overlay, not an `if/else` around the content,
   so the content keeps its identity and scroll position.
3. **`ViewState` does not change.** Still `loading`, `loaded`, `error(RecipeError)`;
   no `idle`, no empty case, and no payload on `loaded`. The data lives next to the
   state in the view data (`cards`, `content`), so it outlives a state change: the
   Library keeps its cards during a search, and the overlay covers content that never
   leaves the hierarchy. The README records why (discovery decision 17).
4. **Details content is no longer optional.** `RecipeDetailsViewData.content` becomes
   a plain `RecipeDetailsContentViewData` with a static `.placeholder` value (blank
   texts, no rows) used while loading and after an error. The `ZStack`, the
   `if let content` and the `TODO(milestone E)` are removed. Assumption: a recipe
   the Library shows has a detail, so a missing or malformed one is a data failure
   and shows the error, not a "no detail" state.
5. **The mock waits one second before every response**, as a
   `delay: Duration = .seconds(1)` parameter on `LocalRecipeAPIClient`'s initializer.
   The mock's end-to-end tests pass `.zero`.
6. **Only a first load, or a retry, shows the spinner.** No view model change for
   this: it already keeps `loaded` during later searches, and Try Again goes through
   `load()`, which sets `.loading` first.
7. **Library modifier order:** `stateOverlay` on the `ScrollView`, before
   `.searchable`, so its `.disabled` does not reach the search field.
8. **Details drops the "Back to Recipes" button**; the native back button is enough.
9. **No animation** on state changes.
10. **Every recipe has a detail file except the two that fail on purpose.** The five
    missing files are added, copied from their catalog records (the catalog record and
    the detail file are the same JSON, as the two existing good files already are).
    `beef-tacos` keeps no file (`notFound`), `creamy-tomato-pasta` keeps its malformed
    step (`invalidData`). Their titles carry the failure in the catalog and in the
    malformed file, so a reviewer knows the error is intended.
11. **`notFound` stays.** It is a real case for `GET /recipes/{id}`: the recipe was
    removed after the list was fetched, or the id came from a stale link. Both services
    already map it, and with `beef-tacos` it is reachable in the app, not only in tests.
12. **Search text is debounced in the view model, 0.3 seconds.** A
    `searchDebounce: Duration = .milliseconds(300)` parameter on
    `RecipeLibraryViewModel`'s initializer; tests pass `.zero` unless they test the
    debounce. Only typing is debounced: filter changes are single taps and search at
    once. Debounce, not throttle: a throttle would send searches during typing for
    prefixes nobody wants; a debounce waits for a pause. It is built on the search
    task the view model already cancels (`Task.sleep`, then the search), so it needs
    no Combine and no package.
13. **Search text is trimmed before it is compared.** `didChangeSearch` stores the
    trimmed text, so "pasta" and "pasta " are one search. The endpoint already trims
    the value it sends.

## Approach / How

Fixed, existing patterns: constructor-injected view models (`@State` in the view),
views built from `viewModel.viewData`, `Presentation/` never imports `API/`, previews
under `#if DEBUG`, preview services in `_DevelopmentAssets/`, system fonts and the
shared colors, no new tokens.

**The modifier** (`Presentation/Shared/View+StateOverlay.swift`):

```swift
extension View {
    /// Covers the content with a spinner while loading, and with a
    /// `ContentUnavailableView` and a Try Again button after a failure.
    func stateOverlay(state: ViewState, retry: @escaping () -> Void) -> some View {
        let isCovered = state.isLoading || state.error != nil
        return self
            .opacity(isCovered ? 0 : 1)
            .disabled(isCovered)
            .overlay {
                if state.isLoading {
                    ProgressView()
                } else if let error = state.error {
                    ContentUnavailableView {
                        Label("Couldn't Load", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(error.errorMessage)
                    } actions: {
                        Button("Try Again", action: retry)
                            .buttonStyle(.bordered)
                    }
                }
            }
    }
}
```

The file carries a short header comment on why an overlay and not an `if/else` (the
content keeps its identity, so scroll position and view state survive loading to
loaded and loaded to error), and previews of the modifier over a plain list in
loading, error and loaded.

**Library** (`RecipeLibraryView`): `.stateOverlay(state: viewModel.viewData.state) {
Task { await viewModel.load() } }` on the `ScrollView`, ahead of `.searchable`. The
"blank unless loaded" comment and the "loading and error views are a later spec"
note go. `ContentUnavailableView.search` stays where it is, after `.searchable`.
While in error, `hasNoResults` is false (it needs `loaded`), so the two overlays never
both show.

**Search debounce** (`RecipeLibraryViewModel`):
- `init(service:searchDebounce:)`, the debounce stored. `ReciMateApp` and the previews
  take the default.
- `didChangeSearch` trims the text, returns if it equals `query.instructionText`,
  stores it and starts a debounced search. `didChangeFilters` starts an undebounced one.
- `startSearch(debounce:)` creates the search task as today, and inside it sleeps first:
  `do { try await Task.sleep(for: debounce) } catch { return }`, then
  `await runSearch(number:)`. Not `try?`: that would swallow the cancellation and
  search anyway. The next keystroke cancels the task (`beginSearch()` already does), so
  only the last text reaches the service. `load()` (first load and Try Again) does not
  wait.

**Details**:
- `RecipeDetailsViewData.content` becomes non-optional; `RecipeDetailsContentViewData`
  gains `static let placeholder`.
- `RecipeDetailsViewModel` starts with `.placeholder` content, and its two `error`
  branches set `.placeholder`; `.loading` keeps resetting to it (today `nil`).
- `RecipeDetailsView` builds `RecipeDetailsPage(content: viewModel.viewData.content)`
  directly, with `.stateOverlay(...)` and `.task` on it. The `ZStack` and the TODO go.
  Watch the overlay's centering: the page ignores the top safe area. Check it in the
  previews and the simulator.

**Mock delay** (`LocalRecipeAPIClient`): `init(bundle: Bundle = .main, delay: Duration
= .seconds(1))`, stored, and `try await Task.sleep(for: delay)` as the first line of
`data(from:)`, with a comment that it exists only to mock network latency and that a
real client has none of it. A cancelled request throws `CancellationError` from the
sleep, which the services' catch-all turns into `RecipeError.unavailable`; the Library
view model drops it anyway because the search is outdated (`isCurrent`), and on Details
it only happens when the screen is gone. `RecipeCatalogFixtureTests` builds the client
with `delay: .zero` (one test with 9 cases and one more, plus the new details test; the
default would add about 20 seconds to the suite).

**Mock data** (`API/Infrastructure/`):
- Add `sheet-pan-salmon.json`, `chickpea-curry.json`, `roasted-vegetable-couscous.json`,
  `turkey-meatballs.json` and `mushroom-risotto.json` to `RecipeDetails/`, each the
  recipe's catalog record as is, formatted like `petit-gateau.json`. The project uses
  synchronized folders, so the files join the app target on their own.
- In `recipe-catalog.json`, retitle `creamy-tomato-pasta` "Creamy Tomato Pasta (Fails:
  Data)" and `beef-tacos` "Beef Tacos (Fails: Not Found)". Same title in
  `creamy-tomato-pasta.json`. Ids do not change. Check in the simulator that the titles
  fit the card's two lines; if not, shorten the suffix and log it as a deviation.
- `LocalRecipeAPIClient`'s `#Playground` comment: `beef-tacos` is the recipe with no
  detail file (unchanged id, so the code stays).

**Preview services**: `PreviewRecipeListService` and `PreviewRecipeDetailsService` take
an `outcome` (a small `PreviewOutcome` enum in `_DevelopmentAssets/`: `.loaded`,
`.loading` which never returns, `.failed(RecipeError)`), defaulting to `.loaded` so
current previews do not change.

**Previews** (V3): Library loading, Library error, Library error with search text
filled; Details loading, Details error. The Library error cannot happen with the
bundled data, so it is reachable through previews and tests only.

**Tests**:
- `RecipeDetailsViewModelTests`: assertions that compared `content` to `nil` now compare
  to `.placeholder` (initial, loading after a reload, both error cases);
  `content != nil` after load becomes `content != .placeholder`.
- `RecipeCatalogFixtureTests` (client at `delay: .zero`): one new parameterized test
  through `LocalRecipeAPIClient` and `RemoteRecipeDetailsService`: the seven good ids
  load, `creamy-tomato-pasta` throws `invalidData`, `beef-tacos` throws `notFound`.
- `RecipeCatalogDriftTests`: the five new ids join the arguments of
  `catalog_matchesTheDetailsFile`.
- `RecipeLibraryViewModelTests`: `makeSUT` passes `searchDebounce: .zero`. New: three
  keystrokes in a row reach the service once, with the last text; with a long debounce
  (one second), nothing is requested after a few yields; text that differs only by
  spaces does not search again; a filter change is not debounced.
- `RecipeErrorMessageTests` (new): one parameterized test, each `RecipeError` case to
  its message, `invalidData` with two different reasons giving the same message.
- No other new tests: the state logic is covered already, the modifier by previews,
  and the delay by the mock's own tests running at `.zero`.

**Docs**: `product/ROADMAP.md` (status and the milestone C and E text: error and
loading are done; the "Back to Recipes" and `ZStack` notes resolved; the "6 of 9" line);
`product/BACKLOG.md` ("Loading and empty-collection states" narrowed to
empty-collection; "Cancellation handling": the local client now throws
`CancellationError` from its delay; two new items, "Try Again by error kind" and an "Accessibility pass" line that the overlay's hidden content stays in the
VoiceOver tree); `implementation-notes.md` for this spec (assumptions below). The
README's "View state" decision is already written; check it still matches the code.

## Out of Scope

- Try Again that depends on the error kind (backlog).
- Accessibility work, including hiding the covered content from VoiceOver (backlog).
- Empty-collection state, skeleton or shimmer placeholders (backlog).
- The no-image hero on Details (a separate roadmap item).
- Showing or logging the failure reason (Observability backlog).
- Cancellation work beyond spec 008 (backlog).
- A debug-only way to make the Library fail in the running app (backlog, "Forcing a
  Library failure").
- Debouncing filter changes.
- Automated view tests for the modifier (backlog, "View tests").

## Steps

1. Add `delay` to `LocalRecipeAPIClient`; pass `delay: .zero` in `RecipeCatalogFixtureTests`;
   run that suite.
2. Mock data: the five detail files and the two titles; the new details test in
   `RecipeCatalogFixtureTests` and the drift test arguments; run both suites.
3. Search debounce and trimming in `RecipeLibraryViewModel`; `makeSUT` and the new tests
   in `RecipeLibraryViewModelTests`; run that suite.
4. Make Details content non-optional: `.placeholder`, `RecipeDetailsViewData`,
   `RecipeDetailsViewModel`; update `RecipeDetailsViewModelTests`; run that suite.
5. Add `PreviewOutcome` and give both preview services an `outcome`.
6. Add `RecipeError+ErrorMessage.swift` and `RecipeErrorMessageTests`; run that suite.
   Add `View+StateOverlay.swift` with its previews.
7. Apply `stateOverlay` to the Library (before `.searchable`) and add its previews.
8. Apply `stateOverlay` to Details, remove the `ZStack` and TODO, add its previews.
9. Walk it in the simulator: the Library spinner, a search, the two failing titles fit
   their cards, `beef-tacos` and `creamy-tomato-pasta` errors and Try Again,
   `petit-gateau` and `mushroom-risotto` load, back button.
10. Update `ROADMAP.md`, `BACKLOG.md` and write `implementation-notes.md`.
11. Run the full suite once.

Task list: no

## Open Questions / Risks

- **Use the system error view or a hand-built one?** → The system
  `ContentUnavailableView`, built directly: the brief names it, and a hand-built view
  would re-create its layout and Dynamic Type handling.
- **Should Try Again show for `notFound` and `invalidData`?** → Yes, for every error
  (E2 asks for a recoverable screen with Try Again). Whether it should depend on the
  kind is backlog.
- **Does `notFound` make sense?** → Yes (decision 11), and `beef-tacos` shows it.
- **How does Details draw non-optional content before it loads?** → A `.placeholder`
  value under the overlay; not a `ViewState` case.
- **How is the loading state visible with instant local data?** → A one-second mock
  delay in `LocalRecipeAPIClient`, a parameter so the mock's tests can use `.zero`.
- **Debounce or throttle?** → Debounce (decision 12).
- **Assumptions for the notes and README:** a recipe shown in the Library has a
  detail, so a missing one is our data's fault; two recipes fail on purpose and say so
  in their titles; one message per error kind, worded for either screen; the mock's one-second wait
  applies to every request, searches included; typing waits 0.3 seconds before
  searching.
- Risk: the overlay on Details may not center on the screen, since the page ignores the
  top safe area. Checked in the previews and the simulator; if off, apply the overlay
  inside the page.
- Risk: the longer titles may not fit the card's two lines (step 9).
- Risk: with `opacity(0)` the covered content stays in the VoiceOver tree (backlog).
- Risk: after a failed search the old cards sit hidden under the error; a later
  successful search replaces them.
- Risk: while in error, typing a new search shows no spinner until its result arrives
  (the state stays `error`).

## Acceptance Criteria

- **AC1:** Opening the app shows a centered spinner while the Library loads, with the
  title, search field and Filters button visible.
- **AC2:** When the Library's load fails, the grid is replaced by the error message with
  a Try Again button, and the search field and Filters button stay usable.
- **AC3:** When a search fails, the same error shows; changing the search text or a
  filter still works.
- **AC4:** Try Again on the Library runs the current query again and shows the spinner
  first.
- **AC5:** Tapping a recipe shows a centered spinner while its page loads.
- **AC6:** Tapping "Creamy Tomato Pasta (Fails: Data)" or "Beef Tacos (Fails: Not
  Found)" shows the error message with Try Again, and the native back button returns
  to the Library. Every other recipe opens its page.
- **AC7:** Try Again on Details shows the spinner and then the error again for those
  two recipes, and the page for a recipe that loads.
- **AC8:** Typing in the search field or changing a filter does not show the spinner.
- **AC9:** A search with no matches still shows "No Results", not the error.
- **AC10:** Details no longer has an optional content, a `ZStack` or the TODO; the view
  model's content is `.placeholder` until loaded and after an error.
- **AC11:** `LocalRecipeAPIClient` waits one second before each response by default,
  with a comment saying it only mocks a network, and the mock's end-to-end tests run
  with no wait.
- **AC12:** Previews show the Library loading, error, and error with search text, and
  Details loading and error.
- **AC13:** The full test suite passes.
- **AC14:** ROADMAP and BACKLOG reflect what was built, and the implementation notes
  record the assumptions.
- **AC15:** Seven detail files load through the local client; `creamy-tomato-pasta`
  fails with `invalidData` and `beef-tacos` with `notFound`, and both titles say they
  fail.
- **AC16:** Typing searches once, 0.3 seconds after the last keystroke, with the last
  text; text that differs only by spaces does not search again; a filter change
  searches at once.
- **AC17:** The error message depends on the error kind (decision 1): Beef Tacos shows
  the `notFound` message, Creamy Tomato Pasta the `invalidData` one, and the Library
  error previews the `unavailable` one.

## Verification

- **AC10, AC13, AC15, AC16** `scripts/test.sh ReciMateTests/RecipeCatalogFixtureTests`,
  `ReciMateTests/RecipeCatalogDriftTests`, `ReciMateTests/RecipeLibraryViewModelTests`,
  `ReciMateTests/RecipeDetailsViewModelTests`, each as its step lands, then the full
  suite once at the end. Confirm the suite did not slow by about 20 seconds.
- **AC11** Read `LocalRecipeAPIClient`: the sleep, the comment, the default of one
  second. In the simulator, the spinner lasts about a second.
- **AC12, AC17** Open each preview in Xcode and look. `scripts/test.sh
  ReciMateTests/RecipeErrorMessageTests` for the mapping; in the simulator, each failing
  recipe shows its own message.
- **AC1, AC5, AC8, AC9, AC16** Simulator: launch, watch the Library spinner; type
  "ramekins" quickly (no spinner, old cards until one result), then "tofu lasagna"
  ("No Results"); tap `petit-gateau` and `mushroom-risotto` (spinner, then page).
- **AC6, AC7** Simulator: tap both failing recipes (spinner, then the error); tap Try
  Again (spinner, then the error again); tap the back button.
- **AC2, AC3, AC4** Previews only (Library error, Library error with search text); the
  bundled data cannot fail on the Library. The retry path is covered by the existing
  view model tests (`load()` runs again after an error).
- **AC14** Read the diffs of `ROADMAP.md`, `BACKLOG.md` and `implementation-notes.md`.
