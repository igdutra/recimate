# Backlog

Ideas outside the challenge brief ([REQUIREMENTS.md](REQUIREMENTS.md)), not yet
scheduled in [ROADMAP.md](ROADMAP.md). Each gets scoped when it moves there.

## Pagination

Load the recipe list in pages instead of all at once, for example a 100-recipe
JSON read 10 at a time as the user scrolls. The service and view model only see
pages; the local client does the slicing, like a server would.

## Cancellation handling

Make a cancelled load (a `.task` that goes away, a search keystroke in 004) not
show up as `unavailable`. The local client cannot throw `CancellationError`, so
milestone 002 dropped the handling and its tests. Add it back, with a test,
together with the URLSession client: rethrow `CancellationError` (and map
`URLError(.cancelled)` to it) before the services' catch-all.

## Observability

Logging (for example `os.Logger`, injected into the services) and analytics: see
what failed in the field, such as the `reason` of an `invalidData` or the cause
behind an `unavailable`, without the services validating or masking the
backend's data. Not part of the challenge; nothing in the data layer logs today.
