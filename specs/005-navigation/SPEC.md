Created: 2026-10-04
Updated: 2026-10-04

# 005 Navigation: spec

## Context / Why

The app has one screen and no way to go anywhere. Before the real Filters sheet
and Recipe Detail screens are built, the navigation layer goes in on its own:
a router, a root view that owns the stack, one push destination and one sheet,
each opening a placeholder. The real screens then slot in without touching how
navigation works. Decisions come from [discovery.md](discovery.md).

## Requirements / What

- Launching the app still shows the Recipes screen, with its title, search field,
  chips and grid unchanged.
- Tapping a recipe card opens a placeholder details screen that shows which
  recipe was tapped, with a back button that returns to the Recipes screen.
- The Recipes screen has a Filters button in its navigation bar. Tapping it opens
  a placeholder filters sheet, which can be dismissed by swiping it down.
- Cards look the same as before.
- Nothing else changes: no loading of details, no filter state, no new behavior.

## Decisions / Architecture

1. **The router is injected into the views by initializer, wired at the
   composition root. Never `@Environment`.** Views call it directly on a tap; view
   models never see it. Rejected: injecting it into the view models, and
   `@Environment(AppRouter.self)`. Recorded in the README under "Architecture
   decisions". If it goes badly, the router moves into the view models.
2. **`RootView` owns the `NavigationStack`**, bound to the router's path, with
   `.navigationDestination(for: AppRoute.self)` and `.sheet(item:)`. The stack
   that `RecipeLibraryView` owns today is removed from it.
3. **One route, one sheet.** `AppRoute.details(recipeID: String)` and
   `AppSheet.filters`. The route carries the id only, since details are fetched
   separately and only 3 of 9 recipes have them.
4. **The path is a typed `[AppRoute]`, not the opaque `NavigationPath`**, since there
   is one fixed route type. Router API: `path`, `sheet`, `push(_:)`, `pop()`, `popToRoot()`,
   `present(_:)`, `dismissSheet()`. `pop()` on an empty path does nothing.
5. **The whole card is a `Button` with the plain style**, added in the grid, not
   in `RecipeCardView`. Rejected: a tap gesture. Cost: no pressed-state highlight on the card for now.
6. **The Filters entry point is a temporary toolbar button** (title "Filters",
   system image `slider.horizontal.3`) on the Recipes screen. It is replaced when
   the real filters entry point is built.
7. **Placeholders show their name only**, and the id for details. No view model,
   no service, no dismiss button on the sheet.

## Approach / How

New files, all under `ReciMate/Presentation/`:

- `Navigation/AppRouter.swift`: `@MainActor @Observable final class AppRouter`
  with `var path: [AppRoute] = []` and `var sheet: AppSheet?`, and the methods
  above.
- `Navigation/AppRoute.swift`: `enum AppRoute: Hashable` with `.details(recipeID:)`.
- `Navigation/AppSheet.swift`: `enum AppSheet: Identifiable, Hashable` with
  `.filters`, whose `id` is a fixed string.
- `RootView.swift`: takes the router and the Library view model. Holds the router
  as `@Bindable` for the path and sheet bindings. Builds `RecipeLibraryView` with
  the router, and the two placeholders in the destination and sheet closures.
- `Details/RecipeDetailsView.swift`: placeholder, takes `recipeID`, shows it,
  sets a navigation title.
- `Filters/FiltersSheetView.swift`: placeholder, shows "Filters".

Changed files:

- `Library/RecipeLibraryView.swift`: takes `router` in its initializer; drops its
  `NavigationStack`; keeps the search field, title and the load state check on its
  content; adds the toolbar button that calls `router.present(.filters)`;
  `RecipeGrid` takes the router and wraps each card in a `Button` that calls
  `router.push(.details(recipeID: card.id))`. Previews pass a fresh `AppRouter()`
  and are wrapped in a `NavigationStack` so the title and toolbar render.
- `ReciMateApp.swift`: holds `@State private var router = AppRouter()`, shows
  `RootView(router:viewModel:)`. `makeLibraryViewModel()` stays. The preview
  builds a `RootView`.

Fixed and assumed:

- The `.task { await viewModel.load() }` stays on the Library view, on a stable
  container (a `ZStack`, not a `Group`: a `Group` with no content never runs
  `.task`) so it still runs once and does not depend on the
  conditional content inside.
- While loading, the Library shows nothing, as today (the loading and error
  states are a later spec). The toolbar button belongs to the loaded content, so
  it is also hidden until then.
- `Presentation/` still imports `Domain` only. `ReciMateApp` stays the one place
  that builds an `API/` type.
- Swift 6 strict concurrency: the router is main-actor isolated.
- Existing patterns to follow: previews with named samples, design tokens for
  spacing, doc comments only where the why is not obvious.

## Out of Scope

- The real Filters sheet and Recipe Detail screens, loading recipe details, and the
  unavailable state for the 6 of 9 recipes without details.
- Filter state, applying filters, and a dismiss control on the sheet.
- Deep links, state restoration, tab or multi-stack navigation.
- Card pressed-state styling.
- ViewInspector tests of the views (in `product/BACKLOG.md`).

## Steps

1. `AppRouterTests` first (push, pop, pop on empty, pop to root, present,
   dismiss), then `AppRouter`, `AppRoute`, `AppSheet`. Run the suite for it.
2. `RecipeDetailsView` and `FiltersSheetView` placeholders with previews.
3. `RootView` with a preview.
4. Wire `RecipeLibraryView`: remove its stack, add the toolbar button, wrap the
   cards in buttons, update its previews.
5. Wire `ReciMateApp` and its preview to `RootView`.
6. Check in the simulator: card tap, back, Filters button, swipe down.
7. Run the full suite once. Note any deviation in `implementation-notes.md` under
   `## Deviations`, and update `product/ROADMAP.md` if it tracks navigation.

Task list: no

## Open Questions / Risks

- **Where does the Filters button go?** → A temporary toolbar button on the
  Recipes screen: smallest change, replaced later by the designed entry point.
- **Card tap: button or gesture?** → A plain-style `Button` around the card. Accepted cost:
  no pressed highlight.
- **Details for recipes that have none?** → Out of scope; the dummy view shows the
  id only. The real Detail spec owns the unavailable state.
- **Does `.task` still run once after the stack moves?** → Yes, if it sits on a
  stable container; verified by the existing view model load tests plus a manual
  check that the grid appears on launch.
- Risk: the toolbar and `.searchable` need a `NavigationStack` ancestor, so
  previews of the Library view need one or the title, search field and button do
  not render.
- Risk: moving the stack to `RootView` could change how the large title and
  search field collapse. Check by eye at the end of Step 6.

## Acceptance Criteria

- **AC1.** Launching the app shows the Recipes screen as before: title, search
  field, chips and grid.
- **AC2.** Tapping a recipe card pushes a details placeholder that shows the
  tapped recipe's id.
- **AC3.** Back from the details placeholder returns to the Recipes screen.
- **AC4.** The Recipes screen has a Filters button in the navigation bar, and
  tapping it presents the filters placeholder as a sheet.
- **AC5.** The filters sheet can be dismissed by swiping down, and the router's
  sheet is cleared afterwards.
- **AC6.** Cards look the same as before.
- **AC7.** `AppRouter` behaves as specified: `push` adds to the path, `pop`
  removes the last entry and does nothing on an empty path, `popToRoot` empties
  the path, `present` sets the sheet and `dismissSheet` clears it.
- **AC8.** The router reaches views only by initializer: no `@Environment` use of
  it, and no view model holds it.
- **AC9.** The app and test target compile with no warnings added, and the full
  `ReciMateTests` suite passes.

## Verification

- **AC7** `scripts/test.sh ReciMateTests/AppRouterTests`, then the suite.
- **AC9** `scripts/test.sh` (full suite), once at the end.
- **AC1, AC2, AC3, AC4, AC5** Run the app on the iPhone 17 simulator: launch,
  tap a card, go back, tap Filters, swipe the sheet down. Previews cover each
  placeholder and `RootView` for a quick check.
- **AC6** Compare the card against the previous screenshot or preview.
- **AC8** `rg "Environment\(AppRouter|\.environment\(router" ReciMate` returns
  nothing, and `rg AppRouter ReciMate/Presentation/Library/RecipeLibraryViewModel.swift`
  returns nothing.
