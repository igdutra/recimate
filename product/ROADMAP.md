# Roadmap

Each milestone is one spec in `specs/NNN-slug/`, built with the
`/discovery → /spec → /implement-spec → /qa → /finish` workflow. The IDs refer
to [REQUIREMENTS.md](REQUIREMENTS.md).

```
001 Foundation + Data Contract
        ↓
002 Recipe Data Layer
        ↓
003 Recipe List
        ↓
004 Search + Filtering
        ↓
005 Recipe Details
        ↓
006 Polish + README
```

| # | Milestone | Closes | Status |
|---|-----------|--------|--------|
| 001 | Foundation + Data Contract | D1, D2 | done |
| 002 | Recipe Data Layer | D3, E3 (data side), P1 | not started |
| 003 | Recipe List | V1, V2, V3, E1 | not started |
| 004 | Search + Filtering | S1–S6, E3 (filter side) | not started |
| 005 | Recipe Details | E2 | not started |
| 006 | Polish + README | R1–R6, P2 | not started |

## Milestones

**001 Foundation + Data Contract.** Domain model, transport (DTO) types, the
bundled JSON fixture. No loading or mapping code. See
[notes](../specs/001-foundation-data-contract/notes.md).

**002 Recipe Data Layer.** The API-shaped boundary: a protocol the app depends
on, a local implementation backed by the fixture, DTO → domain mapping, typed
errors, async calls, and the decoding tests, so a network client could replace
it later. Also switches the project to Swift 6 language mode (P1).

**003 Recipe List.** The list or grid screen and its view model, with
loading, empty and error states.

**004 Search + Filtering.** The search endpoint (S1–S6) behind the data layer,
plus the search bar and filter UI that drive it.

**005 Recipe Details.** The detail screen and the intentional failure (E2) shown
through the view state and `ContentUnavailableView`.

**006 Polish + README.** Accessibility and visual pass, final full test run,
and the README sections R2–R6.

## Rules that apply to every milestone

- Tests and previews ship with the milestone, not at the end. 006 does not
  catch up on testing.
- Every assumption, tradeoff or limitation found while building goes into that
  spec's `implementation-notes.md` the moment it comes up. 006 collects them
  into the README instead of reconstructing them from memory.
- When a milestone finishes, update the Status column above.
