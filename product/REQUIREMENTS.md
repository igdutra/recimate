# Requirements

The challenge brief, rewritten as a checklist with stable IDs. Every spec in
`specs/` names the IDs it closes under `## Requirements / What`, and
[ROADMAP.md](ROADMAP.md) tracks which spec covers which ID.

An ID is closed when a test or a preview shows it working, not when code exists.

## Data

- **D1** A recipe has: title, description, number of servings, ingredients, cooking instructions, dietary attributes (at least vegetarian).
- **D2** Recipes load from a `.json` file bundled with the app (mock API response). No network calls for data.
- **D3** The code is structured as if the data came from a real API: transport types are separate from domain types, and the loading boundary can be swapped for a network client without touching views.

## Views and view models

- **V1** Recipes are shown in a clean, intuitive list or grid.
- **V2** Views are backed by view models; views hold no loading or filtering logic.
- **V3** Every screen has SwiftUI previews, covering its non-happy states too.

## Search

- **S1** A search endpoint takes optional query filters. With no filters it returns everything.
- **S2** Vegetarian filter.
- **S3** Servings filter.
- **S4** Include ingredients filter.
- **S5** Exclude ingredients filter.
- **S6** Search within instruction text.

## Errors and constraints

- **E1** Error and no-results states are each handled explicitly in the UI (`ContentUnavailableView` where it fits). Loading and empty-collection states are outside the brief (see [BACKLOG.md](BACKLOG.md)).
- **E2** One recipe fails on purpose when its detail opens, and the app shows a recoverable error screen for it instead of crashing or showing a blank view.
- **E3** Constraints and edge cases (malformed data, conflicting filters such as the same ingredient included and excluded, empty strings) are decided and documented, not left to chance.

## Platform

- **P1** Swift and SwiftUI, targeting iOS 26+.
- **P2** Swift Packages only if they earn their place; each one is justified in the README.

## Deliverables

- **R1** A complete Xcode project that builds and runs on a clean checkout.
- **R2** README: setup instructions.
- **R3** README: high-level architecture overview.
- **R4** README: key design decisions.
- **R5** README: assumptions and tradeoffs.
- **R6** README: known limitations.

## How it gets judged

Reviewers look at coding style, design intuition and developer mindset. These are
not checkboxes, but every spec should be reviewed against them:

- Logical, intuitive user experience.
- Idiomatic SwiftUI and use of the platform frameworks.
- Naming conventions.
- Documentation of assumptions and unclear boundaries.
- Handling of errors and constraints where needed.
