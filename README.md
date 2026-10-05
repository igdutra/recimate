<p align="center">
  <img src="docs/app-icon.png" alt="ReciMate app icon" width="120">
</p>

# ReciMate 🍋👨‍🍳 — Your recipe companion

ReciMate is a native iOS recipe browser application built with Swift and SwiftUI. It demonstrates modern iOS development practices through a clean recipe search and filtering interface powered by local JSON data, with support for dietary preferences, ingredient filtering, and title and instruction search. The app serves as a showcase of SwiftUI idioms, MVVM architecture, and thoughtful error handling in a production-ready iOS application.

## AI workflow

The repo carries a set of Claude Code skills under [`.claude/skills`](.claude/skills), a spec-driven workflow for working with an AI agent:

```
/discovery → /prototype → /spec → /implement-spec → /qa + /local-code-review → /finish
```

`/pitch` is a separate skill for writing up a finished piece of work. Each task gets a slug (`NNN-short-kebab-slug`, fixed by `/discovery`), and its work lands in `specs/<slug>/`.

The workflow follows Anthropic's guidance for the Claude 5 family. The core idea comes from [A field guide to Claude Fable: finding your unknowns](https://claude.com/blog/a-field-guide-to-claude-fable-finding-your-unknowns): the quality of the work is bottlenecked by how well its unknowns are clarified, so each practice in it (blind-spot interviews, prototyping several directions, implementation plans, implementation notes, explainers, pitches) became one skill. Further refinements come from:

- [Getting the most out of Opus 5.5](https://claude.dev/blog/getting-the-most-out-of-opus-5-5/)
- [Building with Claude Sonnet 5.5](https://claude.dev/blog/building-with-claude-sonnet-5-5/)
- [Spending Your Effort](https://claude.dev/blog/spending-your-effort/)

Build and test commands for the agent live in [`CLAUDE.md`](CLAUDE.md).

## Code organization

Files are condensed for simplicity. A view's view data lives in the view's file, and the mapping from a domain type to view data is a static function on the view model, tested with it. Under `Presentation/Library/`, a card's small views sit together in `Components/RecipeCard/`. The Details screen follows the same shape in `Presentation/Details/`: its view data types and small row views sit in `RecipeDetailsView.swift`, and the servings label shared with the Library is `Shared/ServingsLabelFormatter.swift`. Depending on the project, each of these types can deserve its own file (a bigger team, a larger view data type, a mapper shared by several screens); here, fewer files made the code easier to read.

## Architecture decisions

Each of these was settled for this project and could go the other way in another one.

- **Navigation is owned by the views, through a router.** An `@Observable` `AppRouter` holds the `NavigationStack` path and the presented sheet. The views receive it through their initializers, wired at the composition root (never through `@Environment`), and call it directly when a button is tapped. A search of what the community does found both approaches in common use: the view calls the router directly, or the view model signals intent to a router or coordinator. Neither is the standard. We chose the first to keep view models from collecting yet another responsibility (calling services, formatting and now navigation), the same drift as massive view controllers. Taps only wire to the router; anything with behavior of its own (applying state and then dismissing, a check before navigating, analytics) still goes through the view model. The trade-off is that navigation has no view model seam to unit test. The plan is to cover it with ViewInspector tests that tap a button and assert the router's path or sheet (see the backlog). It depends on the project: with more navigation logic, or a team that wants navigation covered by plain unit tests, injecting the router into view models is the better fit, and the change here would be small.
- **One collection endpoint, and each layer named for its role.** The brief's "search endpoint" is read as the recipe collection with optional query filters: `GET /recipes?vegetarian=true&servings=2&include=cream&exclude=mushrooms&instructions=ramekins`, with `GET /recipes/{id}` for one recipe. A search is a list with filters, so a second endpoint would be two paths to the same data. The names follow the layers: the URL names the resource, the domain and API code say list and details (`RecipeListService.loadRecipes(matching:)`, `RecipeDetailsService.loadRecipe(id:)`), and the screen says Library because it shows a grid. The chain is `GET /recipes` → `RecipeListService` → `RecipePreview` → `RecipeLibraryViewModel` → `RecipeCardViewData` → `RecipeLibraryView`.
- **The view state does not carry the data.** `ViewState` is `loading`, `loaded` or `error(RecipeError)`, and the data sits next to it in the view data (`cards` on the Library, `content` on Details). The common alternative puts the data inside the loaded case, `enum LoadingState<Value> { case idle, loading, failed(Error), loaded(Value) }` (see [Swift by Sundell](https://www.swiftbysundell.com/articles/handling-loading-states-in-swiftui/)). That makes states that make no sense impossible to write and suits a generic container view, but moving to `loading` or `failed` drops the value. This app needs the value to survive: the Library keeps its old cards while a new search runs, so the grid does not flicker, and the loading and error overlay covers content that stays in the hierarchy, so it keeps its identity and scroll position. With the data in the enum, it would have to come back in the other cases (`loading(previous:)`, `failed(error, previous:)`). The trade-off is that a combination that makes no sense, such as Details in `loaded` with its placeholder content, can be written. Each view model is the only writer of its view data (`private(set)`), and its tests pin the combinations. It depends on the project: a screen that shows nothing but its data, with no refresh or search, is simpler with the data in the enum.
- **One search field finds titles and steps, and a card says when the match was only in the steps.** The brief asks for search within instruction text, and the first version read that literally: the field searched the steps only, so typing a recipe's name ("Pet" for Petit Gâteau) showed "No Results" with the recipe on screen. That fails the brief's "logical and intuitive user experience". Research pointed one way. NN/g found that people [overlook and forget a search scope](https://www.nngroup.com/articles/scoped-search/) and should get "all" by default, and Apple's [HIG on search fields](https://developer.apple.com/design/human-interface-guidelines/search-fields) says to "default to a broader scope". Tokens, the other native option, are meant for filtering by values such as Vegetarian, which the Filters sheet already does. So the field matches the title or any step, with title matches first and no scope picker. Results found only in the steps would look random, so those cards carry one line, "Found in the steps". A second cell type per match kind and grouped "Titles" / "In the steps" sections were both drawn and rejected as heavier than the problem. The endpoint keeps `instructions=` for steps only, as the brief asks, and gains `q=` for the combined search. The app decides "found only in the steps" on its own, because a card already has the title and both sides use the same matching function. A real backend with its own matching (stemming, synonyms) would need to return where the match was instead. No results now repeats the searched text, following [NN/g's no-results guidelines](https://www.nngroup.com/articles/search-no-results-serp/), and offers Clear Filters when filters are part of the cause.

## Search result cache

The Library keeps every successful search result in memory, keyed by the query that produced it, so going back to a query already searched (clearing the text, turning a filter off) shows its result at once, with no debounce and no spinner. Failures are never cached.

This is a deliberately rudimentary strategy, a plain dictionary on the view model, added to test the idea. It has none of what a production cache needs:

- **Time to live (TTL).** Entries never expire. A real backend's data changes, so each entry needs a lifetime, and how long that should be depends on how fast the data goes stale. It would have to be chosen and tested, not guessed.
- **Refresh.** No pull to refresh and no revalidation in the background (for example showing the cached result, then fetching again and replacing it if it changed).
- **Invalidation.** Nothing clears an entry when the data changes.
- **Size limit.** The dictionary grows with every distinct query. A real one would cap it and evict the least recently used entries.
- **Lifetime.** It lives only as long as the view model; it is not persisted.

In a production app these would be combined (TTL plus refresh plus a size cap, at least), and the combination tested against real usage. Here the catalog is static local JSON, so none of them can go stale. Where it lives (the view model, not a service wrapper) is on purpose: a hit must skip the loading state and the debounce, which a wrapper around the service cannot do.
