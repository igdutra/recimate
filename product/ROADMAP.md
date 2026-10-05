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
| C | Recipe Library | V1, V2, V3 | 003 (design prototype for C, D, E), 004 (loaded state) | loaded state done (004); error state in milestone E's shared error pass |
| D | Search + Filtering | S1–S6, E3 (filter side), E1 (no-results half) | 008 | in discovery |
| E | Recipe Details | E2, E1 (error half, Library and Details) | 006 (loaded state) | loaded state done (006); shared error pass pending, no spec yet |
| F | Polish + README | R1–R6, P2 | | not started |

The user flow the milestones build toward:
`Library → search / Filters sheet → Recipe Details`.

## Milestones

**A. Foundation + Data Contract.** Domain model, transport (DTO) types, the
bundled JSON fixture. No loading or mapping code. See
[notes](../specs/001-foundation-data-contract/notes.md).

**B. Recipe Data Layer.** The API-shaped boundary: a protocol the app depends
on, a local implementation backed by the fixture, DTO → domain mapping, typed
errors, async calls, and the decoding tests, so a network client could replace
it later. Also switches the project to Swift 6 language mode (P1).

**C. Recipe Library.** The list or grid screen and its view model, with
error and no-results states. Each recipe shows its title, servings and a
vegetarian indicator. Delivered in steps:

- Spec 004: the Library in its loaded state only, with the search field drawn
  but inert (it prints). Light mode only. Spec 004 also drew two quick chips,
  which the brief does not ask for; spec 008 removes them (see
  [BACKLOG.md](BACKLOG.md), "Quick filter chips").
- Error and no-results states (E1) are mandatory. No-results lands in spec 008,
  because a search is what produces it, using the system
  `ContentUnavailableView.search`. The error state is built together with the
  Details error state, in one shared pass under milestone E (see below). Loading
  and empty-collection states are outside the brief and live in
  [BACKLOG.md](BACKLOG.md).

**D. Search + Filtering.** The search endpoint (S1–S6) behind the data layer,
plus the minimal UI that drives it (spec 008):

- The search endpoint: no filters returns everything; vegetarian, servings,
  include ingredients, exclude ingredients and instruction text are each
  optional. The local fake server does the filtering.
- The native search field, searching instruction text (S6).
- A Filters sheet, opened from the toolbar button, with the four other
  filters. It applies live.
- The edge cases (the same ingredient included and excluded, empty strings,
  recipes with unknown ingredient data, what "servings" means) are decided and
  documented (E3).
- The Library's no-results state (E1), using the system `ContentUnavailableView.search`.
- Nothing else. Chips, search tokens, servings ranges, an Apply button with a
  result count, title search and vegan, difficulty, course and cuisine filters
  are outside the brief (see [BACKLOG.md](BACKLOG.md)).

**E. Recipe Details.** The detail screen: title, description, servings,
vegetarian indicator, ingredient quantities and numbered cooking instructions.
Also the intentional failure (E2) shown through the view state and
`ContentUnavailableView`, with a retry action. Delivered in steps:

- Spec 006: the Details screen in its loaded state only (segmented
  Ingredients / Steps layout, native back button, full-bleed hero).
- **Error states, one shared pass for both screens (E1, E2).** The Library's error
  state (a failed load, and a failed search, since search runs through the same
  view model) and the Details error state (E2, with Try Again) are built together,
  with one `View+StateOverlay` view extension: a state-driven overlay over a stable
  content view, with `ContentUnavailableView` for the error, on top of the
  `ViewState` introduced in spec 004. On the Library the search field and the
  Filters button stay on screen under the overlay, so a failed search can be
  retried or changed, and Try Again re-runs the current query (the view model
  already allows `load()` again after an error). On Details, until this lands, a
  tap on a recipe with no detail file (6 of 9, plus `creamy-tomato-pasta`) opens a
  blank screen. Mandatory, so it lives here and not in the backlog. Needs its own
  spec. What changes when it lands: both screens drop their "blank unless loaded"
  branch for the overlay; the Details frame's "Back to Recipes" button is
  redundant with the native back button and is dropped or kept as a decision then;
  new constants (the 80pt badge circle) are declared inline in the view that uses
  them (see spec 007).
- Still to do, separate from the error pass: loading and the no-image hero on
  Details. Neither is in the brief (see [BACKLOG.md](BACKLOG.md), "Loading and
  empty-collection states"); whether they stay here or move to the backlog is
  decided when Details is next scheduled.

**F. Polish + README.** Final full test run and the README sections R2–R6.
The accessibility and visual pass is outside the brief and lives in
[BACKLOG.md](BACKLOG.md).

## Rules that apply to every milestone

- Tests and previews ship with the milestone, not at the end. F does not
  catch up on testing.
- Every assumption, tradeoff or limitation found while building goes into that
  spec's `implementation-notes.md` the moment it comes up. F collects them
  into the README instead of reconstructing them from memory.
- When a milestone finishes, update the Status column above.
