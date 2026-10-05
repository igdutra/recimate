Created: 2026-10-05
Updated: 2026-10-05

# 010 Title and step search: discovery

The **milestone D follow-up** in [ROADMAP.md](../../product/ROADMAP.md): the search
field finds a recipe by its title as well as by its cooking steps, a card says when
it was found only in the steps, and the no-results state repeats what was searched.
Closes the "intuitive UX" gap that spec 008 left by reading S6 literally. No new
requirement ID: S6 stays met on the endpoint, and the fix serves the brief's stated
judging criterion, "logical and intuitive user experience".

Inputs read: the roadmap, backlog and requirements; spec 008 notes;
`RecipeLibraryView`, `RecipeLibraryViewModel`, `RecipeCardView`, `RecipeSearchQuery`
(with `SearchTextMatching`), `RecipeEndpoint`, `LocalRecipeSearchServer`,
`FiltersViewModel`, `recipe-catalog.json`; Apple's documentation and HIG (below);
web research (below).

## The problem

Spec 008 made the field search instruction text only. Typing a recipe's name, such
as "Pet" for Petit Gâteau, shows "No Results" while that recipe is on screen. The
prompt says "Search instructions", but nobody reads a prompt before typing a name.
Two more things surfaced during discovery:

- **The no-results view does not show the query.** The view uses the bare
  `ContentUnavailableView.search`, which reads the query from the enclosing
  `.searchable` on its own. Apple's documentation says the view must be *contained
  within* the searchable hierarchy, and every community write-up puts the overlay
  *before* `.searchable`. `RecipeLibraryView` puts it after, with a comment claiming
  the opposite. Not confirmed in the simulator; the decision below makes the order
  irrelevant.
- **The no-results view is search-specific even when only filters caused it.**
  With no text and filters that match nothing, "No Results" plus "Check the spelling
  or try a new search" is wrong advice.

## Research

**Search everything by default.** NN/g: users "overlook, misunderstand, and forget
about the search scope", so the default must be "all"; scoped search is only worth
it for large, diverse catalogs
([Scoped Search](https://www.nngroup.com/articles/scoped-search/),
[Search and You May Find](https://www.nngroup.com/articles/search-and-you-may-find/)).
Apple's HIG says the same: "Default to a broader scope and let people refine it as
they need", a scope bar only "to filter among clearly defined search categories"
([Search fields](https://developer.apple.com/design/human-interface-guidelines/search-fields)).
SwiftUI's native picker is `searchScopes(_:activation:_:)` (iOS 16.4+). The one
recipe app found with scopes, Paprika, defaults to Name and offers Ingredients,
Directions and more as options
([Paprika guide](https://www.paprikaapp.com/help/ios/)): a power-user recipe
manager, not a nine-recipe browser.

**Tokens solve a different problem.** The HIG: "Use tokens to filter by common
search terms or items" (`searchable(text:tokens:)`). They are discrete filter values
(Vegetarian, "with eggs"), the Filters sheet's job, not a way to choose which text
a search reads.

**Show why a result matched.** Without a match location, users "can't tell why a
result matched without opening it"
([match-location UX issue](https://github.com/Fooftilly/PRKS/issues/418)). Apple's
own apps show it either by grouping (Mail and Notes "Top Hits", sections by kind,
[Notes Top Hits](https://danstutorials.com/tutorials/tutor-for-notes/lessons/iphone-lessons-for-notes-2/topics/new-in-ios-14-top-hits-in-search-results/),
[Mail search](https://www.macobserver.com/tips/how-to/apple-mail-how-to-search/))
or by a snippet. The HIG: "Provide the most relevant search results first".

**No results.** NN/g: say clearly there are no matches, echo the query, offer a
way forward ([No Results guidelines](https://www.nngroup.com/articles/search-no-results-serp/)).
SwiftUI: `ContentUnavailableView.search(text:)` (iOS 17+) renders the query into
the message; the bare `.search` reads it from the enclosing `.searchable`
(Apple's documentation;
[Swift with Majid](https://swiftwithmajid.com/2023/10/31/mastering-contentunavailableview-in-swiftui/)).

## Decisions

1. **One field searches titles and steps. No scope picker, no tokens.** A recipe
   matches when its title or any single step contains the search text. This is the
   broad default both NN/g and the HIG ask for. A picker (All / Title /
   Instructions) adds a control nine recipes don't need, and the research says
   people forget it is there. Tokens filter by values and would duplicate the
   Filters sheet; they stay in the backlog with a note asking whether they would
   add anything over the current sheet.
2. **The match rule stays the simple phrase "contains".** Ignoring case, accents
   and surrounding whitespace, through the existing `SearchTextMatching.text(_:contains:)`.
   "lemon chicken" does not find "Lemon Herb Chicken"; matching each word is in
   the backlog. Chosen for simplicity, and because it keeps "matched in the title"
   a yes-or-no question (decision 4).
3. **Title matches come first.** The server returns the title matches, then the
   step-only matches, each group in catalog order (a stable partition). Only when
   search text is present; with no text the order is the catalog's, as today.
   Ranking is the search engine's job, so it lives in the fake server, not in the
   app.
4. **A card found only in the steps says so** (direction B of the prototype,
   below). One extra line under servings: a small `list.bullet` icon in the accent
   green and the text "Found in the steps", footnote size in `inkSecondary`. A
   title match shows the card as it is today. The client decides this on its own:
   `RecipePreview` already carries the title, so a card is a step-only match when
   the search text is non-blank and the title does not contain it, using the same
   `SearchTextMatching` function the server uses. No API change.
   Assumption (documented in code and README): the client's rule and the server's
   rule are the same function here; a real backend with its own matching
   (stemming, synonyms) would have to return the match location in the response
   instead.
5. **Uneven rows are accepted.** A caption card is one line taller. Because title
   matches come first, at most one row per search mixes the two kinds; the grid
   already aligns cards to the top. Reserving an empty line on every card was
   rejected: blank space under every title match, all the time.
6. **The prompt is "Search titles and steps"** (was "Search instructions"). It
   fits the iOS 26 bottom field and tells people what is searched before they type.
7. **No-results repeats what was searched and offers a way out.** Three cases,
   all `ContentUnavailableView`, all with the searched text taken from the view
   data (the text of the query that produced the empty result), never read from the
   live field: debounce means the field can already hold newer text.
   | Cause | Title | Description | Action |
   |---|---|---|---|
   | Text only | system `ContentUnavailableView.search(text:)`: No Results for "x" | system: Check the spelling or try a new search. | none |
   | Filters only | No Results | No recipes match these filters. | Clear Filters |
   | Text and filters | No Results for "x" | No recipes match this search with these filters. | Clear Filters |

   Same `magnifyingglass` symbol in all three. Clear Filters calls the existing
   `FiltersViewModel.reset()` through the Library view model and keeps the search
   text. The modifier-order comment in `RecipeLibraryView` is corrected, since the
   explicit text no longer depends on it.
8. **The endpoint keeps `instructions=` exactly as S6 says and gains `q=`.**
   `GET /recipes?q=<text>` matches title or any step; `instructions=<text>` still
   matches steps only. Both may be sent; each is one more condition (AND). Blank
   values are dropped in `RecipeEndpoint`, as today. The field sends `q`. `q` is the
   common name for a free-text query parameter.
9. **The test fixtures' titles are searchable.** "Creamy Tomato Pasta (Fails: Data)"
   and "Beef Tacos (Fails: Not Found)" match "fails" and "data". Harmless; one line
   in the notes.

## What changes, by layer

- **Domain.** `RecipeSearchQuery` gains `searchText` (title or steps; the field's
  text) next to `instructionText` (steps only, S6, not used by the UI). Neither
  counts as a filter; `resetFilters()` keeps both. `SearchTextMatching` is reused
  as is.
- **API.** `RecipeEndpoint.list(query:)` adds `q=<searchText>`.
  `LocalRecipeSearchServer` parses `q`, matches title or any step, and orders
  title matches first when `q` is present. Its doc comment's matching rules gain
  the two lines.
- **Presentation.**
  - `RecipeLibraryViewModel.didChangeSearch` writes `searchText` (was
    `instructionText`). `makeCard` takes the searched text and sets the new
    `RecipeCardViewData.isStepOnlyMatch`. A new `clearFilters()` calls
    `filtersViewModel.reset()`.
  - `RecipeLibraryViewData` gains `searchedText`: the trimmed text of the query
    that produced `cards`, set when a result is presented and carried unchanged by
    every other update (a filter change before its result arrives keeps the old
    one). It also says which no-results case applies (text, filters, both).
  - `RecipeCardView` shows the caption row when `isStepOnlyMatch`. It is part of
    the card's combined accessibility element, so VoiceOver reads it after the
    title and servings.
  - `RecipeLibraryView`: new prompt, the three no-results views, Clear Filters,
    corrected comment.
- **Previews (V3).** Library searching with mixed matches (the "roast" case);
  the three no-results cases; the card variant with the caption; large Dynamic
  Type with the caption.
- **Tests.** Endpoint: `q` encoded, blank dropped, both `q` and `instructions`.
  Server: title match, step match, neither, title matches first in a stable order,
  `q` and `instructions` together, accent and case folding on titles ("gateau"
  finds "Petit Gâteau"). Query: `resetFilters()` keeps `searchText`. View model:
  `didChangeSearch` sends `searchText`; `makeCard` caption true and false and with
  blank text; `searchedText` follows the presented result, not the latest
  keystroke; the three no-results cases; `clearFilters()` keeps the text. Fixture
  tests: the "roast" example (1 title match, 2 step-only) against the real catalog.
- **Docs.** README: the item below under Architecture decisions (written in this
  discovery). Spec notes: decisions 2, 4's assumption and 9. Backlog: tokens note,
  multi-word matching, the matching-step entry updated.

## Out of scope

Scope picker, search tokens and suggestions, multi-word matching, description
search, a snippet of the matching step, highlighting the match, recent searches.
All in [BACKLOG.md](../../product/BACKLOG.md).

## README item

Added to the README's Architecture decisions:
**"One search field finds titles and steps, and a card says when the match was
only in the steps."** It explains the literal-S6 problem, the research (NN/g and
the HIG on broad default scope, tokens being for filters), why a caption beat
sections and a picker, and the client-side match assumption.

## Prototype

Two directions on one canvas, both the Library searching "roast" (Roasted
Vegetable Couscous matches by title; Lemon Herb Chicken and Sheet Pan Salmon only in
their steps):

- **B · Caption on the card. Chosen.** A flat grid, title matches first, and a
  step-only card carries one line, "Found in the steps". Bet: the smallest change
  that answers "why is this here?"; the grid, the card and the API stay as they
  are, and the caption is a value on the existing card view data. The user loved
  it on sight.
- **A · Two sections.** "Titles" and "In the steps" headers over the same cards,
  the Mail and Notes grouping pattern. It makes titles-first automatic, but gives
  up the flat grid, turns the view data into sections, and spends two headers'
  height on a nine-recipe catalog. Rejected for simplicity, the MVP's other stated
  goal.
- Not drawn, rejected earlier: a second cell type per match kind (the LinkedIn
  pattern, the user's first idea, too heavy for two kinds of match), a scope picker,
  and a prompt-only change (cheap, but a step-only match would still look random).

Canvas: https://claude.ai/artifact/U1DS24WAY7uCWLTaLj5p2Y (the live canvas is the
source of truth). Its editor file is not copied into the repo, at the user's
request; `/design --extract` rebuilds the sources from the URL if needed.

Read-only design snapshot: `specs/010-title-and-step-search/design.html`. It is
regenerated by hand from the canvas and goes stale if the canvas is edited
afterward. Photos are drawn as labelled tiles to keep the file small.

## Open questions

None.
