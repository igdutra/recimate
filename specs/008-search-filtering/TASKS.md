# 008 Search + filtering: tasks

Tick each item when done. Steps follow [SPEC.md](SPEC.md).

- [x] 1. Remove quick filter chips (views, view model, tests, `quickFilterBar` property and its test, README mention); build and run Library view model tests; commit alone
- [x] 2. `RecipeSearchQuery` and `RecipeSearchQueryTests`
- [x] 3. `RecipeEndpoint.list(query:)` and the `/recipes/{id}` details path; update `RecipeEndpointTests`
- [x] 4. `recipe-catalog.json`, `Codable` DTOs, `LocalRecipeSearchServer`, client routing, playground; mock-only tests in `ReciMateTests/API/Mock/`
- [x] 5. `RecipeListService.loadRecipes(matching:)` and `RemoteRecipeListService` pass the query; spy, preview service, tests; delete `recipe-list.json`; end-to-end catalog tests
- [x] 6. `FiltersViewModel` and `FiltersViewModelTests`
- [x] 7. `RecipeLibraryViewModel` on search (sequence guard, state rules, owned `FiltersViewModel`); update tests
- [x] 8. Views: Library, `FiltersSheetView` + chips layout, `RootView` wiring, previews for every listed state
- [ ] 9. Simulator pass; record the system no-results wording (launch + Library done; typing, sheet and no-results wording blocked, see notes)
- [x] 10. Full suite; greps for retired names
- [x] 11. Final notes, ROADMAP D, backlog chips entry with removal commit hash
