Created: 2026-10-03
Updated: 2026-10-03

# 002 Recipe Data Layer

Closes D3 and the data side of E3 ([REQUIREMENTS.md](../../product/REQUIREMENTS.md)).
Findings and rejected alternatives: [discovery.md](discovery.md).

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
- Data that cannot be read as a recipe, or that breaks a recipe rule (fewer than
  one serving, blank id or title, duplicate ids, duplicate step numbers, a
  detail file whose id differs from the one asked for), is reported as "invalid
  data". One bad item makes the whole list invalid.
- Any other failure is reported as "unavailable". The caller never sees why.
- Cancelling a load is not reported as a failure.
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
   `url(baseURL:)`, using `URL.appending`. Rejected: two endpoint types
   (duplicated base-URL logic) and the reference's `URLComponents` rebuild (drops
   port and user info, force-unwraps).
4. **Names.** Protocols `RecipeListService`, `RecipeDetailsService`,
   `RecipeAPIClient`. Concrete `RemoteRecipeListService`,
   `RemoteRecipeDetailsService`, `LocalRecipeAPIClient` (named for its role, a
   stand-in for a server; a URLSession client would be a sibling).
5. **Domain errors** `RecipeError`: `notFound`, `invalidData`, `unavailable`;
   payload-free. The client's contract error `RecipeAPIClientError.notFound` is
   owned by the client protocol so services never inspect Foundation errors.
   `CancellationError` is rethrown unchanged.
6. **Four internal mappers**, two per service (`Data → DTO`, `DTO → domain`),
   tested only through the services.
7. **Validation is all-or-nothing** with the rules listed under Requirements.
8. **Swift 6 isolation.** App default stays `MainActor`; the data layer is
   `nonisolated` and its value types declare `Sendable` in their primary
   declaration; one private `@concurrent` method per concrete service does the
   work off the caller's actor. No `@unchecked Sendable`, `nonisolated(unsafe)`
   or `@preconcurrency`.
9. **Only the services and the endpoint are tested**, with Swift Testing. No
   tests for the local client, the mappers on their own, or the shipped fixtures.

## Approach / How

Under `ReciMate/`:

- `API/RecipeAPIClient.swift`: protocol and `RecipeAPIClientError`.
- `API/RecipeEndpoint.swift`.
- `API/Infrastructure/LocalRecipeAPIClient.swift`: finds `<last path component>.json` in the bundle and returns its bytes; a missing file throws `RecipeAPIClientError.notFound`, anything else passes through. It ignores scheme and host.
- `API/RecipeListService.swift`, `API/RecipeDetailsService.swift`: each protocol and its `Remote…` conformance, a struct initialised with `baseURL` and `client`. Each service: reject unusable ids (details only), build the URL via `RecipeEndpoint`, call the client, run the two mappers, translate errors.
- `API/Mappers/`: `RecipeListDataMapper`, `RecipeListMapper`, `RecipeDetailsDataMapper`, `RecipeDetailsMapper`.
- `Domain/RecipeError.swift`.
- Existing DTOs and domain models gain `Sendable` on their declaration line.
- `ReciMateApp.swift`: a placeholder base URL constant, commented as unused by the local client. No service is wired into a view yet (003).

Under `ReciMateTests/` (Swift Testing, `makeSUT` returning `(sut, clientSpy)`, one spy per test, no static state):

- `RecipeAPIClientSpy.swift`: spy capturing `requestedURLs`, replaying a stubbed `Data` or error; plus JSON builders with overridable fields.
- `RecipeEndpointTests.swift` (EP-1 to EP-6), `RecipeListServiceTests.swift` (DL-1 to DL-11), `RecipeDetailsServiceTests.swift` (DD-1 to DD-11). Test names and triangulation cases are listed in `discovery.md`, section "Requirements → tests"; they are the test plan.
- Delete the placeholder `TestExample1.swift` and `TestExample2.swift`.

Fixed constraints: stub up front in Arrange (async/await, no completion to
invoke); one failure reason per test; no test-only conformances in production
code; the test target keeps its nonisolated default. DTO `CodingKeys` stay
as they are.

## Out of Scope

- Search and filters (S1–S6, milestone 004). `.list` gains parameters there.
- Pagination (see [BACKLOG.md](../../product/BACKLOG.md)).
- View models, views, previews (003 and later).
- A URLSession client or any network code.
- Tests for `LocalRecipeAPIClient`, for the mappers directly, and for the
  shipped fixtures.
- Retry, caching, logging.

## Steps

1. Add `Sendable` to the DTOs and domain models; add `RecipeError`,
   `RecipeAPIClientError` and the `RecipeAPIClient` protocol. Build.
2. `RecipeEndpointTests` first, then `RecipeEndpoint`, until EP-1 to EP-6 pass.
3. `RecipeAPIClientSpy` and JSON builders; delete the placeholder tests.
4. List service test-first, one requirement at a time (DL-1 to DL-11): protocol,
   `RemoteRecipeListService`, its two mappers. Run the suite after each group.
   Confirm the private `@concurrent` method compiles against the protocol
   requirement before writing more tests against it.
5. Details service the same way (DD-1 to DD-11), with its two mappers.
6. `LocalRecipeAPIClient` and the placeholder base URL in `ReciMateApp`. Build.
   No tests.
7. Write `implementation-notes.md` with every assumption, trade-off and
   deviation found (validation rules, local client ignoring scheme and host,
   flat bundle lookup, untested pieces). Run the full suite once. Update the
   roadmap status for 002.

Task list: yes

## Open Questions / Risks

- **Service names?** → `RemoteRecipeListService` and `RemoteRecipeDetailsService`
  behind `RecipeListService` and `RecipeDetailsService`; client is
  `LocalRecipeAPIClient`.
- **One endpoint enum or two types?** → One enum; splitting later is mechanical.
- **Where does the placeholder base URL live?** → A constant in `ReciMateApp`.
- **Are the validation rules final?** → Yes, as listed under Requirements.
- **Do the services need leak tracking?** → No: they are structs with no state.
- **Does the local client or the shipped fixtures get tests?** → No, decided.
- A `@concurrent` method may not be allowed to satisfy a non-`@concurrent`
  protocol requirement; the private-method shape is used to avoid depending on
  that, but step 4 confirms it by building. If it fails, record the deviation.
- The local client's bundle lookup (flat bundle, by file name) is untested; a
  wrong lookup would only show when 003 loads real data.
- A failure inside a service is harder to pinpoint without direct mapper tests.
  If diagnosis gets costly, add focused mapper tests and note it.

## Acceptance Criteria

- Requesting the list returns all previews in order with every field mapped, and
  returns an empty array for an empty list.
- Requesting details returns every field, with steps ordered by step number.
- A missing resource gives `notFound`; undecodable or rule-breaking data gives
  `invalidData`; any other client error gives `unavailable`; cancellation stays
  a cancellation.
- One bad item in the list fails the whole list.
- Blank, `.` and `..` ids give `notFound` without a client call.
- Each load makes exactly one client request, to the URL `RecipeEndpoint` gives
  for the injected base URL.
- Endpoint URLs keep the base URL's port, scheme and path prefix, ignore a
  trailing slash, and encode ids as one path component.
- The services and endpoint depend on `RecipeAPIClient` only; nothing outside
  `LocalRecipeAPIClient` knows about files or the bundle.
- Production types carry no test-only code or conformances; no `@unchecked
  Sendable`, `nonisolated(unsafe)` or `@preconcurrency` is used.
- The project builds in Swift 6 mode with no concurrency warnings from the new
  code, and the full test suite passes.
- `implementation-notes.md` records the assumptions and any deviation.

## Verification

- `scripts/test.sh ReciMateTests/RecipeEndpointTests`, then
  `…/RecipeListServiceTests`, then `…/RecipeDetailsServiceTests` while building
  each piece; a single test as `…/<Suite>/<test>()`. Post the `tail -F` line
  from `CLAUDE.md` before each run.
- Full `scripts/test.sh` once at the end: ends with `PASS`.
- Read `build/build.log` for concurrency warnings from the new files.
- `rg "unchecked Sendable|nonisolated\(unsafe\)|preconcurrency" ReciMate` returns nothing.
- `rg "Equatable|Hashable" ReciMate/API ReciMate/Domain` shows no conformance added only for tests.
- Read `implementation-notes.md` against the Open Questions / Risks above.
