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
