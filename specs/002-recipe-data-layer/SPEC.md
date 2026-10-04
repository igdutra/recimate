Created: 2026-10-03
Updated: 2026-10-04

# 002 Recipe Data Layer

Closes D3 and the data side of E3 ([REQUIREMENTS.md](../../product/REQUIREMENTS.md)).
Findings and rejected alternatives: [discovery.md](discovery.md). What changed
while building, and why: [implementation-notes.md](implementation-notes.md).

## Context / Why

Milestone 001 gave the app its recipe types and JSON fixtures but nothing that
loads them. The screens in 003 to 005 need a loading boundary that behaves like a
real API client (async, typed failures) while reading local files, so the
bundled JSON can later be replaced by a network client without touching a view
model or a view.

## Requirements / What

Nothing is visible on screen yet; the behaviour is observable through tests.

- Asking for the recipe list returns every recipe preview, in file order, with
  all fields. An empty list is a normal result, not a failure.
- Asking for one recipe's details returns the full recipe: ingredients, steps in
  step order, dietary attributes, optional photo.
- A recipe that does not exist is reported as "not found".
- Data that cannot be decoded as a recipe (malformed JSON, a missing key, a wrong
  type) is reported as "invalid data", with the decoder's reason. One undecodable
  item makes the whole list invalid.
- Decoded values are taken as the backend sent them. The app does not judge them
  (servings of 0, a blank title, duplicate ids, a detail file whose id differs from
  the one asked for all pass through). Validating the backend would hide what it
  actually sent; an MVP should not.
- Any other failure is reported as "unavailable". The caller never sees why.
- Ids that cannot name a recipe (blank, `.`, `..`) are "not found" without
  any lookup. Ids with special characters are looked up safely as one name.
- The intentionally broken recipe (`creamy-tomato-pasta`) reports "invalid
  data"; recipes without a detail file report "not found" (what E2 needs).

## Decisions / Architecture

1. **Two layers only: service over a client.** Services map and translate
   errors; the client only fetches bytes. Not adopting the longer chain
   (infra → data source → repository → use case → view): it would only forward
   calls. Recorded in the README later.
2. **The client takes a `URL` and returns `Data`**: `RecipeAPIClient.data(from:)`.
   Rejected: a resource-name string (hides the endpoint in each client, breaks
   when a real API needs paths or query items) and a generic DTO-returning
   method (the client would decode).
3. **`RecipeEndpoint` builds URLs**: one enum, `.list` and `.details(id:)`, with
   `url(baseURL:)`, using `URL.appending`. It is a basic setup; a production API
   would likely need `URLComponents` (query items arrive with search in 004).
   Rejected: two endpoint types (duplicated base-URL logic).
4. **Names.** Protocols `RecipeListService`, `RecipeDetailsService`,
   `RecipeAPIClient`. Concrete `RemoteRecipeListService`,
   `RemoteRecipeDetailsService`, `LocalRecipeAPIClient` (named for its role, a
   stand-in for a server; a URLSession client would be a sibling).
5. **Domain errors** `RecipeError`: `notFound`, `invalidData(reason:)`,
   `unavailable`. Only `invalidData` carries anything: the decoder's description
   as a string, so the error stays `Equatable` and the view model decides what to
   do with it. The client's contract error `RecipeAPIClientError.notFound` is owned
   by the client protocol so services never inspect Foundation errors.
   Cancellation is not handled yet (backlog).
6. **Four internal mappers**, two per service (`Data → DTO`, `DTO → domain`),
   tested only through the services. The domain mapper is a plain copy (the
   details mapper also sorts instructions by step).
7. **No validation of backend data.** `invalidData` means "does not decode".
   Rule checks (servings, blank strings, duplicates, id mismatch) were designed,
   built and removed: they masked what the backend sent. Seeing bad data is
   Observability (backlog). The one check kept is on the request: blank, `.` and
   `..` ids are `notFound` without a request, because `URL.appending` does not
   encode dot segments.
8. **Swift 6 isolation.** The app target's default actor isolation is switched
   off, so the app and test targets are both nonisolated by default and the data
   layer needs no isolation keywords. Value types still declare `Sendable`. One
   private `@concurrent` method per concrete service does the work off the
   caller's actor. No `@unchecked Sendable`, `nonisolated(unsafe)` or
   `@preconcurrency` anywhere. View models (003) need an explicit `@MainActor`.
9. **Only the services and the endpoint are tested**, with Swift Testing, and
   kept lean: happy and sad paths, with `@Test(arguments:)` for triangulation. No
   tests for the local client, the mappers on their own, or the shipped fixtures.
10. **Domain models are `Equatable`**, so a test compares `result == expected`
    like the reference suite.

## Approach / How

Under `ReciMate/`:

- `API/RecipeAPIClient.swift`: protocol and `RecipeAPIClientError`.
- `API/RecipeEndpoint.swift`.
- `API/Infrastructure/LocalRecipeAPIClient.swift`: finds `<last path component>.json` in the bundle and returns its bytes; a missing file throws `RecipeAPIClientError.notFound`, anything else passes through. It ignores scheme and host.
- `API/List/`: the list DTO, `RecipeListService` (protocol and `RemoteRecipeListService`, a struct initialised with `baseURL` and `client`), `RecipeListDataMapper`, `RecipeListMapper`.
- `API/Details/`: the same for details, including the shared `DietaryAttributesDTO`. The details service rejects unusable ids first.
- Each service: build the URL via `RecipeEndpoint`, call the client, run the two mappers, translate errors.
- `Domain/RecipeError.swift`.
- DTOs and domain models declare `Sendable`; the domain models are `Equatable`.
- `ReciMateApp.swift`: a placeholder base URL constant, commented as unused by the local client. No service is wired into a view yet (003).

Under `ReciMateTests/` (Swift Testing, `makeSUT` returning `(service, clientSpy)`, one spy per test, no static state):

- `Helpers/RecipeAPIClientSpy.swift`: `@MainActor` spy in the shape of the reference `HTTPClientSpy`: `stub(data:)` / `stub(error:)` up front, `requestedURLs` to assert on.
- `Helpers/RecipeFixtures.swift`: `.fixture(...)` for every domain type.
- `Helpers/RecipeJSONBuilders.swift`: API JSON derived from a domain value.
- `Helpers/RecipeErrorMatching.swift`: matches `invalidData` and its reason.
- `RecipeEndpointTests.swift` (2 tests), `RecipeListServiceTests.swift`, `RecipeDetailsServiceTests.swift`. The service suites are `@MainActor`.
- The placeholder `TestExample1.swift` and `TestExample2.swift` are deleted.

Fixed constraints: stub up front in Arrange (async/await, no completion to
invoke); one failure reason per test; no test-only code in production beyond
`Equatable` on the domain types; DTO `CodingKeys` stay as they are.

## Out of Scope

- Search and filters (S1–S6, milestone 004). `.list` gains parameters there.
- Pagination, cancellation handling, logging and analytics (see
  [BACKLOG.md](../../product/BACKLOG.md)).
- Validating decoded values.
- View models, views, previews (003 and later).
- A URLSession client or any network code.
- Tests for `LocalRecipeAPIClient`, for the mappers directly, and for the
  shipped fixtures.
- Retry, caching.

## Steps

1. Add `Sendable` to the DTOs and domain models; add `RecipeError`,
   `RecipeAPIClientError` and the `RecipeAPIClient` protocol. Build.
2. `RecipeEndpointTests` first, then `RecipeEndpoint`.
3. `RecipeAPIClientSpy`, fixtures and JSON builders; delete the placeholder tests.
4. List service test-first, one requirement at a time: protocol,
   `RemoteRecipeListService`, its two mappers. Confirm the private `@concurrent`
   method compiles against the protocol requirement before writing more tests
   against it.
5. Details service the same way, with its two mappers.
6. `LocalRecipeAPIClient` and the placeholder base URL in `ReciMateApp`. Build.
   No tests.
7. Write `implementation-notes.md` with every assumption, trade-off and
   deviation found. Run the full suite once. Update the roadmap status for 002.

Task list: yes

## Open Questions / Risks

- **Service names?** → `RemoteRecipeListService` and `RemoteRecipeDetailsService`
  behind `RecipeListService` and `RecipeDetailsService`; client is
  `LocalRecipeAPIClient`.
- **One endpoint enum or two types?** → One enum; splitting later is mechanical.
- **Where does the placeholder base URL live?** → A constant in `ReciMateApp`.
- **Are the validation rules final?** → There are none: decoded values are not
  judged (decision 7).
- **Do the services need leak tracking?** → No: they are structs with no state.
- **Does the local client or the shipped fixtures get tests?** → No, decided.
- **May a `@concurrent` method satisfy the protocol requirement?** → Resolved: the
  private-method shape compiles; no deviation.
- The local client's bundle lookup (flat bundle, by file name) is untested; a
  wrong lookup would only show when 003 loads real data.
- A failure inside a service is harder to pinpoint without direct mapper tests.
  If diagnosis gets costly, add focused mapper tests and note it.
- A future URLSession client must handle cancellation itself: the services'
  catch-all would report it as `unavailable` (backlog).

## Acceptance Criteria

- **AC1** Requesting the list returns all previews in order with every field
  mapped, and returns an empty array for an empty list.
- **AC2** Requesting details returns every field, with steps ordered by step
  number.
- **AC3** A missing resource gives `notFound`; undecodable data gives
  `invalidData` with a reason; any other client error gives `unavailable`.
- **AC4** One undecodable item in the list fails the whole list.
- **AC5** Blank, `.` and `..` ids give `notFound` without a client call.
- **AC6** Each load makes exactly one client request, to the URL `RecipeEndpoint`
  gives for the injected base URL.
- **AC7** The list URL is the base URL plus `/recipe-list`; the details URL is the
  base URL plus `/recipe-details/<id>`.
- **AC8** The services and endpoint depend on `RecipeAPIClient` only; nothing
  outside `LocalRecipeAPIClient` knows about files or the bundle.
- **AC9** Production code carries no test-only code beyond `Equatable` on the
  domain types; no `@unchecked Sendable`, `nonisolated(unsafe)` or
  `@preconcurrency` is used anywhere.
- **AC10** The project builds in Swift 6 mode with no concurrency warnings from
  the new code, and the full test suite passes.
- **AC11** `implementation-notes.md` records the assumptions and any deviation.

## Verification

Each line names the criteria it checks.

- **AC1, AC3, AC4** `scripts/test.sh ReciMateTests/RecipeListServiceTests`.
- **AC2, AC3, AC5** `scripts/test.sh ReciMateTests/RecipeDetailsServiceTests`.
- **AC6** Both service suites (`…_requestsListEndpointURL`, `…_requestsDetailsEndpointURL`).
- **AC7** `scripts/test.sh ReciMateTests/RecipeEndpointTests`.
- **AC8** Read the imports and initialisers of the services and endpoint: only
  `RecipeAPIClient` appears; `rg "Bundle|FileManager" ReciMate/API` matches only
  `LocalRecipeAPIClient.swift`.
- **AC9** `rg "unchecked Sendable|nonisolated\(unsafe\)|preconcurrency" ReciMate ReciMateTests`
  returns nothing; `rg "Equatable|Hashable" ReciMate/API ReciMate/Domain` shows only
  the domain types and `RecipeError`.
- **AC10** Read `build/build.log` for concurrency warnings from the new files;
  full `scripts/test.sh` once at the end ends with `PASS`.
- **AC11** Read `implementation-notes.md` against Open Questions / Risks above.

Single tests run as `…/<Suite>/<test>()`. Post the `tail -F` line from
`CLAUDE.md` before each run.
