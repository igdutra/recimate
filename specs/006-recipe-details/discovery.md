Created: 2026-10-04
Updated: 2026-10-04

# 006 Recipe Details: discovery

Builds the **Recipe Details screen in its loaded state**, from the 003 design,
behind the navigation that spec 005 already laid (`AppRoute.details(recipeID:)`).
Same shape as spec 004 (Library): a screen, its view model, small components and
only the design tokens the screen needs. Milestone E in
[ROADMAP.md](../../product/ROADMAP.md).

Inputs read: specs 003, 004, 005, `product/`, the domain and API layers, the
current placeholder `RecipeDetailsView`, `RootView`, `ReciMateApp`, the existing
tokens and `RecipeImageView`.

## Decisions

1. **Layout: segmented Ingredients / Steps** (003 frames 12-13) is what ships.
   Both layouts stay in the design snapshot so the other can be swapped in: see
   "Prototype". Only the segmented one is built in code.
2. **Native navigation back button.** No custom back button. The mock's floating
   circle is not drawn; iOS 26 draws the system back button as glass over the hero.
3. **Happy path only (loaded state).** The view model owns a full `ViewState`
   (`loading`, `loaded`, `error(RecipeError)`), tests all of it, and the view
   renders only the loaded screen; otherwise it is blank. The rest is **in the
   roadmap, not the backlog**, because it is mandatory (E2): loading, error with
   Try Again, no-image hero. Recorded under milestone E, including what changes
   when `View+StateOverlay` lands (see the roadmap). **Done.**
4. **Known consequence of 3:** until those states land, tapping any recipe but
   `lemon-herb-chicken` or `petit-gateau` (and `creamy-tomato-pasta`, malformed on
   purpose) opens a blank screen. Accepted.
5. **No `idle`.** The view model starts in `.loading` and reuses `ViewState`.
   `load()` returns at once if loaded or in flight, and re-runs after an error.
6. **Full-bleed hero** under the status bar, with the body sheet (28pt top
   radius) overlapping it. The native back button floats over it.
7. **Composition.** `ReciMateApp` builds a `RemoteRecipeDetailsService` and gives
   `RootView` a factory that makes a `RecipeDetailsViewModel` for a `recipeID`;
   `RootView`'s `navigationDestination` calls it. Constructor injection, no
   `@Environment`. `Presentation/` still never imports `API/`.
8. **Hero reuses `RecipeImageView`.** It already handles loading, success,
   failure and a nil URL. Only the 140pt height and the 36pt placeholder icon are
   hardcoded; they become parameters (the card passes today's values). The hero
   is the same component at a bigger size, not a new one.
9. **New small components:** a Vegetarian badge (white text on green, capsule,
   leaf icon). `VegetarianMarkView` stays icon-only for the card. Ingredient row
   and step row are small private views in the Details file.
10. **Servings label is shared.** The Library's private servings formatter
    moves to `Presentation/Shared/` so both screens use one ("1 serving",
    "N servings"). Its tests move with it. The only refactor this spec implies.
11. **View data**, as in 004: `RecipeDetailsViewData` (state, title, summary,
    servings label, vegetarian flag, image URL, ingredient rows, step rows),
    built by a static mapper on the view model, tested there.
    `@Observable` on the view model only.
12. **Segment selection is view-local `@State`**, not view model state: pure UI,
    no logic.
13. **Tokens: only those the segmented loaded screen uses, plus the scroll
    variant's** so the swap needs no new token work. Off-scale values map to the
    scale, as 004 did for 10pt: 6pt gap to 8, 14pt step gap to 12, 28pt section gap
    to 24 (added step). Text uses system styles: Title (28), Title 2 (22), Body,
    Subheadline, Footnote. The segmented control is a native tinted `Picker`
    (`.segmented`), no custom token. Green on Mist is never text (contrast 4.4);
    the badge is white on green (5.05).
14. **One code base: mirror the Library.** Views, view models, preview samples,
    test suites and fixtures follow what spec 004 did (MARK sections, `private
    extension` test helpers with `SUTBundle` and `makeSUT()`, `@Suite(.hangGuard)`,
    `.fixture(...)` factories and named fixtures, `_DevelopmentAssets` samples built
    through the production mapper, doc comments that say why). The detailed list is
    in `SPEC.md` under "Conventions to mirror". The one deliberate difference is the
    shared servings formatter, since two screens now use it.
15. **Tests:** view model only (loading to loaded, loading to error, no reload once
    loaded, retry after error), the mapper, and the shared servings label. Views by
    previews, as in 004.

## Missing tokens (first pass, to confirm in the snapshot)

Not in `DesignTokens/` today:

- Type: Title (screen title of the recipe), Title 2 (section title in the scroll
  variant), badge label (Footnote semibold).
- Spacing: 24 step.
- Radius: 28 (body sheet over the hero), badge capsule uses `Capsule`.
- Color: separator, ink at 12% (scroll variant rows and servings rule).
- Sizing: hero height 280 (segmented) and 320 (scroll), ingredient row minimum
  height 48 and 52, step number circle 28, icons 14 (badge leaf) and 20 (servings
  people icon). The 56pt no-image hero icon and the error-frame sizes (80pt
  circle, 32pt loading) belong to the deferred states, not this spec.

## Open questions

None that block the spec.

## Prototype

No new directions were explored: the look was locked in spec 003 and the layout
decision (segmented ships, single scroll kept) was made in discovery. The only
prototype work was narrowing the 003 canvas to the Detail frames, as in 004.

Read-only design snapshot: `specs/006-recipe-details/design.html`. It is the
Detail frames of the 003 snapshot (`specs/003-design-all-screens/design.html`,
frames 8, 9, 12, 13), plus tables of the tokens and components this screen
needs. It is regenerated by hand from the 003 snapshot and goes stale if that, or
the live 003 canvas (the source of truth), is edited afterward. About 42 KB, no
script, one inlined photo (Petit Gâteau).

- **A, segmented (ships):** A1 Ingredients selected, A2 Steps selected.
  The bet: the page fits one screen and the user picks what to read. It gives up
  seeing ingredients and steps together while cooking.
- **B, single scroll (kept, not built):** B1 at full length, B2 with no image
  (also the reference for the deferred no-image hero). The bet: everything on one
  page, nothing to tap. It gives up a short first screen. Every token it needs
  (separator, 48pt rows, Title 2) is in the table, so a swap needs no new token
  work.
- **Left out on purpose:** Library and Filters frames, the loading and error
  frames (deferred to the roadmap), the hand-drawn back button (native in
  SwiftUI; the frames draw a plain white circle only to mark where it sits).

What the narrowing surfaced (changes to the "Missing tokens" list above):

- **New:** Title (28 bold), Title 2 (22 bold), separator (ink at 12%), spacing 24,
  radius 28 (body sheet), hero overlap 28, hero heights 280 and 320, ingredient
  row minimums 48 and 52, step number 28, icon size medium (20).
- **Off-scale values map to the scale**, as 004 did for 10pt: badge gap 6 to 8,
  step gap 14 to 12, section gap 28 to 24. The 28 sheet radius and overlap stay.
- **Native controls:** the segmented control (`Picker` `.segmented`) and the back
  button are system-drawn on iOS 26, so they will not match the mock's green-filled
  segment; they are not rebuilt.
- **Reuse:** `RecipeImageView` becomes the hero with height and icon-size
  parameters. The vegetarian badge is new (white on green, text); the card's leaf
  mark stays icon-only.
- **Already existing:** Green, Ink, Mist, ink at 66% and 8%, the Body, Subheadline
  and Footnote roles (the Body role is named `searchText` today; new roles are
  named for their use).
