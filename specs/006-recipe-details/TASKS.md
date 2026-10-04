# 006 Recipe Details: tasks

Written late: Steps 1 to 7 (code) were done before this file existed, so ticks below reflect
what was verified, not when the work happened.

- [x] 1. Tokens added to `DesignTokens/` (separator, type roles, spacing 24, radius 28, sizing). Builds.
- [x] 2. `ServingsLabelFormatter` + `ServingsLabelFormatterTests`; Library uses it.
- [x] 3. `RecipeDetailsServiceSpy`, `RecipeDetailsViewModelTests`, `RecipeDetailsViewModel`, view data types.
- [x] 4. `RecipeImageView` takes `height` and `placeholderIconSize`; card passes 140 and 36.
- [x] 4b. Library card layout checked in a simulator screenshot of the running app (AC11): photo height and placeholder look as before. Xcode previews not opened.
- [x] 5. Components with previews: badge, servings line, ingredient row, step row.
- [x] 6. `RecipeDetailsView` (hero, overlapping sheet, `Picker`, lists, `.task`), DEBUG preview service and samples, screen previews.
- [ ] 6b. Open the Xcode previews (loaded, long text, no image, failing image, large Dynamic Type) (AC16). Large Dynamic Type (AC15) moved to the backlog, "Accessibility pass".
- [x] 7a. `RootView` takes `makeDetailsViewModel`; `ReciMateApp` builds service and factory; previews updated.
- [~] 7b. Simulator walk: the user ran the app and confirmed the loaded page, hero overlap and back button work (AC1, 10). Steps segment, blank screen for a recipe without details, and the picker tint are not confirmed by me.
- [x] 8a. Full suite: PASS, 56 tests (re-run after the final edit).
- [x] 8b. Greps: AC12 clean, AC13 only `spacing: 0` (pre-existing pattern), AC18 roadmap entry exists, AC19 clean. AC14 read against design.html: 13 new tokens, none extra.
- [x] 8c. `implementation-notes.md`, ROADMAP row already present, README line added.
