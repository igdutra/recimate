# 008 Search + filtering: implementation notes

## Assumptions

- **Endpoint:** `GET /recipes` with optional `vegetarian=true`, `servings=<n>`, repeated `include=<term>`, repeated `exclude=<term>`, `instructions=<text>`; `GET /recipes/{id}` for details. The brief's "search endpoint" is read as the collection with query filters.
- **Servings control:** a fixed "Any" plus 1 to 8. The data holds 2 to 6 and any bound is arbitrary; a server holding other values would not be reachable from the sheet. Known limitation (README).
- **Search field searches instruction text only.** Typing a recipe's name finds nothing unless a step says it. Known limitation (README).
- **A `+` in a query value** is not percent-encoded by `URLComponents`; a real server could read it as a space. Irrelevant to the local server.
- **The local client routes by the last path component.** A recipe whose id is `recipes` would be mis-routed; ids are trusted and none is called that.
- **Servings choice limits:** a value below 1 can only come from a hand-built query; it matches nothing.
- **No debounce.** The local data answers at once; a network client would debounce (README).
- **No error view.** A failed search sets `.error` (tested) but the screen shows only the title and search field until the shared error pass (milestone E).

## E3 as built (matching rules)

| Case | Rule |
|---|---|
| Instruction text | One phrase, case- and accent-insensitive "contains", against any single step |
| Include terms | AND; "contains" on ingredient names (not ids), ignoring case and accents |
| Exclude terms | A recipe is dropped if any term matches |
| Same term included and excluded | Nothing satisfies it, so the result is empty; no error type. The sheet prevents it (adding to one list removes it from the other) |
| Blank or whitespace text or term | Dropped in `RecipeEndpoint` (one place); `RecipeSearchQuery` helpers also ignore blanks and repeats |
| Recipe with no ingredient or step data | Fails an include filter and an instruction search; passes an exclude filter |
| Servings | Exact match; below 1 matches nothing |
| Vegetarian off | No filter, never "non-vegetarian only" |
| Result order | Catalog order |
| Overlapping searches | Each search takes a sequence number; only the latest may present. The previous search task is cancelled. A cancelled or outdated search never sets `.error` |

## Deviations

- The first pass renamed the list pipeline to "search" (a reading of the earlier spec text). SPEC.md was then revised (one `GET /recipes` endpoint, list names kept) and the work was redone to match it; nothing of the first pass remains.
- `RecipeLibraryView` takes an optional `searchText` in its initializer, used only by previews to show the field already filled (no-results from text). Not in the spec.
- The `ZStack` workaround in `RecipeLibraryView` (and its TODO) is removed: the scroll view is always present now, so `.task` always has a view.
- `ServingsChoice` (`.any` / `.count`) is a small enum in `FiltersSheetView.swift` so the picker has a hashable value; the spec says only "Any or a number".
- The toolbar prominent style is `.borderedProminent` applied in a branch (a ternary between button styles does not compile).

## Manual checks

- **Done:** simulator launch (iPhone 17): the Library opens with all recipes, no chip row, a Filters button and a "Search instructions" field. On iOS 26 the search field sits at the **bottom** of the screen, above the home indicator, not under the title.
- **Not done (blocked):** typing in the field, opening the sheet, chip entry, the prominent button, and the system no-results wording (text only, and filters only). The environment could not tap or type in the Simulator (no `idb`/`axe`; Apple events to System Events were not authorized). The previews were written but not opened (no Xcode canvas here). **The no-results wording is therefore not recorded.** To do by hand.

## Delete when the mock is replaced by a real backend

- `ReciMate/API/Infrastructure/` whole: `LocalRecipeAPIClient`, `LocalRecipeSearchServer`, `RecipeSearch/recipe-catalog.json`, the details fixtures.
- `ReciMateTests/API/Mock/` whole: `LocalRecipeSearchServerTests`, `RecipeCatalogFixtureTests`, `RecipeCatalogDriftTests`.
- Composition root: swap `LocalRecipeAPIClient()` for the URLSession client in `ReciMateApp`.
