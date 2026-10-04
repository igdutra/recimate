# 006 Recipe Details: implementation notes

## Assumptions

- Hero: `ScrollView` with `.ignoresSafeArea(edges: .top)` and a 280pt `RecipeImageView`; to be confirmed on the simulator.
- Sheet background uses `.background` (the system background) rather than a color literal.
- `ServingsLabelFormatterTests` has no helpers: it is a pure function with nothing to build.

## Deviations

- `TASKS.md` and these notes were created after the code, not alongside it, against the spec's `Task list: yes`.
- The spec's AC19 greps use `rg -L`, which in ripgrep means "follow symlinks", not "files without match". Used `--files-without-match` instead.
- Not verified: tapping through Library -> Details on the simulator (AC1, 3, 6, 9, 10, 15). `simctl` cannot tap and no UI automation is installed, so this needs a manual pass.
- Ingredient rows have a divider (`Color.separator`) although the design table says "single scroll only": the mock's CSS rules every row in layout A too, and the user asked for it.
- Vegetarian badge padding is 12 sides, 4 top and bottom (about 24pt high); the mock is 28pt high with 10pt sides, which are off the scale and have no token.
- Bottom padding of the sheet is 24 (`Spacing.extraExtraLarge`); the mock's 48 is in no table.
- The segmented `Picker` is tinted through `UISegmentedControl.appearance()` (green selected segment, mist track). Global to the app; SwiftUI has no modifier for it. Whether iOS 26 honors it is unconfirmed.
- Typography: `servings` and `stepNumber` repeat the weights of `chipLabel` and `cardTitle`; kept as separate roles because the spec's Step 1 lists them.
