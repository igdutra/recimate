Created: 2026-10-04
Updated: 2026-10-04

# 004 Recipe Library: spec

## Context / Why

The data layer (spec 002) and the design (spec 003) exist, but no screen does.
This spec puts the first UI on screen: the Library in its loaded state, built on
a new `Presentation/` layer with clear boundaries, so the later states, search,
filters and Detail have a pattern to follow.

Visual reference: [design.html](design.html) (frame 1 and the tokens this
screen needs). Build against it, and use no token that is not listed there.
Evidence for the view data and observation decisions:
[investigations.md](investigations.md).

## Requirements / What

- Launching the app shows a "Recipes" screen with the recipes from the bundled
  data in a grid of cards, in the order the data gives them.
- Each card shows the photo, the title (up to two lines), the servings ("1
  serving", "2 servings", ...) and a leaf mark when the recipe is vegetarian.
- A recipe with no photo, or whose photo fails to load, shows a neutral
  placeholder tile on its card.
- Above the grid there is a search field and three quick chips (Vegetarian,
  Servings, Filters). They are drawn as in the design but do not filter or open
  anything: using them only prints a message to the console.
- Tapping a card does nothing.
- While the recipes load, or if loading fails, the screen is blank (the later
  states are a separate piece of work).
- The app always looks light, whatever the device setting.

## Decisions / Architecture

1. **Names:** `RecipeLibraryView` and `RecipeLibraryViewModel`. `RecipeList*` in
   `API/` and `Domain/` is unchanged. Rejected: `RecipeList` for the screen
   (collides with the endpoint naming).
2. **Layer boundary:** `Presentation/` imports `Domain` only. `ReciMateApp` is the
   only place that builds an `API/` type.
3. **The screen's view data carries a full `ViewState`** (`idle`, `loading`,
   `loaded`, `error(RecipeError)`); the view renders only the loaded grid.
   `ViewState` is `Equatable` because its error case holds `RecipeError`, which
   already is; `any Error` cannot be `Equatable`. The view model maps any
   thrown error that is not a `RecipeError` to `.unavailable`.
   `@Observable` goes on view models only: it cannot be applied to structs, and
   a struct property of an observable class is observed as one property.
4. **Two view data types.** `RecipeLibraryViewModel` exposes a single
   `viewData: RecipeLibraryViewData`, replaced as a whole, never
   `[RecipePreview]`.
   - `RecipeLibraryViewData` is the screen's value: `state: ViewState` and
     `cards: [RecipeCardViewData]`. It is `Equatable`.
   - `RecipeCardViewData` is what one card shows: an `Identifiable, Equatable`
     struct (id, title, servings label, vegetarian flag, image URL), so SwiftUI
     can skip unchanged cards.
   A static `RecipeCardViewDataMapper.map(_ preview:)` builds a card, once per
   recipe per load. The view model calls it and assembles the screen's view
   data; it does no formatting itself. The servings
   label ("1 serving" / "N servings") comes from a small
   `ServingsLabelFormatter` the mapper uses, and is unit tested. `@Observable`
   stays on view models only. Rejected: formatting in the view body, per-property
   relabel functions (about 80 ns saved per card, see the backlog benchmark). Rejected for now: String Catalog
   plural variation (backlog).
5. **A second small view model for the chips.** `FilterChipsViewModel`
   (`@MainActor @Observable final class`) exposes `viewData:
   FilterChipsViewData`, which holds `chips: [FilterChipViewData]`.
   `FilterChipViewData` is `Identifiable, Equatable`: id (vegetarian, servings
   or filters), title, SF Symbol name, whether it shows a chevron, whether its
   icon uses the accent color. `RecipeLibraryViewModel` owns it as
   `filterChips`, so the parent can own the shared filter state in milestone D.
   Search stays on `RecipeLibraryViewModel` until D. Rejected: one view model
   per control (chips, sheet and search must share one filter state), a view
   model per card.
   Placeholders (chip taps, search typing and submit) call `print` and each
   carries a `// TODO(milestone D): ...` comment saying what replaces it:
   chip selection state, the servings range, the Filters sheet, the shared
   filter state, and the search query.
6. **Native search:** `.searchable` plus `.onSubmit(of: .search)`, not a
   hand-built field. iOS 26 draws it as glass, and the design says not to
   rebuild native controls. Typing and submitting print.
7. **Custom views:** `FilterChipView`, `RecipeCardView`, `RecipeImageView`
   (`AsyncImage` phases and the placeholder), `VegetarianMarkView`. Each is a
   small view with a preview and no knowledge of the view model.
8. **Tokens separate from the screen: every token in `design.html`'s tables,
   and no others,** in `Presentation/DesignTokens/`, one file per kind:
   - colors: `AccentColor` (Green), `Ink`, `Mist` in the asset catalog, used
     through generated symbols; derived `inkSecondary` (ink at 66%) and
     `placeholderFill` (ink at 8%) in code; White is the system background
   - `Typography`: screen title (Large Title), search text (Body), chip label
     (Subheadline, medium), card title (Subheadline, semibold), card detail
     (Footnote)
   - `Spacing`: 4, 8, 12, 16, 20
   - `Radius`: card 20; chips use a capsule
   - `Sizing`: touch target 44, card photo height 140, grid column minimum 160,
     icon sizes 18, 14 and 36
   Components read tokens, never literals. Rejected: a `Color(hex:)` helper; a
   token the mock does not use "for later".
9. **Grid:** `LazyVGrid` with an adaptive column (about 160pt minimum) rather than
   two fixed columns. Card title uses `lineLimit(2, reservesSpace: true)`.
10. **Light only,** via the `INFOPLIST_KEY_UIUserInterfaceStyle = Light` build
   setting on the app target. Dark mode is in the backlog.
11. **Injection:** the view takes its view model in `init` and keeps it in
    `@State(initialValue:)`. `.task` calls `load()`, which returns at once if
    already loaded.

## Approach / How

Folders, all new unless noted (the Xcode project uses synchronized groups, so no
project edit is needed for files):

```
ReciMate/Presentation/
  Shared/ViewState.swift
  DesignTokens/Colors.swift, Typography.swift, Spacing.swift, Radius.swift,
               Sizing.swift
  Library/RecipeLibraryView.swift
  Library/RecipeLibraryViewModel.swift
  Library/RecipeLibraryViewData.swift
  Library/RecipeCardViewData.swift
  Library/RecipeCardViewDataMapper.swift
  Library/FilterChipsViewModel.swift
  Library/FilterChipsViewData.swift
  Library/FilterChipViewData.swift
  Library/ServingsLabelFormatter.swift
  Library/Components/FilterChipView.swift, RecipeCardView.swift,
                     RecipeImageView.swift, VegetarianMarkView.swift
```

- `ViewState` is an `Equatable, Sendable` enum (`idle`, `loading`, `loaded`,
  `error(RecipeError)`) with `isLoading`, `isLoaded` and `error` helpers, adapted
  from the user's earlier code, which held `any Error`.
- `RecipeLibraryViewModel` is `@MainActor @Observable final class`. It holds
  `RecipeListService`, `let filterChips: FilterChipsViewModel` and
  `private(set) var viewData: RecipeLibraryViewData`
  (starts as `idle` with no cards). `load()`: return if `viewData.state` is
  loaded; set state `.loading`; call the service; map previews to cards; set
  state `.loaded` with the cards; on failure set state `.error`, keeping any
  cards. The dummy handlers
  (`didChangeSearch(_:)` on `RecipeLibraryViewModel`, `didTapChip(_:)` on
  `FilterChipsViewModel`) `print`, each with a `// TODO(milestone D):` comment;
  the views only forward to them.
- Cancellation: a cancelled load is not special-cased (backlog item
  "Cancellation handling"); the view model sets `.error` for anything thrown.
- `RecipeLibraryView` is a `NavigationStack` over a `ScrollView` with a chips row
  and the grid, titled "Recipes". It is split into small private subviews so no
  `body` mixes concerns.
- The chips row is a horizontal `ScrollView` (hidden indicators): the three
  chips are wider than the 350pt content area on a 390pt screen.
- The Servings chip shows a trailing chevron. The Vegetarian chip shows the leaf.
  Neither keeps a selected state.
- `Assets.xcassets`: set `AccentColor` to Green `#2E7D4F`; add `Ink`
  `#1B1F1D` and `Mist` `#EEF1EE`, universal (no dark variants).
- Text and icon colors follow the design: Ink for text, `inkSecondary` for
  secondary text, Green only for the leaf and accent. The card body uses 12pt
  padding on all sides (the mock's 10pt top is off the scale). Green on Mist is for icons
  only (contrast 4.4).
- `ReciMateApp` builds `RemoteRecipeListService(baseURL: Self.apiBaseURL,
  client: LocalRecipeAPIClient())` and `RecipeLibraryView(viewModel:)`. Its
  "no service is wired" comment is updated. `ContentView.swift` is deleted.
- Testing strategy: unit tests cover the presentation logic only, which is the
  view model and the `RecipeCardViewDataMapper` it calls (state transitions, ordering,
  servings label). Views, components and tokens have no automated tests in this
  spec; previews and a manual simulator pass are their check. Snapshot and
  ViewInspector tests for the views are in the backlog.
- Tests (`ReciMateTests/`, Swift Testing, `@MainActor`, same style as
  `RecipeListServiceTests`) use a stub `RecipeListService` and the existing
  `RecipePreview.fixture`.
- Previews: one per component, one for the screen using the local client, and
  one for the screen with a stub service.
- Code style: descriptive names everywhere, including previews and tests.

## Out of Scope

- Loading, error, empty and no-results UI, `View+StateOverlay` and
  `ContentUnavailableView` (roadmap, milestone C, next spec).
- Real search, real filtering, the Filters sheet, chip selected states (D).
- Navigation to Detail (E), pull to refresh.
- Dark mode (backlog), String Catalog pluralization (backlog), localization.
- A full design-system package; only the tokens this screen uses.
- View tests of any kind: snapshot tests, ViewInspector tests and UI tests
  (backlog). Only the view model layer is unit tested.

## Steps

1. Build the tokens and `ViewState`: asset colors, then `Colors`, `Typography`,
   `Spacing`, `Radius`, `Sizing` (one entry per row of `design.html`'s tables),
   and `Presentation/Shared/ViewState.swift`. Build.
2. Write `RecipeCardViewDataMapperTests` (1, 2, 5 servings; vegetarian flag;
   image URL passed through; id and title kept), then `RecipeCardViewData`,
   `ServingsLabelFormatter` and `RecipeCardViewDataMapper`. Run that suite.
3. Write `RecipeLibraryViewModelTests` with a stub service (loaded view data
   with cards in recipe order; `idle -> loading -> loaded`; error on `RecipeError`; second `load()`
   does not call the service again; a non-`RecipeError` thrown error becomes
   `.unavailable`; empty list loads as loaded with empty view data),
   then `RecipeLibraryViewModel`. Run that suite. Then write
   `FilterChipsViewModelTests` (three chips in order: Vegetarian, Servings,
   Filters; only Servings shows a chevron; only Vegetarian uses the accent
   icon), then `FilterChipsViewModel`, `FilterChipsViewData` and
   `FilterChipViewData`. Run that suite.
4. Components with previews: `VegetarianMarkView`, `RecipeImageView` (loaded,
   nil URL, failing URL), `RecipeCardView` (one and two line titles, with and
   without leaf), `FilterChipView` (plain, leaf, chevron).
5. `RecipeLibraryView` with `.searchable`, chips row, adaptive grid, `.task`,
   print handlers; previews (local client, stub). Check previews or the simulator
   at default and a large Dynamic Type size.
6. Wire `ReciMateApp`, delete `ContentView.swift`, set the light-only build
   setting. Boot the simulator and confirm the app shows the grid.
7. Full test suite, then `implementation-notes.md` with assumptions and any
   deviations, and set milestone C's roadmap row accordingly.

Task list: yes

## Open Questions / Risks

- **Search and chips: inert or left out?** → Built and inert, printing only,
  because the user wants every component of frame 1 now.
- **Dark mode?** → Light only, pinned by a build setting; backlog item.
- **Blank screen while loading or on failure?** → Accepted; the state-handling
  work is a mandatory roadmap item for the next spec.
- **Pluralization: view model or String Catalog?** → View model with unit tests
  for the MVP; String Catalog moves to the backlog.
- **Does `RecipeCardViewData` need `@Observable`, or is the view model enough?**
  → The view model only. `@Observable` cannot be applied to a struct (compile
  error), and a struct property of an `@Observable` class is tracked as one
  property: verified by compiling and by a runtime `withObservationTracking`
  test, and consistent with Apple's Observation docs.
- **Can `RecipeLibraryViewData` be `Equatable` with `ViewState` inside?** →
  Yes: `ViewState.error` holds `RecipeError` (already `Equatable`) instead of
  `any Error`, and the view model maps other errors to `.unavailable`.
- **How many view models?** → Two: `RecipeLibraryViewModel` and
  `FilterChipsViewModel`; search stays on the screen until milestone D.
- **Screen name?** → `RecipeLibrary`, matching the design and roadmap.
- Risk: `.searchable` on iOS 26 places the field in the system's own position
  (bottom or top depending on the container), so the screen will not match the
  design pixel for pixel. Accepted: the design says not to rebuild native
  controls.
- Risk: the fixture photos are remote and may fail or load slowly. The two
  dead links (couscous, risotto) were replaced with working Wikimedia Commons
  images, so no fixture photo fails today; the placeholder still covers a
  failure, and previews must use a deliberately bad URL to show it and must not
  depend on the network.
- Risk: `@State(initialValue:)` builds the view model when the owning view is
  re-created. The owner is the app root, which does not re-evaluate, so this is
  fine here; revisit when a parent can rebuild the Library.
- Risk: iOS 27 SwiftUI additions (lazy `@State`, `AsyncImage` caching) are not
  used; confirm availability against the 26.5 target before any future use.

## Acceptance Criteria

- **AC1.** Launching the app shows a screen titled "Recipes" with one card per
  recipe in the bundled list, in the data's order.
- **AC2.** Each card shows its title, a servings label, and a leaf mark only
  when the recipe is vegetarian.
- **AC3.** A card with a `nil` image URL or a failed image load shows the
  placeholder tile and still shows its title and servings.
- **AC4.** The servings label reads "1 serving" for 1 and "N servings" for any
  other count.
- **AC5.** The search field and the Vegetarian, Servings and Filters chips are
  visible; using each prints a message and changes nothing else.
- **AC6.** Tapping a card does nothing.
- **AC7.** The view model moves `idle -> loading -> loaded` on success and
  `idle -> loading -> error` when the service throws, and does not call the
  service again once loaded.
- **AC8.** The view renders only the loaded grid; before loaded and after an
  error nothing but the title is shown.
- **AC9.** The app appears in light mode when the device is set to dark.
- **AC10.** `Presentation/` contains no reference to any type in `API/`.
- **AC11.** Colors, type, spacing, radii and sizes used by the components come
  from `DesignTokens/` and the asset catalog, with no color or number literals
  in the component views except those in a token file.
- **AC16.** `DesignTokens/` holds every token listed in `design.html`'s tables
  and no token that is not listed there.
- **AC12.** A two-line title does not change the card height among cards in the
  same row, and the grid stays usable at a large Dynamic Type size.
- **AC13.** Every new component and the screen have a working preview.
- **AC14.** The full `ReciMateTests` suite passes.
- **AC17.** `RecipeLibraryViewModel` owns a `FilterChipsViewModel` whose view
  data lists the Vegetarian, Servings and Filters chips in that order, with a
  chevron only on Servings.
- **AC18.** Every placeholder (chip taps, search changes) prints and carries a
  `// TODO(milestone D):` comment saying what replaces it.
- **AC15.** `ContentView.swift` is gone and `ReciMateApp` shows
  `RecipeLibraryView`.

## Verification

- **AC4** `scripts/test.sh ReciMateTests/RecipeCardViewDataMapperTests`.
- **AC17** `scripts/test.sh ReciMateTests/FilterChipsViewModelTests`.
- **AC18** `rg -n "TODO\(milestone D\)" ReciMate/Presentation` lists one marker
  per placeholder.
- **AC7, AC8 (state side)** `scripts/test.sh ReciMateTests/RecipeLibraryViewModelTests`.
- **AC1, AC2, AC3, AC5, AC6, AC8, AC9, AC12** run the app on the iPhone 17
  simulator with the device set to dark and then light; check the grid, the
  failing and missing photos, the console prints, a card tap, and a large
  Dynamic Type size.
- **AC10** `rg "API|Remote|Local" ReciMate/Presentation` finds nothing that names
  an `API/` type.
- **AC11** `rg -n "Color\(|\.padding\([0-9]|cornerRadius: [0-9]|\.frame\([a-z]*: [0-9]|spacing: [0-9]" ReciMate/Presentation --glob '!DesignTokens/**'`
  finds no literals.
- **AC16** read `DesignTokens/` against the tables in `design.html`: one token
  per row, none extra.
- **AC13** open each preview in Xcode, or build the previews target.
- **AC14** `scripts/test.sh` (full suite, once, at the end).
- **AC15** `rg ContentView ReciMate` finds nothing; build succeeds.
