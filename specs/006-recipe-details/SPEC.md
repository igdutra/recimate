Created: 2026-10-04
Updated: 2026-10-04

# 006 Recipe Details: spec

## Context / Why

Tapping a recipe card already pushes a Details route (spec 005), but it lands on a
placeholder that prints the recipe id. This spec replaces the placeholder with the
real Recipe Details screen in its loaded state, built on the `Presentation/` layer
and the design tokens from spec 004, so milestone E has a screen to hang its error
and loading states on.

Visual reference: [design.html](design.html) (layout A is built, layout B is kept
for a swap and not built, plus the tokens and components this screen needs). Build
against it, and use no token that is not listed there. Decisions and what was
settled: [discovery.md](discovery.md).

## Requirements / What

- Tapping a recipe that has details opens a full-screen recipe page: a large photo
  at the top that runs under the status bar, with the content sheet rising over
  its bottom edge.
- The page shows, in order: a "Vegetarian" badge (only when the recipe is
  vegetarian), the title, the description, and the servings ("1 serving", "2
  servings", ...).
- Below that is a two-segment control, **Ingredients** and **Steps**, with
  Ingredients selected when the page opens. Choosing a segment swaps the content
  below it; the rest of the page stays.
- Ingredients lists each ingredient's name, with its quantity on the right when it
  has one ("200 g", "To serve"); an ingredient with no quantity shows the name
  alone.
- Steps lists the cooking steps in order, each with its step number in a circle and
  its text.
- A recipe with no photo, or whose photo fails to load, shows the neutral
  placeholder as the photo and the title stays readable.
- The back button is the system one; it floats over the photo and returns to the
  Library.
- While the recipe loads, or if loading fails (including the recipes that fail on
  purpose), the screen is blank apart from the back button. The loading, error and
  retry states are a separate piece of work (roadmap, milestone E).

## Decisions / Architecture

1. **Layout A, segmented, is built.** Layout B (single scroll) stays in
   `design.html` in full for a later swap. Rejected: building both behind a switch
   (dead code in the app); building B (discovery decision).
2. **Native navigation back button, no custom one.** The mock's floating circle is
   not drawn. Rejected: a custom back button (discovery decision; the system draws
   a glass one over photos).
3. **Loaded state only.** The view model owns a full `ViewState` (`loading`,
   `loaded`, `error(RecipeError)`) and is tested for all of it; the view renders
   only the loaded page. No `idle`. Loading, error with Try Again and the no-image
   hero are roadmap items under milestone E, not backlog.
4. **Names:** `RecipeDetailsView`, `RecipeDetailsViewModel`,
   `RecipeDetailsViewData`. The placeholder `RecipeDetailsView` is replaced in
   place, in `Presentation/Details/`.
5. **One screen view model, no component view models.** `RecipeDetailsViewModel`
   (`@MainActor @Observable final class`) takes the `recipeID` and a
   `RecipeDetailsService`, and exposes one `viewData: RecipeDetailsViewData`,
   replaced as a whole. `@Observable` stays on the view model, never on view data.
6. **View data, as in 004.** Immutable, `Equatable`, already formatted:
   - `RecipeDetailsViewData`: `state: ViewState` and `content:
     RecipeDetailsContentViewData?` (nil until loaded).
   - `RecipeDetailsContentViewData`: title, summary, servings label, vegetarian
     flag, image URL, `ingredients: [IngredientRowViewData]`, `steps:
     [StepRowViewData]`.
   - `IngredientRowViewData` (`Identifiable`: id, name, `quantity: String?`) and
     `StepRowViewData` (`Identifiable`: id is the step number, number, text).
   A static `makeContent(from:)` on the view model builds the content once per
   load, tested with it. The types sit in the file of the view that shows them.
7. **Segment selection is view-local `@State`**, not view model state: pure UI, no
   logic. A native `Picker` with `.segmented` style; iOS 26 draws it, so it will
   not match the mock's green-filled segment. Rejected: view model state; a custom
   control.
8. **The hero reuses `RecipeImageView`.** Its height and placeholder icon size
   become parameters (the card passes 140 and 36, so the card does not change). The
   hero passes the hero height and the same icon size. It keeps all four photo
   phases (loading spinner, loaded, failed, nil URL).
9. **The servings label is shared.** The Library's private `servingsLabel` moves to
   a small `ServingsLabelFormatter` in `Presentation/Shared/`, used by the Library
   card mapper and the details mapper. Its own tests are added; the Library's card test stays as the wiring check. Rejected: a second
   copy (two places to change when the String Catalog plural variation lands).
10. **Vegetarian badge is a new small view** (white text on green, capsule, leaf
    icon). `VegetarianMarkView` stays the icon-only mark on the card. Servings
    line, ingredient row and step row are small private views in the Details file.
11. **Composition by factory, constructor injection.** `ReciMateApp` builds a
    `RemoteRecipeDetailsService(baseURL:, client: LocalRecipeAPIClient())` and hands
    `RootView` a `makeDetailsViewModel: (String) -> RecipeDetailsViewModel`.
    `RootView`'s `.details(recipeID:)` destination calls it and passes the result to
    `RecipeDetailsView`. No `@Environment`; `Presentation/` never imports `API/`.
12. **Tokens: every token in `design.html`'s tables that is new, and no others**,
    one kind per file in `DesignTokens/`. Layout A's and layout B's tokens are both
    added, so a swap needs no token work; the ones only B uses are commented as
    such. Off-scale values from the mock map to the scale (6 to 8, 14 to 12, 28
    section gap to 24).
13. **Hero under the status bar.** The hero ignores the top safe area; the nav bar
    is transparent so the system back button floats over the photo. The content
    sheet has a 28pt top radius and overlaps the hero by 28pt.

## Approach / How

Files (the Xcode project uses synchronized groups, so no project edit is needed):

```
ReciMate/Presentation/
  Shared/ServingsLabelFormatter.swift                       (new; moved out of the Library view model)
  DesignTokens/Colors.swift, Typography.swift, Spacing.swift, Radius.swift,
               Sizing.swift                                  (additions only)
  Details/RecipeDetailsView.swift                            (replaced; view data types and components inside)
  Details/RecipeDetailsViewModel.swift                       (new)
  Library/Components/RecipeCard/RecipeImageView.swift        (height and icon size parameters)
  Library/Components/RecipeCard/RecipeCardView.swift         (passes today's values)
  Library/RecipeLibraryViewModel.swift                       (uses the shared formatter)
  _DevelopmentAssets/PreviewRecipeDetailsService.swift       (new, DEBUG only)
  _DevelopmentAssets/RecipeDetails+PreviewSamples.swift      (new, DEBUG only)
  RootView.swift                                             (takes the factory)
ReciMate/ReciMateApp.swift                                   (builds the details service and factory)
ReciMateTests/Presentation/
  RecipeDetailsViewModelTests.swift, ServingsLabelFormatterTests.swift      (new)
  Helpers/RecipeDetailsServiceSpy.swift                                      (new, same pattern as RecipeListServiceSpy)
```

- `RecipeDetailsViewModel.load()` mirrors the Library's: starts `.loading`, returns
  at once if loaded or a load is in flight (a private `isLoadInFlight` flag),
  re-runs after an error, maps any non-`RecipeError` to `.unavailable`, and does not
  special-case cancellation (backlog, "Cancellation handling"). On success it sets
  `.loaded` with the content; on failure it sets `.error` and keeps `content` nil.
- `RecipeDetailsView` takes its view model in `init` and keeps it in
  `@State(initialValue:)`. `.task { await viewModel.load() }` sits on a `ZStack`
  that holds the loaded page (the same reason and the same `TODO` as the Library:
  an empty `Group` gives `.task` nothing to attach to; removed when the state
  overlay lands).
- The loaded page is a `ScrollView` of a `VStack`: the hero, then the content sheet
  (white, 28pt top radius, pulled up by the overlap). The sheet holds badge, title,
  summary, servings line, the `Picker`, and the selected list. Text uses the new
  tokens; summary and quantity use `inkSecondary`; step numbers sit in Green
  circles with white text (5.05:1); Green is never text on Mist.
- Ingredient rows have a minimum height (so Dynamic Type can grow them), name left
  and quantity right; a nil quantity shows no right-hand text. Step rows show the
  domain `step` as the number, not the array index.
- Navigation bar: inline title display mode with the bar background hidden, so
  nothing but the system back button shows over the hero.
- Previews: one per component (badge, ingredient row, step row, servings line, hero
  variants), and the screen with a preview service (loaded, long title and long
  step, no image, large Dynamic Type). The local-client screen preview lives in
  `ReciMateApp.swift` (it builds an `API/` type), as in 004. Previews must not use
  the network: `PreviewImage.fileURL` for a loaded photo.
- Tests (`ReciMateTests/`, Swift Testing, `@MainActor`, `.hangGuard`) use a
  `RecipeDetailsServiceSpy` built on `ServiceSpy` and the existing `RecipeDetails`
  fixtures, written to the conventions above.
- Code style: descriptive names everywhere, including previews and tests.

### Conventions to mirror (one code base)

Nothing here is new: this screen is written the way spec 004's Library was, so the
two read as one code base. Where a choice below says "as in the Library", the
Library file is the reference to open, not this list.

Views (`RecipeLibraryView`, `QuickFilterBar`, `FilterChipView`, `RecipeCardView`):
- A view's view data struct sits above it in the same file, `Equatable` (and
  `Identifiable` where it is listed), immutable `let` fields, one doc line on what
  it shows. A static mapper lives on the view model under `// MARK: - Mapping`.
- A screen takes its view model in `init` and holds it with
  `_viewModel = State(initialValue: viewModel)`; a component takes plain view data
  and closures and knows no view model. Splitting a `body` is done with
  `private struct` subviews at file scope (like `RecipeGrid`) or small
  `private var` sections (like `details` in the card), never one long `body`.
- Doc comments (`///`) on types and on anything whose reason is not obvious (why a
  `ZStack`, why a flag exists), in the Library's plain, reason-first voice.
- Every view file ends with `// MARK: - Preview` followed by an `#if DEBUG` block
  of named `#Preview("...")`s. Previews never touch the network (`PreviewImage`).
- Tokens only (`Spacing`, `Typography`, `Sizing`, `Radius`, `Color.ink` ...); the
  card's `.accessibilityElement(children: .combine)` and `accessibilityLabel` habit
  is kept for the new rows and badge.

View models (`RecipeLibraryViewModel`, `QuickFilterBarViewModel`):
- `@MainActor @Observable final class`, `private(set) var viewData`,
  `@ObservationIgnored private let service`, a private `isLoadInFlight` flag, a
  doc comment on `load()` saying what it skips and what it does with errors.
- Same error mapping and the same "not special-cased cancellation" note.

Development assets (`_DevelopmentAssets/`):
- Every file starts with the folder's standing `// DEVELOPMENT ASSETS` comment and
  is wrapped in `#if DEBUG`; only `#Preview` blocks reference them.
- Samples come as `RecipeDetails.previewSamples` (one list that covers every case:
  a vegetarian and a non-vegetarian recipe, a long title and a long step, an
  ingredient with no quantity, a photo that loads, a failing one and none), and the
  view data samples are built through the production
  `RecipeDetailsViewModel.makeContent(from:)`, like `RecipeCardViewData.previewSamples`,
  so a preview cannot drift from the app. `PreviewRecipeDetailsService` mirrors
  `PreviewRecipeListService` (an `init` with a default sample).

Tests (`RecipeLibraryViewModelTests`, `RecipeListServiceTests`):
- `@Suite(.hangGuard) @MainActor struct <Name>Tests`; sections under
  `// MARK: -` headings (Initial state, Happy path, Failure modes, Repeated loads,
  Mapping); test names read `subject_condition_outcome` (`load_onSuccess_...`,
  `makeContent_carriesVegetarianFlag`); tables use `@Test(arguments:)`.
- The suite ends with `// MARK: - Helpers` and a `private extension <Name>Tests`
  holding `typealias SUTBundle`, `makeSUT()`, `startLoad(of:on:expectedRequestCount:)`
  and the two `load(_:on:...)` helpers, copied in shape from the Library suite. Each
  test starts `let (sut, spy) = makeSUT()`.
- The spy is `RecipeDetailsServiceSpy`, shaped exactly like `RecipeListServiceSpy`
  (`ServiceSpy<String, RecipeDetails>` inside, `requestCount`, `waitUntilRequested`,
  `complete`, `fail`, `failPendingRequests`, `@MainActor func loadRecipe(id:)`).
  It also lets a test assert the id the service was asked for.
- Data comes from the existing fixtures in `ReciMateTests/Fixtures/`: named recipes
  (`RecipeDetails.petitGateau`, `.lemonHerbChicken`, `Ingredient.eggs`, `.salt` for
  no quantity) for "a recipe", and `.fixture(...)` overriding only the field that is
  the point of the test (`RecipeDetails.fixture(servings: 1)`). New fixtures are
  added there, in the same two sections (`// MARK: - Named recipes`, `// MARK:
  - Factory`), only when a case is missing (for example instructions given out of
  order), never inline in a test.
- No sleeps and no `Task.sleep`; waiting is the spy's bounded `Task.yield()` loop.
  Descriptive names in tests and previews too (global rule).

The one deliberate difference: the servings label is a shared
`ServingsLabelFormatter` instead of a private static on the view model, because two
screens now need it (Decision 9).

## Out of Scope

- Loading, error (with Try Again) and no-image hero states, `View+StateOverlay` and
  `ContentUnavailableView` (roadmap, milestone E).
- Layout B (single scroll) in code; it stays in the design snapshot only.
- A custom back button, share, favorites, scaling quantities by servings, prep or
  cook time (spec 003 dropped them).
- Dark mode (backlog), String Catalog plurals (backlog), localization.
- View tests of any kind: snapshot, ViewInspector and UI tests (backlog). Only the
  view model layer and the servings formatter are unit tested.
- Pull to refresh, share sheet, a stretchy hero on overscroll.
- **Accessibility verification (moved to the backlog, "Accessibility pass"):** large
  Dynamic Type behavior (AC15), the segmented `Picker` truncating at accessibility
  sizes, and how the badge, servings line, ingredient rows and step rows read in
  VoiceOver. The code keeps the card's `.accessibilityElement(children: .combine)`
  and label habit and the Dynamic Type previews are built; checking them is the
  backlog item.

## Steps

1. Tokens: add the new tokens from `design.html` to `Colors` (separator), `Typography`
   (title, section title, body roles, servings, badge label, step number), `Spacing`
   (24), `Radius` (28 body sheet), `Sizing` (hero overlap, hero heights 280 and 320,
   ingredient row minimums 48 and 52, step number 28, icon medium 20). Build.
2. Move the servings label: write `ServingsLabelFormatterTests` (1, 2, 5, as
   `@Test(arguments:)`), add `ServingsLabelFormatter`, switch `RecipeLibraryViewModel`
   to it. The Library's `makeCard_formatsServingsLabel` stays: it now proves the card
   mapper is wired to the formatter. Run `RecipeLibraryViewModelTests` and the new
   suite.
3. `RecipeDetailsServiceSpy`, then `RecipeDetailsViewModelTests` (starts loading with
   no content; `loading -> loaded` with content; `loading -> error` on a
   `RecipeError`; a non-`RecipeError` becomes `.unavailable`; second `load()` does
   not call the service again, in flight or loaded; retry after an error calls it
   again; mapper: title, summary, servings label, vegetarian flag, image URL;
   ingredients keep order and a nil quantity; steps keep their step numbers and
   order; empty ingredients and steps map to empty lists), then
   `RecipeDetailsViewModel` and the view data types. Run that suite.
4. `RecipeImageView` gets `height` and `placeholderIconSize`; `RecipeCardView` passes
   140 and 36. Update the image previews. Build and check the Library previews have
   not changed.
5. Components with previews: vegetarian badge, servings line, ingredient row (with and
   without quantity), step row (one-line and long).
6. `RecipeDetailsView`: hero (`RecipeImageView`), overlapping content sheet, `Picker`,
   lists, `.task`, transparent nav bar. Add the DEBUG preview service and samples;
   previews for loaded, long text, no image and a large Dynamic Type size.
7. Composition: `RootView` takes `makeDetailsViewModel`, `ReciMateApp` builds the
   details service and the factory, update the root previews, and add the
   local-client details preview in `ReciMateApp.swift`. Boot the simulator and walk
   Library to Petit Gâteau, both segments, and back.
8. Full test suite, then `implementation-notes.md` (assumptions and deviations), the
   ROADMAP row for milestone E, and the README "Code organization" line if the file
   layout changed.

Task list: yes

## Open Questions / Risks

- **Segmented or single scroll?** → Segmented ships; the single scroll stays in
  `design.html` in full for a swap (discovery).
- **Custom or native back button?** → Native; the mock's circle is only a marker.
- **Which states now?** → Loaded only; loading, error and no-image are roadmap items
  under milestone E, with a note on what changes when `View+StateOverlay` lands.
- **Is there an `idle` state?** → No; the view model starts `.loading`, as the
  Library does.
- **Where does the hero come from?** → `RecipeImageView` with parameters, not a new
  component.
- **Where does the segment choice live?** → View-local `@State`.
- **Where does the servings label live?** → Shared formatter in
  `Presentation/Shared/`.
- **How does the screen get its view model without `@Environment`?** → A factory
  closure from the composition root, called by `RootView`'s destination.
- **Hero height and the safe area:** the 280pt hero is measured from the top of the
  screen, status bar included, so it is the total height the image tile takes with
  the top safe area ignored.
- Risk: until the deferred states land, tapping a recipe with no detail file (6 of
  9) or `creamy-tomato-pasta` (malformed on purpose) opens a blank screen with a back
  button. Accepted; recorded in the roadmap.
- Risk: `RecipeImageView` gained parameters, so the Library card could shift if a
  value is wrong. Step 4 re-checks the Library previews.
- Risk: the system back button is drawn by iOS 26 over the photo; its legibility on
  a bright photo is the system's. Check on the simulator.
- Risk: ingredient ids are assumed unique within one recipe (the domain says they
  are stable across recipes); a duplicate would break the list identity. The
  fixtures have none.
- Risk: the native `Picker` at the largest accessibility text sizes may truncate its
  labels. **Moved to the backlog ("Accessibility pass")**, not checked in this spec; the
  fix, if needed, is a menu style, which would be a design change.
- Risk: `@State(initialValue:)` builds the view model when its owner is rebuilt. The
  destination closure creates a new view model per navigation, which is intended
  (one per pushed screen).

## Acceptance Criteria

- **AC1.** Tapping a recipe that has details opens a page with its photo, title,
  description and servings label, and the system back button returns to the Library.
- **AC2.** The "Vegetarian" badge shows only when the recipe is vegetarian.
- **AC3.** The page opens with Ingredients selected; choosing Steps shows the steps
  and choosing Ingredients shows the ingredients again, with the rest of the page
  unchanged.
- **AC4.** Ingredients appear in the data's order, each with its name and its
  quantity on the right; one with no quantity shows the name alone.
- **AC5.** Steps appear in step order, each with its step number (from the data) in a
  circle and its text.
- **AC6.** A `nil` image URL or a failed load shows the neutral placeholder as the
  hero, and the title stays readable.
- **AC7.** The servings label reads "1 serving" for 1 and "N servings" otherwise,
  from one shared formatter used by both the Library and Details.
- **AC8.** The view model starts `.loading` with no content, moves `loading -> loaded`
  on success and `loading -> error` when the service throws, does not call the
  service again while loaded or in flight, and calls it again after an error.
- **AC9.** The view renders only the loaded page; before loaded and after an error
  nothing but the back button is shown.
- **AC10.** The hero runs under the status bar and the content sheet overlaps it with
  a 28pt top radius, with no custom back button drawn.
- **AC11.** `RecipeImageView` takes its height and placeholder icon size as
  parameters and the Library card looks the same as before.
- **AC12.** `Presentation/` contains no reference to any type in `API/`, and no
  `@Environment(AppRouter` use.
- **AC13.** Colors, type, spacing, radii and sizes used by the new views come from
  `DesignTokens/` and the asset catalog, with no color or number literals in the
  component views.
- **AC14.** `DesignTokens/` gains every new token listed in `design.html`'s tables and
  no token that is not listed there.
- **AC15.** *(Moved to the backlog, "Accessibility pass"; not verified in this spec.)*
  The page works at a large Dynamic Type size: long titles and steps wrap, rows grow,
  nothing is clipped.
- **AC16.** Every new component and the screen have a working preview.
- **AC17.** The full `ReciMateTests` suite passes.
- **AC19.** The new code follows the Library's conventions listed under "Conventions
  to mirror": `// MARK: - Preview` and `#if DEBUG` on every preview, the
  `// MARK: - Helpers` `private extension` with `SUTBundle` and `makeSUT()` in each new
  suite, `@Suite(.hangGuard) @MainActor`, `.fixture(...)` and named fixtures from
  `ReciMateTests/Fixtures/`, the `// DEVELOPMENT ASSETS` header on every new
  `_DevelopmentAssets` file.
- **AC18.** `ROADMAP.md` lists the deferred Details states under milestone E.

## Verification

- **AC7** `scripts/test.sh ReciMateTests/ServingsLabelFormatterTests`.
- **AC8** `scripts/test.sh ReciMateTests/RecipeDetailsViewModelTests`.
- **AC4, AC5 (data side), AC2 (flag)** the mapper tests in the same suite.
- **AC1, AC3, AC6, AC9, AC10** run the app on the iPhone 17 simulator: open
  Petit Gâteau, switch segments, go back; open a recipe with no details and confirm
  a blank screen with a back button; check a recipe with a bad photo URL in a
  preview. (The large Dynamic Type repeat, AC15, is in the backlog.)
- **AC11** open the `RecipeImageView` and `RecipeCardView` previews before and after
  Step 4; run `scripts/test.sh ReciMateTests/RecipeLibraryViewModelTests`.
- **AC12** `rg "API|Remote|Local|@Environment" ReciMate/Presentation` finds no `API/`
  type and no `@Environment(AppRouter`.
- **AC13** `rg -n "Color\(|\.padding\([0-9]|cornerRadius: [0-9]|\.frame\([a-z]*: [0-9]|spacing: [0-9]" ReciMate/Presentation --glob '!DesignTokens/**'`
  finds no new literals in the Details files.
- **AC14** read `DesignTokens/` against the tables in `design.html`: one new token per
  row marked New, none extra.
- **AC16** open each preview in Xcode, or build the previews target.
- **AC17** `scripts/test.sh` (full suite, once, at the end).
- **AC18** `rg -n "Spec 006" product/ROADMAP.md` finds the milestone E entry.
- **AC19** `rg -L "MARK: - Preview" ReciMate/Presentation/Details` and the new
  component files lists none; `rg -L "MARK: - Helpers|private extension" ReciMateTests/Presentation/RecipeDetailsViewModelTests.swift ReciMateTests/Presentation/ServingsLabelFormatterTests.swift`
  lists none (the formatter suite may omit helpers if it has none, noted in the
  implementation notes); `rg -L "DEVELOPMENT ASSETS" ReciMate/Presentation/_DevelopmentAssets`
  lists none; a read-through against `RecipeLibraryViewModelTests` and
  `RecipeLibraryView` before the review step.
