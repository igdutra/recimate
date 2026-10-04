Created: 2026-10-03
Updated: 2026-10-04

# 002 Recipe Data Layer: discovery

Closes D3 and the data side of E3 from [REQUIREMENTS.md](../../product/REQUIREMENTS.md).
P1 (Swift 6 language mode) was already switched on in the build settings; this
milestone only has to keep the new code clean under it.

Status: discovery complete, spec written and implemented. This file records the
reasoning at the time; where building overturned a decision, the section says so
and points to [SPEC.md](SPEC.md) and [implementation-notes.md](implementation-notes.md),
which win. Superseded: validation rules (5), cancellation (4), `nonisolated`
data layer (6), the spy and test plan (Testing approach).

Inputs read: `product/`, `specs/001-*/notes.md`, the DTOs, domain types and
fixtures, and everything in `references/` (architecture notes, test map, testing
cheat sheet, `RemoteSongRepositoryTests.swift`).

## Decisions

### 1. Two layers, on purpose

```
view model (003) → RecipeListService / RecipeDetailsService  (protocols, concrete types conform)
                      │  RecipeEndpoint      (builds the URL from baseURL)
                      │  data → DTO mapper   (decoding, DecodingError → invalidData)
                      │  DTO → domain mapper (plain mapping, steps sorted)
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
protocol RecipeAPIClient: Sendable {
    func data(from url: URL) async throws -> Data
}

/// The contract error every implementation throws for a resource that does not
/// exist. Owned by the protocol's side, so the services never inspect
/// Foundation file errors or HTTP status codes.
enum RecipeAPIClientError: Error {
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
enum RecipeEndpoint: Sendable {
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
protocol RecipeListService: Sendable {
    func loadRecipes() async throws -> [RecipePreview]
}

protocol RecipeDetailsService: Sendable {
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

- Step 1 decodes with `JSONDecoder`. A `DecodingError` becomes `invalidData(reason:)`.
  The DTOs keep their explicit `CodingKeys`, so snake_case handling is unchanged.
- Step 2 builds domain values. It judges nothing (decision 5, superseded).
- Mappers are not public API. They are internal to the data layer and are **not
  tested directly, only through the services' public interface** (classicist, as
  in the reference lesson 004), so nothing is made visible just for tests and the
  mappers stay freely replaceable. Trade-off, accepted: a failure is harder to
  pinpoint (service or one of its two mappers), with no extra abstraction layer.
  If diagnosis ever costs too much, the named escape hatch is to give a mapper
  its own focused tests.

### 4. Domain errors

Declared in `Domain/`. `Equatable` is declared explicitly (a payload-free enum
gets it for free, one with a payload does not) so tests can use
`#expect(throws:)` and view state can be compared.

| Error | Meaning | Produced when |
|---|---|---|
| `notFound` | The recipe does not exist | client throws `RecipeAPIClientError.notFound`, or the id cannot name a recipe |
| `invalidData(reason:)` | The data arrived but does not decode | the bytes do not decode into the DTO; `reason` is the decoder's description |
| `unavailable` | Anything else went wrong, the cause is not the user's data | any other client error (I/O today, connectivity later) |

The UI learns the three outcomes it can react to. `unavailable` is the retryable
one, which is what E2's recoverable error screen will lean on. `invalidData`
carries its reason as a string, not the `DecodingError`, which is not
`Equatable` and would cost the plain `#expect(throws: value)` form.

**Superseded: cancellation.** The first design rethrew `CancellationError`
instead of turning it into `unavailable`. The local client cannot throw it, so
the branch could not run; it was removed with its tests and moved to the backlog.
The URLSession client has to handle it, because the services' catch-all would
report it as `unavailable`.

### 5. Mapping rules (E3, data side)

**Superseded: validation.** This section proposed validating decoded data (servings
below 1, blank id or title, duplicate ids, duplicate step numbers, a detail id
different from the requested one, all-or-nothing). They were built, then removed:
that is the app validating the backend and hiding what it sent, which an MVP
should not do. What remains:

- Decoding is all or nothing: one undecodable item makes the whole list
  `invalidData`.
- Decoded values pass through as sent.
- Instructions are returned ordered by `step`; out-of-order input is sorted.
- Valid and not errors: an empty list, a recipe without a photo, an ingredient
  without a quantity, empty ingredient or instruction arrays.
- The request side keeps one check: blank, `.` and `..` ids are `notFound` without
  a request. `URL.appending` does not encode dot segments, so they would traverse.
- The malformed fixture `creamy-tomato-pasta` (`"step": "two"`) is the real
  decoding failure for E2.
- Seeing bad data in the field is Observability (backlog): logging and analytics.

### 6. Swift 6 and isolation

**Superseded: keep `MainActor` as the default.** The first design kept
`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` on the app target and opted the data
layer out with `nonisolated` (24 keywords). It also relied on the SE-0466
amendment, which says `Sendable` on a type's primary declaration stops
`@MainActor` inference. On Swift 6.3.2 it did not: the types' members and
`Decodable` conformances stayed main-actor isolated, and the data layer could not
be used off the main actor.

**Decision: the default is switched off** for the app target, matching the test
target. Nothing in the data layer needs an isolation keyword. A separate
experiment confirmed the other variants fail to compile or need the annotations.

- Value types still declare `Sendable`; protocols require it.
- **`nonisolated` does not mean "off the main thread".** Approachable Concurrency
  turns on `NonisolatedNonsendingByDefault`, so an `async` function runs on the
  caller's actor. Called from a `@MainActor` view model, the file read and decode
  would run on the main thread. Only `@concurrent` leaves the caller's actor.
- **One hop, at the service.** Each concrete service runs its pipeline inside one
  private `@concurrent` method. The protocol requirements keep the default form;
  building confirmed the private-method shape compiles.
- **No escape hatches** in production or tests: no `@unchecked Sendable`,
  `nonisolated(unsafe)` or `@preconcurrency`.
- **Consequences for later milestones.** View models need an explicit
  `@MainActor`. Views and `App` get it from their protocols.

Research sources: [SE-0466](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0466-control-default-actor-isolation.md),
[SwiftLee](https://www.avanderlee.com/concurrency/default-actor-isolation-in-swift-6-2/),
[Fatbobman](https://fatbobman.com/en/posts/default-actor-isolation/),
[Donny Wals](https://www.donnywals.com/exploring-concurrency-changes-in-swift-6-2/).

### 7. Fixtures are bundled flat

`API/Infrastructure/` is a synchronized folder group, so the JSON files land in
the bundle root and the `RecipeList/` and `RecipeDetails/` subfolders are lost.
Lookup is by the URL's last path component only. File names are already unique
(`recipe-list`, `petit-gateau`, ...); keep them that way. Nothing in the test
suite covers the real bundle (the local client and the shipped fixtures are
deliberately untested), so this is a documented assumption, checked by running
the app or a preview in 003.

## Testing approach

All test files use the **Swift Testing** framework (`import Testing`, `@Test`,
`#expect`, `#expect(throws:)`, `@Test(arguments:)`), not XCTest. Style follows
`RemoteSongRepositoryTests.swift` and the references.

**Lean, on purpose.** The first pass aimed to be thorough (a test for "init does
no work", "called twice", boundary values, cancellation). It was cut back: test
the behaviour a reader expects, happy and sad paths, triangulate with
`@Test(arguments:)`, and do not test mistakes the code cannot make yet.

- **Behaviour through the public API.** Tests call `service.loadRecipes()` and
  `service.loadRecipe(id:)` on the concrete services. All four mappers are
  covered through them.
- **Only the two services and the endpoint are tested.** The endpoint is a basic
  `URL.appending` setup, so it has two tests (list URL, details URL). No tests
  for the local client, the fixtures, or the mappers on their own.
- **The spy sits at the seam, nothing else.** `RecipeAPIClientSpy` follows the
  reference `HTTPClientSpy`: stub a `Data` or an error up front, call the
  service, assert on `requestedURLs`. With async/await there is no completion to
  invoke. It is `@MainActor` (so `Sendable` without escape hatches), and the
  service suites are `@MainActor` too. Its `data(from:)` needs an explicit
  `@MainActor`, otherwise the compiler infers it nonisolated from the protocol.
  A URL-keyed stub was tried and dropped: it hid the happy path behind a
  `notFound` fallback.
- **`makeSUT`** returns `(service, clientSpy)` and takes an overridable `baseURL`.
- **Fixtures and builders, in `ReciMateTests/Helpers/`.** `.fixture(...)` builds
  a valid domain value; `makePreviewJSON(from:)` and `makeDetailsJSON(from:)`
  derive the API's JSON from it. A test states the expected model once and
  asserts `result == expected`. That is why the domain models are `Equatable`.
- **Argument providers** (`static` members used by `@Test(arguments:)`) are
  `nonisolated` in the `@MainActor` suites.
- **One failure reason per test.**

### The test files

| File | Role |
|---|---|
| `RecipeListServiceTests.swift` | Suite for `RemoteRecipeListService` over the spy |
| `RecipeDetailsServiceTests.swift` | Suite for `RemoteRecipeDetailsService` over the spy |
| `RecipeEndpointTests.swift` | Two tests, no spy |
| `Helpers/` | The spy, domain fixtures, JSON builders, `invalidData` matcher |

### What is tested

**Endpoint:** the list URL; the details URL.

**List service:** requests the list endpoint's URL (two base URLs); valid JSON
maps to previews in order with every field (three recipes covering both
vegetarian values, a missing image and servings of 1); an empty list is an empty
array; client `notFound` gives `notFound`; undecodable data gives `invalidData`
with a reason (not JSON, wrong shape, wrong field type, one bad item in the
middle fails the whole list); any other client error gives `unavailable`.

**Details service:** requests the details URL for the id (three ids and base
URLs); valid JSON maps to the full recipe; out-of-order steps are sorted; a
recipe without photo, ingredients or instructions succeeds; client `notFound`
gives `notFound`; undecodable data gives `invalidData` with a reason (including
the `"step": "two"` shape); any other client error gives `unavailable`; unusable
ids (`""`, `" "`, `.`, `..`) give `notFound` without a request.

## Files this milestone adds

Under `ReciMate/`:

- `API/RecipeAPIClient.swift`: protocol and `RecipeAPIClientError`.
- `API/RecipeEndpoint.swift`: the URL map.
- `API/Infrastructure/LocalRecipeAPIClient.swift`: reads the bytes of the file the URL points at.
- `API/List/`, `API/Details/`: each holds the DTO, the service (protocol and concrete type) and its two mappers.
- `Domain/RecipeError.swift`: the three domain errors.

Under `ReciMateTests/`: the three suites and `Helpers/`. The two placeholder
`TestExample*.swift` files are deleted.

## Defaults taken for /spec

All stood, except where the sections above say superseded.

- **Names.** Protocols `RecipeListService` and `RecipeDetailsService`; concrete
  `RemoteRecipeListService` and `RemoteRecipeDetailsService`; client protocol
  `RecipeAPIClient` with `LocalRecipeAPIClient`; `RecipeEndpoint`.
- **One `RecipeEndpoint` enum** (decision 2b), not two endpoint types.
- **Placeholder base URL.** A constant in `ReciMateApp`, commented as unused by
  the local client (it only reads the last path component).
- **The `@concurrent` hop** is a private `@concurrent` method in each concrete
  service; building confirmed it compiles.
- **Services are structs** (no stored mutable state), so there is nothing to
  leak-track.
- **Out of scope, in [BACKLOG.md](../../product/BACKLOG.md):** pagination,
  cancellation handling, observability. Search (S1–S6) stays in milestone 004;
  `RecipeEndpoint.list` gains its parameters there.
