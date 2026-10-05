<p align="center">
  <img src="docs/app-icon.png" alt="ReciMate app icon" width="120">
</p>

# ReciMate 🍋👨‍🍳 — Your recipe companion

ReciMate is a native iOS recipe browser application built with Swift and SwiftUI. It demonstrates modern iOS development practices through a clean recipe search and filtering interface powered by local JSON data, with support for dietary preferences, ingredient filtering, and instruction search. The app serves as a showcase of SwiftUI idioms, MVVM architecture, and thoughtful error handling in a production-ready iOS application.

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
