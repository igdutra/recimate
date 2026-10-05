# Milestone D (search + filtering): manual verification report

Build: scheme `ReciMate`, iPhone 17 simulator, iOS 26. Verified by hand. The only code change is the one-line Details fix in section A, left uncommitted. Nothing else edited, nothing committed.
Date: 2026-10-05.

## Result: 21 of 21 checks pass

| # | Result | What was seen |
|---|---|---|
| 1 | Pass | Title "Recipes", 9 cards in catalog order, round Filters button top-right. Card photos show spinners for about 1 s on first launch. |
| 2 | Pass | "Pet": only Petit Gâteau, no "Found in the steps" caption. |
| 3 | Pass | "gateau" (no accent) returns Petit Gâteau. |
| 4 | Pass | "ramekins": only Petit Gâteau, with "Found in the steps". |
| 5 | Pass | "oven": Petit Gâteau, Lemon Herb Chicken, Sheet Pan Salmon, Beef Tacos (Fails: Not Found), Roasted Vegetable Couscous, all with the caption. |
| 6 | Pass | System no-results: title `No Results for “zzz”` (curly quotes), "Check the spelling or try a new search." |
| 7 | Pass | Clearing the text restores all 9 at once, no spinner (cached query). |
| 8 | Pass (retracted failure) | A new, uncached query hides the grid and shows a centred spinner. That is the designed loading state (`coveredBy` in `View+StateOverlay.swift`). Clearing "Salmon" afterwards returned all 9 instantly from the cache. My first "fail" misread the checklist wording as "old cards stay visible under the spinner on every search". |
| 9 | Pass (run twice) | Sections Dietary ("Vegetarian only"), Servings ("Exactly", Any, 1–8), "Include ingredients", "Exclude ingredients". Reset (disabled until a filter is set) and Done in the toolbar. |
| 10 | Pass (re-run) | Vegetarian only gives Petit Gâteau, Creamy Tomato Pasta (Fails: Data), Chickpea Coconut Curry, Roasted Vegetable Couscous, Mushroom Risotto. Live update behind the sheet confirmed: dragging the open sheet down showed the Library already filtered and the Filters button already green. |
| 11 | Pass | Vegetarian + Servings 2: Creamy Tomato Pasta (Fails: Data), Mushroom Risotto. |
| 12 | Pass | Include "cream": Petit Gâteau, Creamy Tomato Pasta (Fails: Data), Mushroom Risotto. Reset tested separately: clears everything, then disables itself. |
| 13 | Pass | + exclude "mushroom": Petit Gâteau, Creamy Tomato Pasta (Fails: Data). |
| 14 | Pass | Adding "Cream" to Exclude while in Include moved it out of Include (case-insensitive match). |
| 15 | Pass | Filters button is a solid green filled circle while any filter is active, plain white otherwise. |
| 16 | Pass | Vegetarian + 2 + "zzz": `No Results for “zzz”`, "No recipes match this search with these filters.", Clear Filters button. |
| 17 | Pass | Text cleared, filters kept. Vegetarian + 8: "No Results", "No recipes match these filters.", Clear Filters. Tapping it restores all 9. |
| 18 | Pass | Details: full-bleed hero, back chevron, Vegetarian badge, title, description, "4 servings", Ingredients/Steps segmented control, 4 numbered steps. |
| 19 | Pass | Creamy Tomato Pasta (Fails: Data): "Couldn't Load", "The data we received couldn't be read.", Try Again. |
| 20 | Pass | Beef Tacos (Fails: Not Found): "Couldn't Load", "We couldn't find what you were looking for.", Try Again. |
| 21 | Pass | Try Again shows the spinner, then the same error again. No crash, no blank screen. |

## Observations beyond the checklist

### A. Details screen: top of the hero is washed out for about a second after the photo appears, then snaps to normal (visual glitch, reproduced)

Reproduced three times on Petit Gâteau, and the user's own screenshot shows the same frame. Timeline, frames taken as the spinner clears:

1. Spinner over a light grey hero, status bar dark, back button light.
2. **First frame with the photo:** the photo is drawn, but the top ~third of it is covered by a pale, white-to-transparent wash. Status bar text is **dark**, the back button is a light near-white glass circle. This is the odd frame.
3. About 0.7 s to 1 s later the wash is gone: the photo is full strength at the top, the status bar text is **white** and the glass back button is tinted darker. This is the settled state and it stays.

So the flip is not "light placeholder to dark photo" (my first explanation, which was wrong): the photo is already on screen in frame 2, with a pale gradient over it. The gradient is what makes the system choose the dark status bar, and when the gradient disappears the status bar and glass controls flip.

Likely cause (inferred from code and the frames, not proven): that gradient is the iOS 26 scroll-edge effect at the top of the `ScrollView`. `RecipeDetailsPage` lets the content run under the status bar (`.ignoresSafeArea(edges: .top)`, `RecipeDetailsView.swift:98`) and the navigation bar background is hidden (`.toolbarBackground(.hidden, for: .navigationBar)`, line 66). On the first layout with real content the scroll view appears to count the hero as scrolled under the top bar, so it draws the soft edge. One layout pass later the offset settles at the true top, the effect turns off, and the status bar and back button restyle. Nothing in the project sets a status bar, toolbar colour scheme or scroll-edge effect (checked with `rg`).

Fix candidates, none applied or tested yet:
- `.scrollEdgeEffectHidden(true, for: .top)` on the `ScrollView` in `RecipeDetailsPage`. Probably the right one: the hero is meant to sit edge to edge under the status bar, so the soft edge has no job there. Needs an API availability check and a before/after run.
- Pin the style as well, for photos that are light at the top: `.toolbarColorScheme(.dark, for: .navigationBar)` plus a dark top scrim on the hero. Separate decision, since the status bar currently follows each photo.
- Only if the scroll-edge theory fails on test: hold the page hidden one frame longer after the photo arrives.

Not tested on a light-topped photo.

**Fix applied and verified (uncommitted):** `.scrollEdgeEffectHidden(true, for: .top)` on the `ScrollView` in `RecipeDetailsPage` (`RecipeDetailsView.swift`). Same capture as before: the photo is at full strength from its first frame, with no pale wash and no later snap. Build succeeded. Side effect: the status bar now stays **dark** for the whole time (it used to settle to white), so the clock and icons sit dark over the brown top-left of the Petit Gâteau photo, a lower-contrast look than before. If white is wanted, pin it with `.toolbarColorScheme(.dark, for: .navigationBar)` plus a dark top scrim; not applied.

### B. Smaller things

- **Autocapitalisation** in the search field and ingredient fields ("Ramekins", "Zzz", chip "Cream" vs "cream"). Matching is case- and accent-insensitive, so results are correct; only the displayed casing of the term varies. Fine as is. Optional: `.textInputAutocapitalization(.never)` on those fields.
- **Search focus hides the title and Filters button.** While the search field is focused the large title and the toolbar button are not visible, so Filters cannot be reached until search is dismissed (the X, which also clears the text). This is the iOS 26 bottom-search behaviour; noted, not a defect.
- **Filters sheet height.** It covers nearly the whole screen, so the Library behind it cannot be watched unless the sheet is dragged down. A medium detent would make the "updates live" behaviour visible. Optional.
- **Card heights** differ slightly in a row (title lines, caption). Cosmetic.

### C. Testing notes

- Synthetic taps on the Vegetarian switch and its row did not toggle it; a swipe on the thumb did. Treated as a tooling limit, not an app bug.
- Screenshots trail the screen by a fraction of a second. Two early observations (check 8, and "Chick" → "Chicken") were misread because of that and the 0.3 s search debounce, and were corrected.
