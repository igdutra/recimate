Created: 2026-10-05
Updated: 2026-10-05

# 011 Final refactors

The last items of the to-do list, worked through with Claude. Built directly, no
`/spec`. Each one was checked against what other practitioners do before
changing anything; the long reasoning and the sources are in
[docs/decisions.md](../../docs/decisions.md).

## View models are created by the views that own them

- **Before:** the composition root built the view models in `body` and handed
  them to the views, which stored them with `State(initialValue:)`. Every `body`
  evaluation made a new one, and the root's reference to the Library view model
  could drift from the one the grid kept, so the Filters sheet could end up
  talking to a different instance.
- **Now:** `ReciMateApp` builds only the services and forwards them, as Domain
  protocols, down the chain. The owning view creates its view model in `init`
  (the Hacking with Swift pattern):
  - `RecipeDetailsView(recipeID:service:)` creates its own.
  - `RootView` creates the Library one, because the grid and the Filters sheet
    share it and `RootView` is the lowest view holding both.
  - `RecipeLibraryView` and `FiltersSheetView` take theirs as a plain property.
- **Tried and dropped:** a factory closure called in `.task` into an optional
  `@State` (Apple's `State` documentation shows it). It works, but reads worse
  for no gain at this size.
- **Known costs, accepted:** a re-init builds a view model that `State` discards
  (cheap: `init` only stores its arguments), and a changed input would be
  ignored (cannot happen: a new route is a new view). Xcode 27's `@State` macro
  removes the first one; the project builds with Xcode 26.5.

## View data changes field by field

- **Before:** every view data field was `let`, and each change rebuilt the whole
  struct through a helper that copied every field.
- **Now:** the fields are `var` and the view models write only what changed
  (`viewData.state = .loading`), as state structs are usually handled. Still a
  struct, still `Equatable`, still `private(set)` on the view model.
- **Exception:** the Filters view data is derived in full from the filters, and
  one action can move several fields, so it is still rebuilt from them.

## `invalidData(reason:)` sanity check

- Kept as is. `reason` is `String(describing:)` of the `DecodingError`, which
  names the missing key, the wrong type and its path, or "not valid JSON";
  `localizedDescription` would only say "couldn't be read". A `String` keeps
  `RecipeError` `Equatable` and `Sendable`. It is never shown.
- Only the doc comment changed: it used to promise a key and a path, which
  invalid JSON does not have.

## Docs

- `docs/decisions.md`: "Views get finished view data" rewritten, and a new
  entry, "Each view model is created by the view that owns it".
- `README.md` and `docs/architecture.md` (the diagram now shows `RootView` and
  `RecipeDetailsView` creating their view models).
