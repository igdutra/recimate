# Assumptions, tradeoffs and limitations

The full list behind the README's short version. Each spec's own notes are in `specs/<slug>/implementation-notes.md`.

## Assumptions and tradeoffs

- **Matching** ignores case and accents and uses "contains". Include terms must all match (AND); a recipe with any excluded term is dropped. Ingredients match by name.
- **Conflicting filters:** the same ingredient included and excluded returns nothing, not an error. The Filters sheet prevents it: adding a term to one list removes it from the other.
- **Empty input:** blank or whitespace-only text and terms are dropped before the request is built. Vegetarian off means no filter, never "non-vegetarian only". Servings is an exact match.
- **Malformed data:** a broken or missing detail is our data's fault, so it shows an error with Try Again, not an empty screen. Missing photos, quantities or steps are valid and are shown as absent.
- **Errors:** one message per error kind, worded to fit either screen. The decoder's technical reason is kept on the error for debugging, never shown.
- **"Found in the steps"** is decided in the app, because the card already has the title. A real backend with smarter matching (stemming, synonyms) would have to return where the match was.

## Known limitations

- The mock API waits one second on every request, to make the loading state visible.
- The search cache is a plain in-memory dictionary: no expiry, refresh, invalidation or size limit. Fine for static local data, not for a real backend ([details](decisions.md#search-result-cache)).
- A `+` in a query value is not percent-encoded, so a real server could read it as a space.
- Search is one phrase: no multi-word matching, ranking beyond "titles first", or highlighting of the matching step.
- The servings picker offers 1 to 8; a backend with larger servings counts would need a different control.
- Light mode only; no accessibility pass, UI tests or snapshot tests yet. Navigation has no unit tests (planned with ViewInspector). These and other extras are in [`product/BACKLOG.md`](../product/BACKLOG.md).
