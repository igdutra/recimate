# Roadmap

Each milestone is lettered (A, B, C...) and is delivered by one or more specs
in `specs/NNN-slug/`, built with the
`/discovery → /spec → /implement-spec → /qa → /finish` workflow. The IDs refer
to [REQUIREMENTS.md](REQUIREMENTS.md).

**Letters are milestones, numbers are specs.** The roadmap lays out the raw
features; spec numbers are assigned in order of creation by `/discovery`, and
work that sits between milestones (such as the design pass, spec 003) takes a
number without moving the letters. Specs 001 and 002 were written when
milestones used numbers, so their text still says "003" or "004" for what is now
milestone C or D.

```
A Foundation + Data Contract
        ↓
B Recipe Data Layer
        ↓
C Recipe Library
        ↓
D Search + Filtering
        ↓
E Recipe Details
        ↓
F Polish + README
```

| Milestone | Name | Closes | Specs | Status |
|---|-----------|--------|-------|--------|
| A | Foundation + Data Contract | D1, D2 | 001 | done |
| B | Recipe Data Layer | D3, E3 (data side), P1 | 002 | done |
| C | Recipe Library | V1, V2, V3, E1 | 003 (design prototype for C, D, E), 004 (loaded state) | in progress |
| D | Search + Filtering | S1–S6, E3 (filter side) | | not started |
| E | Recipe Details | E2 | | not started |
| F | Polish + README | R1–R6, P2 | | not started |

The user flow the milestones build toward:
`Library → search / quick filters → Filters sheet → Recipe Details`.

## Milestones

**A. Foundation + Data Contract.** Domain model, transport (DTO) types, the
bundled JSON fixture. No loading or mapping code. See
[notes](../specs/001-foundation-data-contract/notes.md).

**B. Recipe Data Layer.** The API-shaped boundary: a protocol the app depends
on, a local implementation backed by the fixture, DTO → domain mapping, typed
errors, async calls, and the decoding tests, so a network client could replace
it later. Also switches the project to Swift 6 language mode (P1).

**C. Recipe Library.** The list or grid screen and its view model, with
loading, empty and error states. Each recipe shows its title, servings and a
vegetarian indicator. Delivered in steps:

- Spec 004: the Library in its loaded state only, with the search field and
  quick chips drawn but inert (they print). Light mode only.
- Still to do: loading, error, empty and no-results states. Mandatory, not
  optional polish, so they live here and not in the backlog. They are handled
  with the `View+StateOverlay` pattern (state-driven overlay over a stable
  content view, `ContentUnavailableView` for error and empty) on top of the
  `ViewState` introduced in spec 004.

**D. Search + Filtering.** The search endpoint (S1–S6) behind the data layer,
plus the search bar and filter UI that drive it:

- Quick controls on the library: a vegetarian toggle, a serving-range control
  (`1–2`, `3–4`, `5+`) and a button that opens the Filters sheet.
- Filters sheet: vegetarian toggle, one mutually exclusive servings range,
  separate include and exclude ingredient selection, instruction text search,
  and Clear All / Apply Filters. Open questions on ingredient entry and apply
  behaviour are in [BACKLOG.md](BACKLOG.md).
- Selected state is communicated accessibly, not by colour alone.
- Only the filters the brief asks for are built. Vegan, difficulty, course and
  cuisine filters are outside the brief and the recipe data cannot support
  them (see [BACKLOG.md](BACKLOG.md)). The look and interaction come from the
  spec 003 design pass.

**E. Recipe Details.** The detail screen: title, description, servings,
vegetarian indicator, ingredient quantities and numbered cooking instructions.
Also the intentional failure (E2) shown through the view state and
`ContentUnavailableView`, with a retry action.

**F. Polish + README.** Accessibility and visual pass (labels, Dynamic Type
checks), final full test run, and the README sections R2–R6.

## Rules that apply to every milestone

- Tests and previews ship with the milestone, not at the end. F does not
  catch up on testing.
- Every assumption, tradeoff or limitation found while building goes into that
  spec's `implementation-notes.md` the moment it comes up. F collects them
  into the README instead of reconstructing them from memory.
- When a milestone finishes, update the Status column above.
