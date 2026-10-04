Created: 2026-10-03
Updated: 2026-10-03

# 002 Recipe Data Layer: discovery

Closes D3 and the data side of E3 from [REQUIREMENTS.md](../../product/REQUIREMENTS.md).
P1 (Swift 6 language mode) was already switched on in the build settings; this
milestone only has to keep the new code clean under it.

Status: discovery complete, ready for `/spec 002-recipe-data-layer`.

Inputs read: `product/`, `specs/001-*/notes.md`, the DTOs, domain types and
fixtures, and everything in `references/` (architecture notes, test map, testing
cheat sheet, `RemoteSongRepositoryTests.swift`).

## Decisions

### 1. Two layers, on purpose

```
view model (003) → RecipeListService / RecipeDetailsService  (protocols, concrete types conform)
                      │  RecipeEndpoint      (builds the URL from baseURL)
                      │  data → DTO mapper   (decoding, DecodingError → invalidData)
                      │  DTO → domain mapper (mapping + validation)
                      │  error translation
                      ▼
                   RecipeAPIClient (protocol) → LocalRecipeAPIClient
                   data(from: URL) → Data       reads <last path component>.json, nothing else
```

- **Service** (the repository role; we do not use the word "repository"). It is a
  protocol, and a concrete type conforms to it. Each service owns two mappers and
  the translation of every infrastructure failure into a domain error.
- **Infrastructure implementation**, shielded by a protocol the data layer owns.
  Like the reference's `HTTPClient`, it returns raw `Data` and nothing more: no
  decoding, no DTOs, no generics, no domain types, no domain errors. It finds a
  JSON file and reads its bytes.

**Knowingly not doing more layers.** Many codebases, Android-style clean
architecture above all, use this chain:

```
infra (URLSession, Alamofire) → data source (returns DTO) → repository (maps to domain)
    → use case → view
```

We stop at a service over an infrastructure client. A data source layer and a
use-case layer would only forward calls (list and details each have one operation
and no business rule between the screen and the data), which is boilerplate with
no behaviour to isolate. Two layers still give what matters: decoding, domain
errors and mapping never live in the object that touches the file, so a
URLSession client can replace it without touching a service, a view model or a
view. If a use case ever earns its place (rules spanning several services), it
can be added above the services without changing them.

### 2. The infrastructure protocol: one interface, takes a URL, returns Data

Two screens, two DTOs, but the infrastructure does the same job for both: fetch
the bytes at an address. So there is one protocol, it takes a `URL` (like the
reference's `HTTPClient.get(from: URL)`) and returns `Data`. It knows nothing
about DTOs.

```swift
nonisolated protocol RecipeAPIClient: Sendable {
    func data(from url: URL) async throws -> Data
}

/// The contract error every implementation throws for a resource that does not
/// exist. Owned by the protocol's side, so the services never inspect
/// Foundation file errors or HTTP status codes.
nonisolated enum RecipeAPIClientError: Error {
    case notFound
}
```

**Architecture decision (flagged): the client takes a `URL`, and the local
loader is a convenience, not the design.** All our interfaces are shielded so
that swapping the bundled JSON for the real API is a change in one place. The
local implementation exists only because there is no server yet.

- **Why a URL and not a resource name.** The service already knows the
  endpoint (`/recipe-list`, `/recipe-details/{id}`; the DTO doc comments name
  them), so it builds the URL and the client stays dumb. A resource-name string
  would hide the endpoint inside each client and force a new parameter shape the
  day a real API needs paths or query items. With a URL, search (S1–S6, milestone
  004) is just query items on the URL, built by `RecipeEndpoint` (decision 2b).
- **The swap.** A future `URLSessionRecipeAPIClient` implements the same method
  (`URLSession.data(from:)` is the same shape, it also returns the response, which
  that client checks), maps a 404 to `RecipeAPIClientError.notFound`, and
  nothing above it changes. The services, mappers, domain errors, view models and
  tests are untouched.
- **How URLs are built.** Each service is initialised with an injected
  `baseURL` and a `client` (like the reference's `RemoteFeedLoader(url:client:)`)
  and gets its URL from `RecipeEndpoint` (decision 2b).
- **What the local client does.** `LocalRecipeAPIClient` ignores scheme and host
  and maps the URL's last path component to `<component>.json` in the bundle. The
  app's composition root passes a placeholder base URL (for example
  `https://api.recimate.example`), documented as unused by the local client. A
  missing file throws `RecipeAPIClientError.notFound`; any other read failure
  passes through untouched.
- There is no HTTP response in the signature: local files have no status code,
  and the services only care about bytes or a thrown error.
- `LocalRecipeAPIClient` has **no tests of its own**: it only finds a file and
  reads its bytes, so it is a stand-in, not behaviour worth a suite.

**Name: `LocalRecipeAPIClient`.** Two naming styles exist: by mechanism
(`BundleRecipeAPIClient`, like the reference's `URLSessionHTTPClient`) or by
role (`Local…`, paired with a future `Remote…`). `Local` wins here for three
reasons. It states *why* the type exists (a stand-in for a server), which is
the thing a reader at the composition root needs, where `LocalRecipeAPIClient()`
swaps visibly for `URLSessionRecipeAPIClient()`. "Bundle" names an
implementation detail that may change (a documents directory, an in-memory
fixture) without the type's role changing. And it reads as a pair. If you want
the reference's mechanism style instead, the cost of renaming is one type.

### 2b. Endpoints: where URLs are built

The reference's `FeedEndpoint` (an enum with a `url(baseURL:)` method, tested on
its own) is the model. Services do not build URLs themselves; they ask an
endpoint. That keeps the URL map for the whole API in one tested place, and a
URLSession client later needs nothing new from the services.

```swift
nonisolated enum RecipeEndpoint: Sendable {
    case list                      // GET /recipe-list
    case details(id: String)       // GET /recipe-details/{id}

    func url(baseURL: URL) -> URL {
        switch self {
        case .list:
            baseURL.appending(component: "recipe-list")
        case let .details(id):
            baseURL.appending(component: "recipe-details").appending(component: id)
        }
    }
}
```

`RecipeListService` calls `RecipeEndpoint.list.url(baseURL:)`;
`RecipeDetailsService` calls `RecipeEndpoint.details(id:).url(baseURL:)`.

**Where this deliberately differs from the pasted `FeedEndpoint`:**

- **One enum with two cases, not two endpoint types.** The reference has one
  endpoint, so one enum. We have two, and they share everything except the path:
  the base-URL handling, the encoding rules and, from milestone 004, the query
  building. Two types would each need their own copy of that logic (or a third
  shared helper type), and one test file would become two with the same
  base-URL cases repeated. One enum means one file and one test suite, and the
  case list reads as the API's URL map. Adding search in 004 is a parameter on
  `.list` (the reference's `get(after: = nil)` shape), not a new type. If you
  prefer one type per screen, it is a mechanical split; nothing else in this spec
  changes.
- **`URL.appending` instead of rebuilding with `URLComponents`.** The pasted code
  copies only `scheme` and `host` into a new `URLComponents`, which silently
  drops the port (`http://localhost:8080` would become `http://localhost`) and
  user info, concatenates the path as a string, and force-unwraps
  `components.url!`. `appending(component:)` keeps every part of the base URL,
  tolerates a trailing slash (`/v2` and `/v2/` give the same URL), is
  non-optional, and needs no force unwrap. Verified with a scratch script.
- **Ids are encoded as one path component.** `appending(component:)`
  percent-encodes the id: `a b` → `a%20b`, `a/b` → `a%2Fb`, `a?b` → `a%3Fb`,
  `a#b` → `a%23b`. A string-concatenated path would let `a/b` become two
  segments. The dot segments `.` and `..` are *not* encoded and stay path
  traversal, so the service rejects them as `notFound` before building a URL.
- **Query items (milestone 004) are appended only when there are any.**
  Verified: `appending(queryItems: [])` leaves a dangling `?` on the URL, so 004
  must guard on non-empty.
- **Assumption:** the base URL carries no query or fragment. Documented, not
  tested.

### 3. The services and their four mappers

```swift
nonisolated protocol RecipeListService: Sendable {
    func loadRecipes() async throws -> [RecipePreview]
}

nonisolated protocol RecipeDetailsService: Sendable {
    func loadRecipe(id: String) async throws -> RecipeDetails
}
```

Concrete types conform (`RemoteRecipeListService`, `RemoteRecipeDetailsService`,
each initialised with a `baseURL` and a `RecipeAPIClient`). Resolved: the
protocols land now, not in 003, so the view models in 003 only ever see the
protocol.

Each service runs the same two-step pipeline, with one mapper per step:

| Service | Step 1: data → DTO | Step 2: DTO → domain |
|---|---|---|
| `RecipeListService` | `RecipeListDataMapper`: `Data` → `RecipeListDTO` | `RecipeListMapper`: `RecipeListDTO` → `[RecipePreview]` |
| `RecipeDetailsService` | `RecipeDetailsDataMapper`: `Data` → `RecipeDetailsDTO` | `RecipeDetailsMapper`: `RecipeDetailsDTO` → `RecipeDetails` |

- Step 1 decodes with `JSONDecoder`. A `DecodingError` becomes `invalidData`.
  The DTOs keep their explicit `CodingKeys`, so snake_case handling is unchanged.
- Step 2 builds domain values and enforces the domain rules (decision 5). A
  broken rule becomes `invalidData`.
- Mappers are not public API. They are internal to the data layer and are **not
  tested directly, only through the services' public interface** (classicist, as
  in the reference lesson 004), so nothing is made visible just for tests and the
  mappers stay freely replaceable. Trade-off, accepted: a failure is harder to
  pinpoint (service or one of its two mappers), with no extra abstraction layer.
  If diagnosis ever costs too much, the named escape hatch is to give a mapper
  its own focused tests.

### 4. Domain errors

Declared in `Domain/`, payload-free so `Equatable` comes for free and tests can
use `#expect(throws:)` without adding anything test-only to production.

| Error | Meaning | Produced when |
|---|---|---|
| `notFound` | The recipe does not exist | client throws `RecipeAPIClientError.notFound` |
| `invalidData` | The data arrived but is unusable | the bytes do not decode into the DTO, or the mapped data breaks a domain rule |
| `unavailable` | Anything else went wrong, the cause is not the user's data | any other client error (I/O today, connectivity later) |

The UI never learns why (a 500 and a flaky disk are both `unavailable`), only the
three outcomes it can react to. `unavailable` is the retryable one, which is what
E2's recoverable error screen will lean on.

**Cancellation is not an error.** `CancellationError` is rethrown as is, never
turned into `unavailable`, so a screen that goes away does not show an error.

### 5. Mapping and validation rules (E3, data side)

Proposed defaults; `/spec` confirms them. Every rule is a decision to document in
`implementation-notes.md`.

- **All or nothing.** One malformed item makes the whole list `invalidData`; the
  service does not silently drop bad items. Silent drops hide data problems.
- `servings < 1` is `invalidData` (the domain model already promises "at least 1").
- Blank (empty or whitespace-only) `id` or `title` is `invalidData`.
- Duplicate recipe ids in the list are `invalidData` (`Identifiable` would break
  `ForEach`). Duplicate step numbers in one recipe are `invalidData`.
- Instructions are returned ordered by `step`; out-of-order input is sorted, not rejected.
- The detail DTO's `id` must equal the requested id, else `invalidData` (a
  mislabeled file must not show the wrong recipe).
- Valid and not errors: an empty list, a recipe without a photo, an ingredient
  without a quantity, empty ingredient or instruction arrays.
- The malformed fixture `creamy-tomato-pasta` (`"step": "two"`) is the real
  decoding failure for E2.

### 6. Swift 6 and isolation

**Settings today.** Swift 6 language mode, compiler 6.3.2. The app target has
`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` and `SWIFT_APPROACHABLE_CONCURRENCY = YES`.
The test target has only Approachable Concurrency.

**Keep `MainActor` as the app's default.** This is what SE-0466 was built for: a
single-target, UI-heavy app where most code belongs on the main actor, and it is
the Xcode 26 default for new apps. The community's main complaint is that the
default leaks into plain data types, and the usual advice is to opt the data
layer out explicitly (or move it to its own target, which is too much for a
handful of files). Removing the setting would mean annotating every view and
view model by hand instead.

**What the default does to the data layer if left alone:**

- Protocols, DTOs, mappers and services are inferred `@MainActor`.
- The DTOs (`struct RecipeDetailsDTO: Decodable`) compile today only because
  Approachable Concurrency's `InferIsolatedConformances` quietly makes their
  conformance `@MainActor Decodable`. Decoding them anywhere off the main actor
  fails to compile ("main actor-isolated conformance ... cannot be used").
  `Decodable` does not inherit `Sendable`, so the SE-0466 amendment below does
  not save them.

**Rules for the data layer:**

1. **Value types declare `Sendable` in their primary declaration**: DTOs, domain
   models, `RecipeError`, `RecipeAPIClientError`. The SE-0466 amendment (accepted
   August 2025) stops `@MainActor` inference for a type whose *primary
   declaration* conforms to a `Sendable`-inheriting protocol. A conformance
   added in an extension does not count, so it goes on the `struct` line. Error
   enums already get this from `Error: Sendable`; spelling it out is harmless.
2. **Protocols, services, mappers and the client are `nonisolated`**, as in the
   snippets above.
3. **`nonisolated` does not mean "off the main thread".** Approachable
   Concurrency turns on `NonisolatedNonsendingByDefault`, so a
   `nonisolated async` function runs on the caller's actor. Called from a
   `@MainActor` view model, the file read and the decode would still run on the
   main thread. Only `@concurrent` leaves the caller's actor.
4. **One hop, at the service.** Each concrete service runs its pipeline (client
   read, data mapper, domain mapper) inside one private `@concurrent` method.
   Everything below it is `nonisolated` and inherits that background executor,
   so the hop happens once per load. The protocol requirements keep the
   default (nonsending) form, so this does not depend on whether a `@concurrent`
   witness may satisfy a nonsending requirement; `/spec` confirms that by
   building.
5. **No escape hatches.** No `@unchecked Sendable`, `nonisolated(unsafe)` or
   `@preconcurrency`. Nothing here has shared mutable state, so they are never
   needed.

**The test target stays on the nonisolated default, on purpose.** `makeSUT` is a
synchronous, nonisolated function. If a service, DTO or domain type slips back
to `@MainActor`, building or reading it there without `await` stops compiling,
so the test target guards rules 1 and 2 at no cost. The price is that the view
model suites in 003 need `@MainActor` on the suite. Write that down in 003 so
nobody "fixes" the mismatch by flipping the test target's setting.

Research sources: [SE-0466](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0466-control-default-actor-isolation.md),
[SE-0466 amendment review](https://forums.swift.org/t/amendment-se-0466-control-default-actor-isolation-inference/80994),
[SwiftLee](https://www.avanderlee.com/concurrency/default-actor-isolation-in-swift-6-2/),
[Fatbobman](https://fatbobman.com/en/posts/default-actor-isolation/),
[Donny Wals](https://www.donnywals.com/exploring-concurrency-changes-in-swift-6-2/),
and the local `swift-concurrency` skill (`threading.md`, `migration.md`,
`testing.md`), which agrees on every point but does not cover the amendment.

### 7. Fixtures are bundled flat

`API/Infrastructure/` is a synchronized folder group, so the JSON files land in
the bundle root and the `RecipeList/` and `RecipeDetails/` subfolders are lost.
Lookup is by the URL's last path component only. File names are already unique
(`recipe-list`, `petit-gateau`, ...); keep them that way. Nothing in the test
suite covers the real bundle (the local client and the shipped fixtures are
deliberately untested), so this is a documented assumption, checked by running
the app or a preview in 003.

## Testing approach

All test files use the **Swift Testing** framework (`import Testing`; `@Suite` as
needed, `@Test`, `#expect`, `#require`, `#expect(throws:)`, `@Test(arguments:)`),
not XCTest. Style follows `RemoteSongRepositoryTests.swift` and the references:

- **Behaviour through the public API.** Tests call `service.loadRecipes()` and
  `service.loadRecipe(id:)` on the concrete services. All four mappers are
  covered through them.
- **Only the two services and the endpoint are tested.** The endpoint is pure
  logic with real rules (base-URL handling, id encoding), so it earns its own
  suite, as in the reference. No tests for the local client, the fixtures, or the
  mappers on their own.
- **The spy sits at the seam, nothing else.** `RecipeAPIClientSpy` conforms to
  `RecipeAPIClient`, lives in the test target, captures every requested URL
  (`requestedURLs`, so value, count and order are asserted in one `#expect`),
  and replays a stubbed `Data` or a stubbed error. Because the client
  returns plain `Data`, there is no generic cast in the spy, and malformed input
  is simply malformed bytes, as in the reference.
- **Async/await changes the pattern** (cheat sheet table): there is no completion
  to invoke in Act, so stubs are set in Arrange and the test just `await`s. Call
  capture (URLs requested, count, order) still works.
- **`makeSUT`** returns `(sut, clientSpy)` and takes an overridable `baseURL`;
  one construction point, so tests survive initializer changes. Each test builds its own spy (no static stub
  state, so Swift Testing's default parallel execution is safe).
- **Production carries zero test details.** No `Equatable` added to DTOs or
  domain models for assertions: tests compare fields, or compare the
  payload-free error enum. JSON builders (`makeRecipeDetailsJSON(...)` with
  overridable fields) live in the test target.
- **One failure reason per test.** A test that can fail for two reasons is split.
- **Triangulation, not just the happy path.** Every mapping behaviour is shown
  with at least two different inputs, so a hard-coded return cannot pass:
  parameterized `arguments:` over distinct values, plus two different payloads.
  Every rule is sampled on both sides of its boundary (servings 0, 1, 2).
- **Budget more sad tests than happy ones.** The reference suite guards about 5
  success scenarios against 20+ failure scenarios; this one should be as lopsided.
- **Requirements are expanded before tests are written**: explicit lines, hidden
  ones (what must NOT happen), and discovered ones (what a dependency really
  does).

### The four test files

| File | Role |
|---|---|
| `RecipeListServiceTests.swift` | Unit suite for `RemoteRecipeListService` over the spy |
| `RecipeDetailsServiceTests.swift` | Unit suite for `RemoteRecipeDetailsService` over the spy |
| `RecipeEndpointTests.swift` | Unit suite for `RecipeEndpoint`, no spy needed |
| `RecipeAPIClientSpy.swift` (test support) | The spy plus the JSON builders shared by the two service suites |

Deliberately absent: tests for `LocalRecipeAPIClient`, for the mappers, and a
contract suite over the shipped fixtures. The reference's end-to-end test exists
to catch an unannounced break of a *real server's* contract; with local files
there is no such counterpart.

### Requirements → tests

IDs are local to this spec (`EP-n`, `DL-n`, `DD-n`). The test names are the
proposed names; they read back as the requirement.

**`RecipeEndpointTests`** (Swift Testing port of the reference's
`FeedEndpointTests`: scheme, host, path and query asserted separately, each with
a message so a failure names the part)

| ID | Requirement | Tests | Path |
|---|---|---|---|
| EP-1 | The list URL is the base URL plus `/recipe-list`, with no query | `list_url_hasSchemeHostPathAndNoQuery` | happy |
| EP-2 | The details URL is the base URL plus `/recipe-details/<id>` | `details_url_endsInRecipeDetailsAndID` (parameterized over several ids, so the id can't be hard-coded) | happy |
| EP-3 | The base URL's path prefix is kept and a trailing slash makes no difference *(hidden)* | `url_keepsBaseURLPathPrefix`, `url_withOrWithoutTrailingSlash_isIdentical` (parameterized `https://host/api` vs `https://host/api/`, for both cases) | happy-edge |
| EP-4 | The base URL's port and scheme are kept *(hidden; the pasted `FeedEndpoint` would drop the port)* | `url_keepsBaseURLPortAndScheme` (parameterized `http://localhost:8080`, `https://host:443`) | happy-edge |
| EP-5 | An id is always one path component, percent-encoded | `details_url_encodesSpecialCharactersAsOnePathComponent` (parameterized `a b`, `a/b`, `a?b`, `a#b`, `ä`, `100%`; asserts the encoded string and that the path has the same number of components as for a plain id) | sad |
| EP-6 | Different ids give different URLs; the same id gives the same URL *(hidden)* | `details_url_isDeterministicAndDistinctPerID` | negative |

**`RecipeListServiceTests`**

| ID | Requirement | Tests | Path |
|---|---|---|---|
| DL-1 | Creating the service does no work *(hidden)* | `init_doesNotRequestData` | negative |
| DL-2 | Loading asks the client for the list endpoint's URL | `loadRecipes_requestsListEndpointURL` (triangulated with two different base URLs, so the base URL can't be hard-coded; the expected value comes from `RecipeEndpoint`, whose own URLs are pinned by `RecipeEndpointTests`) | happy |
| DL-3 | Each call is exactly one request, in order, no caching or dedupe *(hidden)* | `loadRecipesTwice_requestsListURLTwice` | negative |
| DL-4 | Valid JSON maps to previews, preserving order and every field | `loadRecipes_onValidJSON_deliversMappedPreviewsInOrder` (triangulated: two or more different recipes, so fields can't be hard-coded), `loadRecipes_mapsVegetarianFlagBothWays` (parameterized true/false), `loadRecipes_mapsSnakeCaseKeys` (`image_url`, `dietary_attributes`; guards the silent-drop trap from 001), `loadRecipes_withoutImageURL_deliversNilImageURL` | happy |
| DL-5 | An empty list is a valid success, not an error | `loadRecipes_onEmptyList_deliversEmptyArray` | happy-edge |
| DL-6 | Client says not found → `notFound` | `loadRecipes_onClientNotFound_throwsNotFound` | sad |
| DL-7 | Undecodable payload → `invalidData` | `loadRecipes_onUndecodableData_throwsInvalidData` (parameterized: not JSON, empty `Data`, valid JSON of the wrong shape, missing key, wrong type for a field such as `"servings": "four"`) | sad |
| DL-8 | Any other client failure → `unavailable`, whatever it is | `loadRecipes_onAnyOtherClientError_throwsUnavailable` (parameterized: `URLError`, `CocoaError`, a custom error), `loadRecipes_doesNotLeakInfrastructureErrors` | sad |
| DL-9 | Decoded data that breaks a rule → `invalidData` | `loadRecipes_onServingsBelowOne_throwsInvalidData` (parameterized 0, -1, `Int.min`), `loadRecipes_onServingsOfOne_succeeds` (boundary), `loadRecipes_onBlankIdOrTitle_throwsInvalidData` (parameterized `""`, `" "`, `"\n"`), `loadRecipes_onDuplicateIDs_throwsInvalidData` | sad |
| DL-10 | One bad item fails the whole list *(all-or-nothing)* | `loadRecipes_whenOneItemIsInvalid_throwsInvalidDataAndDeliversNothing` (bad item first, middle and last, so position doesn't matter) | sad |
| DL-11 | Cancellation is not a failure *(hidden)* | `loadRecipes_onCancellation_rethrowsCancellationError` | sad |

**`RecipeDetailsServiceTests`**

| ID | Requirement | Tests | Path |
|---|---|---|---|
| DD-1 | Creating the service does no work *(hidden)* | `init_doesNotRequestData` | negative |
| DD-2 | Loading asks the client for the details endpoint's URL for that id | `loadRecipe_requestsDetailsEndpointURL` (parameterized over several ids and two base URLs, so neither can be hard-coded) | happy |
| DD-3 | Each call is one request, in order *(hidden)* | `loadRecipeTwice_requestsSameURLTwice`, `loadTwoDifferentRecipes_requestsEachURLInOrder` | negative |
| DD-4 | Valid JSON maps to domain details with all fields | `loadRecipe_onValidJSON_deliversMappedDetails` (two different recipes), `loadRecipe_mapsIngredientsPreservingOrderAndOptionalQuantity`, `loadRecipe_mapsDietaryAttributes` (parameterized true/false), `loadRecipe_mapsSnakeCaseKeys` (`cooking_instructions`, `dietary_attributes`, `image_url`), `loadRecipe_withoutImageURL_deliversNilImageURL` | happy |
| DD-5 | Instructions come back ordered by step | `loadRecipe_withOutOfOrderSteps_deliversInstructionsSortedByStep` (triangulated with two different orderings) | happy-edge |
| DD-6 | Empty ingredients or instructions are valid, not errors | `loadRecipe_onEmptyIngredients_succeeds`, `loadRecipe_onEmptyInstructions_succeeds` | happy-edge |
| DD-7 | Not found, undecodable, other failure → `notFound`, `invalidData`, `unavailable` | the same three behaviours as DL-6 to DL-8, one test per row; `loadRecipe_onMalformedStep_throwsInvalidData` reproduces the `"step": "two"` shape; `loadRecipe_forEveryUnknownID_throwsNotFound` (parameterized ids, including `""`) | sad |
| DD-8 | Rule violations → `invalidData` | servings below one (parameterized), servings boundary of 1, blank id or title (parameterized), `loadRecipe_withDuplicateStepNumbers_throwsInvalidData`, `loadRecipe_whenDTOIDDiffersFromRequestedID_throwsInvalidData` | sad |
| DD-9 | Cancellation is not a failure *(hidden)* | `loadRecipe_onCancellation_rethrowsCancellationError` | sad |
| DD-10 | A failure for one recipe does not poison the next *(hidden)* | `loadRecipe_afterAFailure_stillLoadsAnotherRecipe` (the service keeps no failure state) | negative |
| DD-11 | An id that cannot name a recipe never reaches the client *(hidden)* | `loadRecipe_withUnusableID_throwsNotFoundWithoutRequesting` (parameterized `""`, `" "`, `"."`, `".."`) | sad |

Coverage is a diagnostic, not a target. The hidden-requirement questions that
produced the extra rows (what must NOT happen, what does "valid" exclude, what
does the dependency do in rows we did not define) are the working method for
`/spec` and `/implement-spec` to keep applying as cases come up.

## Files this milestone adds

Under `ReciMate/`:

- `API/RecipeAPIClient.swift`: protocol and `RecipeAPIClientError`.
- `API/RecipeEndpoint.swift`: the URL map.
- `API/Infrastructure/LocalRecipeAPIClient.swift`: reads the bytes of the file the URL points at.
- `API/RecipeListService.swift`, `API/RecipeDetailsService.swift`: each protocol and its concrete conformance.
- `API/Mappers/`: `RecipeListDataMapper`, `RecipeListMapper`, `RecipeDetailsDataMapper`, `RecipeDetailsMapper`.
- `Domain/RecipeError.swift`: the three domain errors.

Under `ReciMateTests/`: the four files above. The two placeholder
`TestExample*.swift` files are deleted.

## Defaults taken for /spec

Nothing here blocks `/spec`. Each default stands unless it is changed there.

- **Names.** Protocols `RecipeListService` and `RecipeDetailsService`; concrete
  `RemoteRecipeListService` and `RemoteRecipeDetailsService`; client protocol
  `RecipeAPIClient` with `LocalRecipeAPIClient`; `RecipeEndpoint`.
- **One `RecipeEndpoint` enum** (decision 2b), not two endpoint types.
- **Placeholder base URL.** A constant in `ReciMateApp`, commented as unused by
  the local client (it only reads the last path component).
- **Validation rules** in decision 5 (all-or-nothing, id-mismatch, duplicates,
  servings below one) are accepted as written.
- **The `@concurrent` hop** (decision 6, rule 4) is a private `@concurrent`
  method in each concrete service. `/spec` confirms it by building before the
  tests are written against it.
- **Services are structs** (no stored mutable state), so there is nothing to
  leak-track. Swift Testing has no `addTeardownBlock`; if a service ever becomes a
  class, add a small `weak`-reference check in `makeSUT`.
- **Out of scope, in [BACKLOG.md](../../product/BACKLOG.md):** pagination.
  Search (S1–S6) stays in milestone 004; `RecipeEndpoint.list` gains its
  parameters there.
