Created: 2026-10-04
Updated: 2026-10-04

# 003 Design all screens: discovery

> **Deliverable: the design only.** This spec has **no `SPEC.md`, no tasks and no
> code**. Its output is a prototype (an HTML artifact) showing every surface and
> state below, plus the color system. Later milestones (C, D, E in
> [ROADMAP.md](../../product/ROADMAP.md)) build the SwiftUI screens from it.
> This file records what the prototype must contain and the decisions behind it.

Inputs read: the earlier design exploration, `product/`, specs 001 and 002, the
domain types, DTOs and JSON fixtures.

**Trust level of the inputs.** The earlier design exploration (a scope note and
several mock screens) was AI-generated. It is a starting point, not a source of
truth. Every claim below was checked against `product/REQUIREMENTS.md` and what
the data model can truthfully show.

## Decisions

1. **Three surfaces, one extra frame.** Library, Filters sheet and Recipe Detail
   are the product surfaces. "Empty / no results" is a state of the Library. The
   prototype shows 4 frames plus the other states below.
2. **Deliverable is the prototype alone.** No spec file for 003.
3. **Ingredient entry for include/exclude is out of scope.** The sheet draws two
   placeholder rows. Backlog: "Ingredient entry for include/exclude filters".
4. **Apply behaviour and result count are out of scope.** The sheet has a plain
   "Apply Filters" button and "Clear All", no count. Backlog: "Filter apply
   behaviour and result count".
5. **Images:** a placeholder for a null `image_url` and for a failed load, plus a
   placeholder while loading. The fixture's images are remote hotlinks, so
   failure is a real case, not a hypothetical.
6. **Roadmap uses letters (A-F), specs use numbers.** Done in `ROADMAP.md`.
7. **Color system is part of the prototype.** See "Color system".

## Competitors and what each contributes

| Competitor | Role | Borrow | Do not copy |
|---|---|---|---|
| Paprika | Structure of the Library | Image-led collection, compact metadata (photo, title, servings, dietary mark), search inside the collection | Database-like density |
| Tasty | Appetite, and instruction scanning | Strong food photography, numbered steps, short chunks, generous spacing | Video feed, Cooking Mode |
| Kitchen Stories | Detail hierarchy | Large hero, title, facts, then description, dietary info, ingredients, directions | Editorial extras (save, share, related) |
| Mealime | Filters | Grouped categories, explicit servings, include/exclude, progressive disclosure | Its larger preference set |
| Yummly | Search and filter hierarchy | Prominent search, then quick choices, then a detailed sheet | Its wider filter taxonomy |
| Native iOS | States | Loading, empty and error conventions (`ContentUnavailableView`, placeholders) | Recipe-app-specific state art |

### Competitor x screen

| Screen / state | Paprika | Tasty | Kitchen Stories | Mealime | Yummly | Native iOS |
|---|---|---|---|---|---|---|
| Library | primary | secondary | | | search hierarchy | search, nav title |
| Filters sheet | | | | primary | secondary | sheet, toggle, segmented control |
| Recipe Detail | | secondary (steps) | primary | | | nav, back |
| Loading / empty / no results / error | | | | | | primary |

## Flows

```
launch -> Library (loading) -> Library (loaded)
                                 |-- type in search -> Library (filtered | no results)
                                 |-- tap quick chip (Vegetarian, Servings) -> Library (filtered | no results)
                                 |-- tap Filters -> Filters sheet -> Apply -> Library (filtered | no results)
                                 |                               \-> Clear All / close
                                 |-- tap "Clear Filters" on no results -> Library (all recipes)
                                 \-- tap a recipe -> Detail (loading) -> Detail (loaded | error)
                                                                          \-> Try Again -> Detail (loading)
          Library (error) -> Try Again -> Library (loading)
```

## Surfaces and states the prototype must show

| # | Surface | State | Source | Notes |
|---|---|---|---|---|
| 1 | Library | Loaded (2-column grid) | | Search, quick chips (Vegetarian, Servings, Filters), cards with photo, title, servings, vegetarian mark |
| 2 | Library | Loading | E1 | Native-feeling placeholders in the card grid, not a spinner on a blank screen |
| 3 | Library | Error (list failed to load) | E1 | "Couldn't load recipes", Try Again |
| 4 | Library | No results | E1 | The 4th frame. Shown with a search term and chips on, with a Clear Filters button |
| 5 | Library | Empty collection (no recipes at all) | REQUIREMENTS E1 | Different from no results: nothing to clear. Short copy, no action, or Reload |
| 6 | Library | Card with no / failed image | decision 5 | Placeholder tile with a neutral icon |
| 7 | Filters sheet | Default and with choices on | | Dietary toggle, Servings (1-2, 3-4, 5+), include/exclude rows, instruction search, Clear All, Apply Filters |
| 8 | Recipe Detail | Loaded | | Hero, back, title, vegetarian badge, description, servings, ingredients with quantity, numbered steps |
| 9 | Recipe Detail | Loading | E1 | Hero and text placeholders |
| 10 | Recipe Detail | Error (recoverable) | E2 | The intentional failure: `creamy-tomato-pasta` (malformed step) and the six recipes with no detail file. Message plus Try Again, and a way back to the list |
| 11 | Recipe Detail | No image | decision 5 | Hero placeholder; title must stay readable without a photo |

That is 3 surfaces and 11 frames. Rows 1, 7, 8 and 4 are the four core phones.

## Verdict on the earlier exploration

| Claim in the earlier exploration | Verdict | Why |
|---|---|---|
| 4 frames: Library, Filters, Detail, Empty | Keep, as 3 surfaces + states | An empty state is not a destination |
| "Recipes" nav title, search, chips, grid | Keep | Matches V1, S2, S3 |
| Mic icon in the search field | Drop | No voice search in the brief |
| Settings gear | Drop | Nothing to configure |
| Heart and share in Detail ("Recipe actions") | Drop | Favorites and sharing are out of scope |
| "Pescatarian" badge | Drop | The model has only `isVegetarian` |
| Prep / cook time, "30 min" | Drop | Not in the data; show it only when supported |
| Servings scaler ("Scale - 2 +") | Drop | `quantity` is free text ("200 g", "To serve"), so it cannot be scaled |
| Green check icons next to every ingredient | Change | They read as "checked off", a state we do not have. Use plain bullets or no marker |
| Empty circles next to ingredients | Drop | Implies a tappable checklist |
| Result count on Apply | Backlog | Decision 4 |
| Empty-state "Try these tips" card | Optional | Useful, but some tips refer to filters we draw as placeholders; keep one line of copy unless the prototype has room |
| Cooking Mode, "Cookbook", Vegan, Gluten-free | Drop | Out of scope; the model has no such data |
| Difficulty, Courses, Cuisines | Drop | Out of scope; each needs a new data contract |
| Quick chips duplicating the sheet's Vegetarian and Servings | Keep, with a rule | The chips and the sheet are two views of the same filter state; the prototype must show them agreeing |
| Servings buckets 1-2, 3-4, 5+ | Keep, with an assumption | The fixture holds 2, 3, 4, 5 and 6 servings, so each bucket has recipes. How the endpoint interprets buckets belongs to milestone D |

## Facts the design must respect

- **Library cards** show only `RecipePreview` fields: title, summary (optional on
  the card), servings, vegetarian flag, image.
- **Detail** shows only `RecipeDetails` fields: title, summary, servings,
  ingredients (name and free-text quantity), ordered instructions, vegetarian
  flag, image.
- **Titles and text have no length limit.** Design for 2-line titles ("Mediterranean
  Farro Salad") and long steps.
- **Remote images** load slowly or fail, so every image slot has a placeholder.
- **Only 3 of 9 recipes have details**, so a tap on most recipes ends in the
  error state. That is on purpose (E2), so the error frame is a primary design
  deliverable, not an afterthought.

## Color system

The earlier mocks use a single mid green on white (toggle, selected pill, Apply
and Clear Filters buttons, vegetarian leaf). The green is a visual guess from
the images and was not measured. The prototype should:

- Define semantic tokens (accent, accent-on-accent, surface, grouped surface,
  separator, label levels, success/vegetarian, danger), not raw hex values per
  component.
- Check text and icon contrast for light and dark mode. White text on a mid
  green is the likely failure (the Apply button label and the selected "3-4"
  pill). Fix by darkening the accent or by using dark text, not by shrinking
  the check.
- Map tokens to iOS semantics so SwiftUI can use them: `AccentColor` in the
  asset catalog (currently empty), `.primary` / `.secondary`, system backgrounds.
- Show dark mode and a large Dynamic Type size for at least the Library and
  Detail.
- Decide whether green carries two meanings (brand accent and "vegetarian").
  Keeping both the same green makes the vegetarian mark look like a button; the
  prototype should pick one answer and say why.
- Use iOS 26 materials (Liquid Glass) only where the system provides them
  (navigation bar, sheet, controls). Do not fake glass on cards.

## Open questions

**All of these are undecided.** The design is a direction, not a lock. Each
spec that builds a screen borrows only the frames it needs from `design.html`,
and answers the questions that touch those frames when it gets there. Nothing
below blocks the next spec unless it says so.

| # | Question | Status | Decided in | Assumed until then |
|---|---|---|---|---|
| 1 | Detail layout: single scroll (frame 8) or segmented Ingredients / Steps (frames 12-13) | Undecided | The Detail spec (milestone E), which gets its own design pass | Neither: the list spec does not build Detail |
| 2 | Empty collection: offer "Reload", or no action | Undecided | The list spec (milestone C), since the state lives on the Library | "Reload" |
| 3 | UI language: English only? One fixture recipe is Brazilian | Undecided | Not scoped to a spec; revisit in Polish (milestone F) | English |
| 4 | Search scope: does the main field match title only, or title and summary? The sheet's "Instructions" field is separate | Undecided | The search spec (milestone D) | Title only; the no-results copy must not promise more |
| 5 | Ingredient entry for include/exclude | In [BACKLOG.md](../../product/BACKLOG.md) | Milestone D | Plain disclosure rows |
| 6 | Filter apply behaviour and result count | In [BACKLOG.md](../../product/BACKLOG.md) | Milestone D | "Apply Filters", no count |
| 7 | Dark mode, large Dynamic Type, clickable flow between frames | Not designed yet | Before Polish (milestone F), or earlier if a spec needs them | Light mode only |

## Roadmap and backlog changes made

- `ROADMAP.md`: milestones lettered A-F; specs keep their own numbers; spec 003
  listed against milestone C (covers C, D, E designs).
- `BACKLOG.md`: added "Ingredient entry for include/exclude filters" and "Filter
  apply behaviour and result count".

## Prototype

First version, one direction (not several), built to iterate on. Live canvas:
https://claude.ai/artifact/YPs6m7Qxy416K5m3iL1yML (the canvas is the source of
truth).

Read-only design snapshot: `specs/003-design-all-screens/design.html`. It is a
static, script-free, single-file copy of all 15 frames (about 150 KB, photos
shrunk and inlined, the spinner drawn at one frame, nothing animated). It is
written by hand from the canvas and goes stale if the canvas is edited
afterward; regenerate it when that happens. Later phases read this file, not
the canvas.

- **Frames:** the 11 listed above, plus a segmented-control variant of Detail
  (two frames: Ingredients tab, Steps tab) shown under the single-scroll Detail
  to compare, plus two design-system boards. Data and photos come from the
  fixtures.
- **Photos:** the fixture's image links, downloaded and stored on the canvas
  (the canvas cannot hotlink). Two links are dead: Roasted Vegetable Couscous
  returns 404 and Mushroom Risotto does not respond. They are kept on purpose:
  they are real failed-image cases and the no-image placeholder covers them.
- **Library card:** mist background, 20 radius, photo on top, title and servings
  below, vegetarian leaf.
- **Loading:** one centered spinner in the iOS activity-indicator style (the
  native `ProgressView`), no skeleton or shimmer.
- **Detail:** two layouts to choose between. A single scroll (hero, facts,
  Ingredients, then Instructions) or a two-segment control that swaps
  Ingredients and Steps. Undecided.
- **Assumptions to react to:** the empty collection offers "Reload"; the
  ingredient rows are plain disclosure rows (entry is backlog); the Servings chip
  reads "3-4" once chosen.
- **Open questions:** all undecided, listed with their owner spec under "Open
  questions" below. The Detail layout is not needed for the list spec.
- **Not in this version:** dark mode, large Dynamic Type, a clickable flow between
  frames.

## Design system

Kept deliberately small. Three colors plus white; everything else is ink at an
opacity. The canvas has a Foundations board and a Components board; the values
are recorded here because later phases cannot open the canvas.

| Token | Value | Use |
|---|---|---|
| Green | `#2E7D4F` | Actions, selected state, vegetarian mark, step numbers. Becomes `AccentColor` |
| Ink | `#1B1F1D` | Text and icons. Secondary text is ink at 66% |
| Mist | `#EEF1EE` | Fields, cards, grouped sections, placeholders |
| White | `#FFFFFF` | The page |
| Separator, switch off, placeholder, scrim | ink at 12%, 25%, 8%, 45% | Dividers, off track, no-image tile, behind the sheet |

Contrast, measured: ink on white 16.7, ink on mist 14.6, white on green 5.05,
green on white 5.05, secondary text on white 5.4 and on mist 5.1, **green on mist
4.4 (below 4.5)**. So green is never body text on mist: the Vegetarian badge in
Detail is a green fill with white text, and green on mist is for icons only.

Type is the system font at system text styles (Large Title 34, Title 28, Title 2
22, Headline 17 semibold, Body 17, Subheadline 15, Footnote 13), so Dynamic Type
needs no custom scale. Corner radii: 12 (fields, rows), 16 (grouped cards), 20
(recipe card), 26 (capsules), 28 (sheet top). Spacing 4/8/12/16/20/24, screen
gutter 20, grid gap 16, minimum touch target 44.

Components (15): ten are native SwiftUI, tinted only (buttons, search, segmented
`Picker`, `Toggle`, disclosure row, `ContentUnavailableView`, `ProgressView`,
back button, sheet and `Form`). Five are custom: filter chip, recipe card, image
placeholder, vegetarian mark and badge, step row. The prototype draws some native
controls by hand (search, back button, segmented control); on iOS 26 the system
draws them as glass, so the SwiftUI will look different there and should not be
rebuilt to match.

How it becomes code (milestone C onwards): colors go into `Assets.xcassets` as
`AccentColor`, `Ink` and `Mist` (with dark variants later); radii and spacing as
a few constants in one `Theme` file; each custom component is a small view with
a preview. No third-party package.

## Next step

Iterate on the prototype. There is no `/spec` for this slug.

The next spec is the recipe list (milestone C). It borrows only the Library
frames (1-5) and the design-system tokens from this design, and carries its own
design file with just the Library. The Filters sheet and Detail get their own
design passes in their specs, which is when the undecided questions above are
answered.
