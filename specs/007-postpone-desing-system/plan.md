# 007 Postpone the design system

## Decision

Spec 004 (Library) and spec 006 (Details) introduced a design token layer in
`ReciMate/Presentation/DesignTokens/`: `Spacing`, `Typography`, `Radius`,
`Sizing` and `Colors`. We built it, then reviewed it and decided it is too early.
With two screens there is not enough evidence about which values are really
shared, so the tokens were mostly one-use names (`Sizing.stepNumber`,
`Radius.bodySheet`, `Typography.servings`) that added indirection without
adding consistency. `Spacing.small` alone stood for five unrelated things.

A design system is still the right long-term move. It is postponed, not
dropped, until more screens exist and the tokens are better understood. It is
logged in `product/BACKLOG.md` under "Design system".

This refactor is also an experiment: for the MVP, values live in the view that
uses them.

## What changed

| Token set | Now |
|---|---|
| `Colors.swift` | Kept as is. The colors (`ink`, `mist`, accent and the derived ones) are stable and shared. |
| `Spacing`, `Radius`, `Sizing` | Deleted. Values are inline in the view (see the rule below). |
| `Typography` | Deleted. Views call the font modifier directly (`.font(.subheadline.weight(.semibold))`). System text styles only, so Dynamic Type keeps working. |

## The rule

- **One-off and obvious: inline.** `.padding(12)`, `spacing: 8`,
  `.font(.system(size: 14))`. A short comment where the number is not obvious
  (`44` touch target, the Dynamic Type minimums).
- **Repeated: extract it**, as close to its users as possible:
  - Used twice in one view: a `private extension` with a nested `Constants`
    enum, right under that view (`RecipeGrid`: column minimum and grid gap).
  - Not self-explanatory: same (`RecipeDetailsPage`: hero height and overlap).
  - Owned by one component and read by another: a `static let` on the owner
    (`VegetarianMarkView.iconSize`, which the card's detail row reads, so the
    two cannot drift apart).
  - A component's own internal value is private to it (`PlaceholderIcon` owns
    its 36pt icon, so `RecipeImageView` lost its `placeholderIconSize`
    parameter).
  - Shared across screens: `Layout.screenGutter` (20) in
    `Presentation/Shared/Layout.swift`, used by the grid, the chip bar and the
    Details sheet. It is the only shared value and the first candidate for the
    design system.
- Unused tokens were dropped, not carried over (`screenTitle`, `searchText`,
  `sectionTitle`, the `SingleScroll` variants).
- Values are unchanged. No visual change intended.

Pattern for a `Constants` block:

```swift
// MARK: - RecipeGrid

private struct RecipeGrid: View { ... }

private extension RecipeGrid {
    enum Constants {
        static let columnMinimumWidth: CGFloat = 160
        static let gridSpacing: CGFloat = 16
    }
}
```

`private` at file scope is `fileprivate`, so the enum is visible to the view and
its previews in the same file, and to nothing else.

## File layout

Each component in a file is divided by a `// MARK: - <Component>` (plus
`View data` for the plain data structs and `Preview` for previews), with the
component's constants directly under it.

## Notes

- Specs 004 and 006 still describe the token tables. They are history and are
  left untouched.
- The milestone E line in `product/ROADMAP.md` now says new constants (the 80pt
  badge circle and the 32pt loading icon) are declared inline.
- Hero overlap and sheet corner radius are both 28 in Details. They were not
  linked because it is not clear they must match.
- Verified: build and the full unit suite pass (56 tests). Not verified: the
  screens in previews or on the simulator; the values were copied one to one.
- Revisit when: a third screen lands, or the same value is copied into a third
  view.
