Created: 2026-10-03
Updated: 2026-10-03

# 001 Foundation + Data Contract

Data modeling by Ivo, reviewed with Claude. Built directly, no `/spec`.

Closes D1, D2 from [REQUIREMENTS.md](../../product/REQUIREMENTS.md).

## What drove the model

- **Domain and transport are separate.** `Domain/` knows nothing about JSON;
  `API/` DTOs mirror the wire contract. A real API can replace the bundled
  JSON without touching views.
- **DTOs are pure contract.** No mapping, `Decodable` only, explicit
  `CodingKeys` so the snake_case contract stays readable.
- **Ingredient IDs are stable across recipes**, so filters can match on them.
- **`summary`, not `description`**, to avoid clashing with
  `CustomStringConvertible`.
- **List of previews, then details on demand**, like real recipe APIs:
  `GET /recipe-list` → `RecipeListDTO` of `RecipePreview`s for `RecipeListView`;
  `GET /recipe-details/{id}` → `RecipeDetailsDTO` → `RecipeDetails` for
  `RecipeDetailsView`.
- **One fixture file per endpoint response.** `RecipeList/recipe-list.json` lists all 9
  previews; `RecipeDetails/<id>.json` holds a full recipe. Only 3 recipes have
  one, which gives the detail screen its three cases (E2):
  - `petit-gateau`, `lemon-herb-chicken`: load.
  - `creamy-tomato-pasta`: malformed step, a real `DecodingError`.
  - every other recipe: no file, so the fetch fails as not found.
- **Conformances only when needed.** Nothing beyond `Identifiable` and
  `Decodable` until a feature asks for it.
