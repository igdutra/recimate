# 002 implementation notes

State at the end of the milestone: 16 tests in 3 suites, all passing, no warnings
from the new code. `SPEC.md` and `discovery.md` describe this final design; this
file records what changed on the way and why.

## Assumptions

- Instructions are sorted by step number when out of order. Valid, not errors: an
  empty list, empty ingredients or instructions, a missing photo, a missing quantity.
- Decoded values are not judged (see the no-validation decision below).
- `LocalRecipeAPIClient` ignores scheme and host and reads `<last path component>.json`
  from the bundle root. The fixtures are bundled flat, so file names must stay
  unique. It has no tests by decision; a one-off check (not kept) loaded the real
  list, a real detail, `creamy-tomato-pasta` (`invalidData`, reason names
  `cooking_instructions[1].step`) and a missing detail (`notFound`) from the app bundle.
- The base URL is assumed to have no query or fragment.
- Not tested, by decision: `LocalRecipeAPIClient`, the mappers on their own, the
  shipped fixtures. If a mapper failure gets hard to diagnose, add focused mapper tests.
- Consequence for 003 and 005: ids are not checked for uniqueness, and
  `CookingInstruction.id` is its `step`. Duplicate recipe ids or duplicate step
  numbers from the backend would reach `ForEach` as duplicate identities.
- A future URLSession client must handle cancellation itself (see below).

## Decisions made while building

- **No validation of backend data.** The spec listed rules that turn decoded data
  into `invalidData` (servings below 1, blank id or title, duplicate list ids,
  duplicate step numbers, a detail id that differs from the requested one), and a
  `RecipeRules` helper was written for them. On review that is the app validating
  the backend and hiding what it sent, which an MVP should not do. All of it was
  removed, with its tests. `invalidData` now means "the bytes do not decode into
  the DTO"; one undecodable item still fails the whole list. Ids are
  trusted: the request-side guard for blank, `.` and `..` ids was removed too (see
  Deviations; URL handling, backlog).
- **`invalidData` carries a reason.** `invalidData(reason:)` holds the decoder's
  description as a string (a string so `RecipeError` stays `Equatable`), so the
  cause reaches the service layer and the view model decides what to do with it.
- **Cancellation handling removed** from both services and its tests. The local
  client cannot throw `CancellationError`, so the branch could not run. The
  services' catch-all would report a cancelled URLSession load as `unavailable`;
  handling it comes with that client (`product/BACKLOG.md`, Cancellation handling).
- **Observability** (logging, analytics) is not part of this milestone: nothing in
  the data layer logs. See `product/BACKLOG.md`.
- **Default actor isolation switched off** for the app target
  (`SWIFT_DEFAULT_ACTOR_ISOLATION` removed), so the app and test targets match.
  Evidence (four builds of a copy of the project, Swift 6.3.2): MainActor default
  with every `nonisolated` builds clean; dropping `nonisolated` only where
  `Sendable` was declared fails (`main actor-isolated conformance of
  'RecipeDetailsDTO' to 'Decodable'`, `main actor-isolated instance method
  'url(baseURL:)'`); dropping all of it fails on every mapper call; default off
  with zero `nonisolated` builds clean, 0 warnings. The SE-0466 amendment
  (`Sendable` on the primary declaration stops `@MainActor` inference) did not hold
  on this compiler, which is what made 24 `nonisolated` keywords necessary at first.
  Why off: every keyword existed to undo the setting, and the data layer grows with
  search in 004. The cost moves to the 2–3 view models, which belong on the main
  actor anyway. View models in 003 need an explicit `@MainActor`. Swift 6 language
  mode still rejects every data race. Approachable Concurrency stays on, so
  `nonisolated async` still runs on the caller's actor and the private `@concurrent`
  method is still what moves the read and decode off the main actor.
- **Domain models and `RecipeError` are `Equatable`** in production code, so tests
  compare `result == expected` like the reference does. This deviates from the
  spec's earlier "nothing added only for tests". Revert, and compare field by
  field, if that is not wanted.
- **Tests are lean on purpose.** The first pass aimed to be thorough (triangulation,
  hidden requirements, boundary cases, 52 tests). The direction reversed: test the
  behaviour a reader expects, happy and sad paths, `@Test(arguments:)` for
  triangulation, and no tests for mistakes the code cannot make yet. The endpoint
  suite is two tests (a basic `URL.appending` setup; a production API would likely
  need `URLComponents`, and richer URL tests belong with that change).
- **Spy, not stub.** The spy follows the reference `HTTPClientSpy`: stub up front,
  assert on `requestedURLs`. A URL-keyed stub was tried and dropped; its happy path
  only worked through a `notFound` fallback, which read as always failing. The spy
  is `@MainActor` (so `Sendable` with no escape hatch; `@unchecked Sendable` and
  `Mutex` were tried or considered first), the two service suites are `@MainActor`,
  and their `@Test(arguments:)` providers are `nonisolated`. The spy's
  `data(from:)` needs an explicit `@MainActor`, otherwise it is inferred
  nonisolated from the protocol requirement and cannot touch the spy's state.
- **Test support** lives in `ReciMateTests/Helpers/`: the spy, domain fixtures
  (`.fixture(...)`), JSON builders that derive the payload from a domain value, and
  the `invalidData` matcher.
- **`API/` is split** into `List/` and `Details/` (DTO, service, two mappers each).
  The endpoint, the client protocol and `Infrastructure/` stay at the shared level.
  `DietaryAttributesDTO` lives in `Details/RecipeDetailsDTO.swift` but the list DTO
  uses it too.

## Deviations

- The spec's open risk is resolved: a private `@concurrent` method satisfies the
  protocol shape without trouble.
- DTOs and domain types do not carry `nonisolated`; see the isolation decision.
- The spec's test plan (EP, DL, DD ids, the larger endpoint suite, the spy's
  `Mutex`, cancellation tests, rule-violation tests) was replaced by the lean suite.
- Removed the unusable-id guard (blank, `.`, `..` gave `notFound` without a request) and AC5: ids are trusted for the MVP. Logged in the backlog as "URL handling and path security".
