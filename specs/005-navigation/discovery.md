Created: 2026-10-04
Updated: 2026-10-04

# 005 Navigation: discovery

Lays down the navigation layer before the real Filters sheet and Recipe Detail
screens exist. A router, a root view that owns the stack, one push destination
and one sheet, each opening a **dummy view**. No behavior beyond opening them.

Inputs read: the current app entry point and Library screen, specs 003 and 004,
and the user's router reference code (a router, a route enum, a sheet enum and a
root view with `NavigationStack`, `.navigationDestination(for:)` and `.sheet(item:)`).

## Where the code is today

- `ReciMateApp` builds `RecipeLibraryViewModel` and shows `RecipeLibraryView`
  directly. It is the composition root.
- `RecipeLibraryView` owns its own `NavigationStack`, with the search field and
  title inside it. Nothing is routed, there is no details screen and no sheet.
- `RecipeCardView` is not tappable yet, and the library has no filter button.

## Decisions

1. **Router pattern, as in the reference.** An `@Observable` `AppRouter` holds the
   `[AppRoute]` path (changed from `NavigationPath` during the build) and an optional `AppSheet`, with `push`, `pop`, `popToRoot`,
   `present` and `dismissSheet`. `AppRoute` is a `Hashable` enum and `AppSheet` an
   `Identifiable` enum.
2. **`RootView` owns the stack.** It wraps the first screen in a `NavigationStack`
   bound to the router's path, attaches `.navigationDestination(for: AppRoute.self)`
   and `.sheet(item:)`. The `NavigationStack` that `RecipeLibraryView` has today
   moves up into `RootView`; the search field and title stay on the Library content.
3. **The router is injected into the views by initializer, at the composition
   root. `@Environment(AppRouter.self)` is forbidden.** Views call the router
   directly on a tap. View models do not hold the router and take no navigation
   responsibility.
   - Why: view models already call the service and format; navigation would be a
     third responsibility, the same drift as massive view controllers.
   - A web search found both approaches in common use, with neither standard. This
     is a project choice, recorded in the README under "Architecture decisions".
   - Taps carry no behavior in this task. Later, a tap with behavior (Apply
     filters, then dismiss) goes through the view model, and the view dismisses.
   - If it turns out badly, the router moves into the view models.
4. **One push route, one sheet.** `AppRoute.details(recipeID:)` pushed on a
   recipe card tap. `AppSheet.filters` presented from a toolbar filter button on
   the Library screen. The route carries the recipe id only, since details are
   fetched separately and only 3 of 9 recipes have them.
5. **Dummy views, nothing else.** A `RecipeDetailsView` and a `FiltersSheetView`
   that show their name (and the recipe id for details). They live in the
   presentation layer, in their own folders, ready to be replaced.
6. **Composition.** `ReciMateApp` builds the router and the Library view model and
   hands both to `RootView`; `RootView` passes the router to the views it builds.
7. **Tests.** Unit tests for the router itself (push, pop, pop to root, present,
   dismiss). Navigation from the views (tap a card, tap the filter button) is
   covered later with ViewInspector, logged in `product/BACKLOG.md`.

## Open questions

- **Dummy filter button placement.** A temporary toolbar button was proposed and
  not contradicted ("just basic wiring"). Confirm in the spec; it is replaced when
  the real filters entry point is designed.
- **Card tap target.** Make the whole card a `Button` or add a tap gesture to it,
  without changing its look. Decide in the spec.
- **Details for recipes without data.** Only 3 of 9 recipes have details, so a
  tap on the others will reach a dummy view that cannot load them. Out of scope
  here; the real Detail spec handles the unavailable state.

## Out of scope

The real Filters sheet and Recipe Detail screens, loading details, filter state,
deep links and state restoration, and ViewInspector tests (backlog).
