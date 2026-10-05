Created: 2026-10-05
Updated: 2026-10-05

# 009 Error and loading handling: discovery

Builds the **shared error pass** from milestone E in
[ROADMAP.md](../../product/ROADMAP.md): the Library's error state (a failed load
and a failed search) and the Details error state (the intentional failure, with
Try Again), plus the **loading state** on both, through one `View+StateOverlay`
view extension on top of the `ViewState` from spec 004. Closes E1 (error half,
Library and Details) and E2.

Inputs read: the roadmap, backlog and requirements; the brief; specs 004, 006 and
008; `ViewState`, `RecipeError`, both view models and views, the data layer's
error mapping, `RootView`, `ReciMateApp`, the preview services; Apple's
`ContentUnavailableView` documentation.

## Where things stand

- Both view models already own a full `ViewState` and are tested. `load()` re-runs
  after an error, so Try Again needs no view model work.
- Neither view renders `loading` or `error`. Library shows an empty grid; Details
  shows nothing. Of the 9 recipes, 6 have no detail file (`notFound`) and
  `creamy-tomato-pasta` is malformed on purpose (`invalidData`), so a tap on any of
  them opens a blank screen today. That is the E2 failure.
- A failed Library search keeps the old cards in `viewData` and sets `.error`. The
  search field and the Filters button live in the navigation bar, outside the
  content, so they stay on screen under an overlay.
- Nothing in the app can make the Library fail with the bundled data. Its error
  state is reachable only through previews and unit tests (V3).

## Decisions

1. **Use `ContentUnavailableView` directly, with no wrapper view.** The brief
   asks for `ContentUnavailableView` where it fits, and E1 repeats it. The system
   view already gives the layout, Dynamic Type, dark mode and VoiceOver grouping
   (label, description and actions read as one unit), and it takes the system
   background and the app's tint. A view of our own around it would add a level
   of indirection for one call site. So: `ContentUnavailableView(label:description:actions:)`
   with a `Label`, a `Text` description and a bordered Try Again button, built
   inside the modifier. `ContentUnavailableView.search` stays for no-results, as
   spec 008 built it.
2. **`stateOverlay` is a modifier on the content, with an overlay, not an
   `if/else` around it.** The content stays in the hierarchy at all times, so
   scroll position and view state survive loading to loaded and loaded to error.
   Apple's own guidance for the search case uses the same shape
   (`.overlay { if results.isEmpty { ContentUnavailableView.search } }`), and spec
   008 already does this for no-results.
3. **One message per `RecipeError` kind** (changed after the spec review; it was one
   generic message). Same title and symbol for every error; the message says what
   went wrong: `notFound` "We couldn't find what you were looking for.",
   `invalidData` "The data we received couldn't be read.", `unavailable` "Something
   went wrong while loading." With two recipes failing on purpose, one per kind
   (decision 14), the reviewer sees both, and a generic "Please try again" would be
   wrong for both: a retry fixes neither. The messages fit either screen, since the
   modifier does not know which one it covers, and promise nothing about the retry.
   They are a `RecipeError.errorMessage` extension in Presentation, so the domain
   type carries no UI copy, with a unit test. `invalidData(reason:)` never shows its
   reason to the user.
4. **Try Again is shown for every error.** E2 asks for a recoverable error screen
   with Try Again. For the intentional failure a retry fails again; the way out is
   the native back button. Whether Try Again should depend on the error kind is
   parked in the backlog.
5. **Retry is a closure on the modifier**, `retry: @escaping () -> Void`, called
   as `Task { await viewModel.load() }` at the call site. A closure is the simplest
   idiom, and there is only one action.
6. **Loading is included, as a centered `ProgressView` in the same overlay.**
   Outside the brief ([BACKLOG.md](../../product/BACKLOG.md), "Loading and
   empty-collection states"), but it costs one `else if` in a modifier that has to
   exist anyway, and without it the first frame of each screen is blank for as
   long as the load takes. Only the *loading* half moves out of the backlog. The
   empty-collection state stays there. The roadmap and backlog text are updated
   in the spec step.
7. **Only the first load shows the spinner.** The view model keeps the state
   `loaded` during later searches, so typing never flashes the spinner and the
   grid does not flicker (spec 008). Try Again goes through `load()`, which sets
   `.loading` first, so a retry does show the spinner. No new view model code.
8. **Modifier order matters on the Library.** Apply `stateOverlay` to the
   `ScrollView` *before* `.searchable`. The modifier sets `.disabled` and
   hides the content; applied after `.searchable`, it would also disable the
   search field, and a failed search could no longer be changed. The existing
   `ContentUnavailableView.search` overlay stays after `.searchable`, because the
   system view reads the query from the field.
9. **Details content stops being optional.** `RecipeDetailsViewData.content` becomes
   a non-optional `RecipeDetailsContentViewData`, with a static `.placeholder` value
   (blank texts, no rows; not a `ViewState` case, which stays `loading`, `loaded`,
   `error`) used while loading and after an error. The `ZStack`, the
   `if let content` and the `TODO(milestone E)` go: the page is always built, the
   overlay covers it, and `.task` attaches to the page itself. This matches the
   roadmap, which says both screens drop their "blank unless loaded" branch.
   **Assumption, for the notes and README:** a recipe the Library shows has a
   detail. If it does not, the fault is in the data, not the user's, so Details
   shows the error screen. It is not an empty or "no detail" state. In the mock,
   only the two recipes of decision 14 fail. The view model's `error` case clears the
   content back to `.placeholder`, as it clears it to `nil` today.
10. **Details drops the "Back to Recipes" button.** The native back button is
    on screen over the error (the toolbar background is hidden, the button is not),
    so a second path back is redundant. This was the roadmap's open choice.
11. **No animation on state changes.** The local data answers at once, so a fade
    would turn a barely visible spinner into a visible flicker.
12. **Previews and tests (V3).** A failing preview service per screen (a
    `RecipeError` it throws), so previews show: Library loading, Library error,
    Library error with a search text, Details loading, and Details error. `PreviewRecipeListService` and
    `PreviewRecipeDetailsService` gain a way to fail. Unit tests stay on the view
    models (already covered); no new logic to test. The modifier is
    covered by previews, as other views are, until the view-test backlog item.
13. **`LocalRecipeAPIClient` waits one second before every response, to simulate a
    network.** The bundled JSON answers instantly, so the loading state would
    never be visible. One second, not two (changed after the spec review): it still
    shows the spinner and halves the wait on every search. The wait is a
    `delay: Duration = .seconds(1)` parameter on
    the initializer (existing calls, `LocalRecipeAPIClient()` and
    `LocalRecipeAPIClient(bundle:)`, still compile), applied with
    `try await Task.sleep(for: delay)` at the top of `data(from:)`, with a comment
    saying it exists only to mock network latency and that a real client has none
    of it. Consequences, all accepted:
    - **The mock's end-to-end tests pass `delay: .zero`.** `RecipeCatalogFixtureTests`
      is the only test file that builds the client (one test with 9 cases and one
      more, 10 requests). On the default they would add about 20 seconds to the
      suite. The composition root and previews take the default.
    - **It applies to every request, searches included.** Typing in the search
      field shows no spinner (decision 7) but results arrive a second late (plus
      the debounce of decision 16), with the old cards on screen meanwhile. A newer
      keystroke cancels the older search, and `Task.sleep` throws
      `CancellationError`. The services' catch-all turns that into
      `RecipeError.unavailable`, so the view model never sees a cancellation; it
      drops the result anyway because the search is outdated (`isCurrent`).
    - **Previews that use the local client** ("Root, local client", "Details,
      local client") show the spinner for a second, which is the point.

14. **Only two recipes fail, on purpose, and say so in their title** (added after
    the spec review). Six of the nine recipes had no detail file, so a reviewer
    would have seen the error on 7 of 9 taps and could read it as a broken app. The
    catalog holds each recipe's full record, and for the two good detail files the
    record and the file are the same JSON, so the missing files were missing data,
    not a design. Five are added, copied from the catalog. Two fail, one per way a
    detail can fail: `creamy-tomato-pasta` keeps its malformed step 2
    (`invalidData`), titled "Creamy Tomato Pasta (Fails: Bad Data)", and
    `beef-tacos` keeps no file (`notFound`), titled "Beef Tacos (Fails: Not Found)".
    The titles change in the catalog and in the malformed file; the ids do not.
    Rejected: serving details from the catalog in the mock client, with the
    malformed file as an override. Two sources for one response and more mock code,
    to avoid five small files.
15. **`notFound` stays.** It is a real case for `GET /recipes/{id}`: the recipe was
    removed after the list was fetched, or the id came from a stale link. Both
    services already map it, and decision 14 makes it reachable in the app. On the
    Library it stays reachable only in tests and previews (a missing collection).
16. **Search text is debounced, 0.3 seconds, in the view model** (added after the
    spec review). The usual search-as-you-type handling is: cancel the search in
    flight, drop outdated replies, skip a repeated query, and wait for a pause in
    typing. Spec 008 has the first three; this adds the debounce, and the
    repeated-query check now compares trimmed text. Debounce, not throttle: a
    throttle sends a search at a fixed rate during typing, for prefixes nobody wants;
    a debounce sends one when typing pauses. Combine has both operators; here the
    debounce is a `Task.sleep` at the start of the search task the view model
    already cancels on the next keystroke, so it needs no Combine and no package. The
    interval is a `searchDebounce` parameter on the view model's initializer, so
    tests run at `.zero`. Only typing is debounced: a filter change is one tap and
    searches at once. Rejected: `.task(id: searchText)` in the view, which debounces
    the same way but keeps the logic out of the view model's tests.
17. **The data stays next to `ViewState`, not inside `loaded`** (confirmed after the
    spec review, with a search of common practice). The common alternative is
    `enum LoadingState<Value> { case idle, loading, failed(Error), loaded(Value) }`,
    as in Swift by Sundell's `AsyncContentView`. It makes states that make no sense
    impossible to write, and it suits a generic container view. But moving to
    `loading` or `failed` drops the value. The Library needs the old cards during a
    search (spec 008, no flicker) and under a failed search, and the overlay needs
    content that never leaves the hierarchy, so the payload would have to come back
    in the other cases (`loading(previous:)`). Keeping `state` and the data side by
    side in the view data costs states that make no sense being possible
    (Details in `loaded` with its placeholder content); the view models own `viewData` (`private(set)`) and
    their tests pin the combinations. Recorded in the README's architecture decisions.

## Not in scope (stays out)

- Error banners, toasts, or per-field errors.
- Empty-collection state (backlog).
- Skeleton or shimmer placeholders (backlog, "Loading and empty-collection
  states").
- No-image hero on Details (separate item in the roadmap, not an error).
- Logging the failure reason (Observability backlog).
- Cancellation work beyond what spec 008 did (backlog).
- Accessibility (backlog, "Accessibility pass"). One item to add there in the spec
  step: the modifier hides the content with `opacity(0)`, which leaves it in the
  VoiceOver tree, so it needs `.accessibilityHidden` while loading or in error.
- Try Again that depends on the `RecipeError` case (new backlog item in the spec
  step). E2 asks for Try Again on the failure screen, so it shows for every kind.
- A debug-only way to make the Library fail in the running app (backlog, "Forcing
  a Library failure"). The brief does not ask for it; previews show that state.

## Open questions

None.

## Prototype

No directions were compared: the approach was settled in the decisions above (a
system `ContentUnavailableView` and `ProgressView` in one overlay), so this round
only draws the states to react to. It starts from the spec 003 frames for loading
and error (2, 3, 4, 10, 11) and the spec 008 frames for no-results, brought up to
the current look, and adds the frames 003 did not have for search failures.

Read-only design snapshot: `specs/009-error-and-loading-handling/design.html`
(about 16 KB, no script, no images). It is written by hand from the 003 and 008
snapshots and goes stale if those change. There is no live canvas for this round.

Frames:
1. Library, loading (first load, and after Try Again).
2. Library, load failed (search field and Filters button stay).
3. Library, search failed (typed text kept, two filters active, same error). New.
4. Library, retrying a failed search (spinner, query unchanged). New.
5. Library, no results from search text (system search view, as in 008).
6. Library, no results from filters only (system search view, as in 008).
7. Details, loading (native back button, spinner).
8. Details, load failed (the intentional failure, E2).

What changed from the 003 frames: no custom 80pt badge circle (the system view
draws a plain gray symbol), no "Back to Recipes" button, no "Clear Filters" button
(the system search view has none; Reset in the sheet does it), no chips, one
generic message instead of recipe-specific wording ("Couldn't load Creamy Tomato
Pasta"). Left out: the empty-collection frame (003, frame 5), which is backlog.

What the frames show that the text did not: the failed search (frame 3) keeps the
typed text and the active Filters button, so the user can change the query or
retry; and a retry is the only time a spinner appears over a search.

## Prior art

The overlay pattern (decision 2) comes from an earlier project: a view modifier that
covers stable content with a spinner or an error, instead of an `if/else` that swaps
the root view. It follows "Demystify SwiftUI" (WWDC21) on view identity and the
`ContentUnavailableView` documentation
(https://developer.apple.com/documentation/swiftui/contentunavailableview), whose
search example has the same shape:

```swift
List { … }
    .overlay {
        if results.isEmpty {
            ContentUnavailableView.search
        }
    }
```

The code for this app is in the spec.

## Task name

`009-error-and-loading-handling` (the highest existing spec is 008). Pass it to `/spec`.
