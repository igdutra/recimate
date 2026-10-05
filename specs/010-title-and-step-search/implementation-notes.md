# 010 Title and step search: implementation notes

## Assumptions

- "Found in the steps" is decided in the app: the searched text is not blank and `SearchTextMatching.text(title, contains:)` is false. A real backend with its own matching would have to return the match location.
- `q` searches the title or any step; `instructions` keeps searching steps only and is not used by the UI. Both together are AND.
- The fake server ranks title matches first only when `q` is present (stable partition, catalog order inside each group).
- No-results text and filter state come from the presented result (`searchedText`, `searchedWithFilters`), never from the live field or filters.
- An empty result with no text and no filters (empty catalog only) counts as `.text` and shows the bare system "No Results", as before.
- The fixture titles "(Fails: Data)" and "(Fails: Not Found)" match searches for "fails" / "data"; harmless.
- Endpoint query building uses `URL.appending(queryItems:)`; every existing `RecipeEndpointTests` expectation passed unchanged, so the encoding did not move. The `+` limitation stays.

## Deviations

- Simulator step 8 (typing "pet", "roast", "tofu lasagna", filter combinations, Clear Filters, VoiceOver) was not run: there is no tool here to type or tap in the simulator. Only the launch was checked by screenshot (the field reads "Search titles and steps", AC6). The same cases are covered by `RecipeLibraryViewModelTests`, `LocalRecipeSearchServerTests` and `RecipeCatalogFixtureTests`; the previews were added but not opened in Xcode.
- Existing tests that mapped `RecipeLibraryViewModel.makeCard` as a function reference now use a closure, because the new defaulted `searchedText` parameter changes its type.
