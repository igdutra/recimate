# Backlog

Ideas outside the challenge brief ([REQUIREMENTS.md](REQUIREMENTS.md)), not yet
scheduled in [ROADMAP.md](ROADMAP.md). Each gets scoped when it moves there.

## Pagination

Load the recipe list in pages instead of all at once, for example a 100-recipe
JSON read 10 at a time as the user scrolls. The service and view model only see
pages; the local client does the slicing, like a server would.

## Cancellation handling

Make a cancelled load (a `.task` that goes away, a search keystroke in milestone D) not
show up as `unavailable`. The local client cannot throw `CancellationError`, so
milestone B (spec 002) dropped the handling and its tests. Add it back, with a test,
together with the URLSession client: rethrow `CancellationError` (and map
`URLError(.cancelled)` to it) before the services' catch-all.

## Search by title / description

Free-text search over recipe title and description. The brief only asks for
search within instruction text (S6), so this is extra scope. Undecided: if
wanted, it needs its own requirement ID before moving to the roadmap.

## Features that need new recipe data

Each needs its data contract and UI defined before it is scheduled. None can be
built truthfully from the current fixture.

| Feature | Why defer it | Required new data |
| --- | --- | --- |
| Vegan / gluten-free / allergens | Useful, but beyond the required vegetarian filter | Dietary flags and reliable allergen handling |
| Difficulty | Helpful discovery filter | A consistently authored difficulty value |
| Course and cuisine | Common discovery filters, but adds taxonomy work | Course and cuisine values per recipe |
| Prep / cook time | Useful metadata | Prep and cook durations per recipe |
| Favourites | Requires persisted user state | Favourite storage and UI state |
| Cooking Mode | Outside the agreed scope | Step-progress state, timers, screen-awake behavior |
| Nutrition / calories | Requires trustworthy nutrition data | Nutrition facts per serving |

## Observability

Logging (for example `os.Logger`, injected into the services) and analytics: see
what failed in the field, such as the `reason` of an `invalidData` or the cause
behind an `unavailable`, without the services validating or masking the
backend's data. Not part of the challenge; nothing in the data layer logs today.

## Ingredient entry for include/exclude filters

How the user enters ingredients in the Filters sheet: free text, comma-separated
tokens, or a picker over known ingredient ids. A picker needs a source of known
ingredients, but list previews carry none and only 3 recipes have a details file,
so the choice depends on the data. Not scoped in the design pass (spec 003);
the design draws the rows as plain placeholders. Decide in milestone D.

## Filter apply behaviour and result count

Whether the Filters sheet applies changes live or on an "Apply Filters" button,
and whether the button shows how many recipes match ("Apply Filters, 12
recipes"). A live count needs a count query against the search endpoint. The
design pass draws a plain "Apply Filters" button with no count; the count is
optional polish.
