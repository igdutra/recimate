import Testing

/// A controllable stand-in for one async service call, for tests that must look
/// at the code under test while a request is in flight. Each call to `load`
/// records a request and suspends until the test completes or fails it.
///
/// `@MainActor`, like the suites that use it, so its state needs no lock and no
/// `nonisolated(unsafe)`. Each request is one `AsyncThrowingStream`: `yield` plus
/// `finish` succeeds, `finish(throwing:)` fails. The test then waits, bounded, with
/// `Task.yield()` until the awaiting side has recorded how the request ended.
///
/// This pattern (a spy over `AsyncThrowingStream`, waiting with `Task.yield()`)
/// comes from the Essential Developer course's async loader spy. Cancellation
/// support is left out because cancellation handling is a backlog item.
@MainActor
final class ServiceSpy<Parameter, Resource: Sendable> {
    enum Outcome: Equatable {
        case succeeded
        case failed
    }

    struct Request {
        let parameter: Parameter
        fileprivate let continuation: AsyncThrowingStream<Resource, any Error>.Continuation
        fileprivate(set) var outcome: Outcome?
    }

    private struct NoResponse: Error {}

    private(set) var requests: [Request] = []

    /// What the code under test calls. Suspends until the test completes or fails the request.
    func load(_ parameter: Parameter) async throws -> Resource {
        let (stream, continuation) = AsyncThrowingStream<Resource, any Error>.makeStream()
        let requestIndex = requests.count
        requests.append(Request(parameter: parameter, continuation: continuation, outcome: nil))

        do {
            for try await resource in stream {
                requests[requestIndex].outcome = .succeeded
                return resource
            }
            throw NoResponse()
        } catch {
            requests[requestIndex].outcome = .failed
            throw error
        }
    }

    func complete(with resource: Resource, at requestIndex: Int = 0, sourceLocation: SourceLocation = #_sourceLocation) async {
        guard hasRequest(at: requestIndex, sourceLocation: sourceLocation) else { return }
        requests[requestIndex].continuation.yield(resource)
        requests[requestIndex].continuation.finish()
        await waitForOutcome(at: requestIndex, sourceLocation: sourceLocation)
    }

    func fail(with error: any Error, at requestIndex: Int = 0, sourceLocation: SourceLocation = #_sourceLocation) async {
        guard hasRequest(at: requestIndex, sourceLocation: sourceLocation) else { return }
        requests[requestIndex].continuation.finish(throwing: error)
        await waitForOutcome(at: requestIndex, sourceLocation: sourceLocation)
    }

    /// Fails every request still waiting, so a test that found an unexpected extra
    /// request ends with a failed expectation instead of waiting for it forever.
    func failPendingRequests(sourceLocation: SourceLocation = #_sourceLocation) async {
        for requestIndex in requests.indices where requests[requestIndex].outcome == nil {
            requests[requestIndex].continuation.finish(throwing: CancellationError())
            await waitForOutcome(at: requestIndex, sourceLocation: sourceLocation)
        }
    }

    /// Gives the code under test turns to reach `load`, instead of guessing that one yield is enough.
    func waitUntilRequested(
        count expectedCount: Int,
        timeout: Duration = .seconds(1),
        sourceLocation: SourceLocation = #_sourceLocation
    ) async {
        let deadline = ContinuousClock.now + timeout
        while requests.count < expectedCount {
            guard ContinuousClock.now < deadline else {
                Issue.record("Timed out waiting for \(expectedCount) request(s); got \(requests.count)", sourceLocation: sourceLocation)
                return
            }
            await Task.yield()
        }
    }

    private func hasRequest(at requestIndex: Int, sourceLocation: SourceLocation) -> Bool {
        let exists = requests.indices.contains(requestIndex)
        if !exists {
            Issue.record("No request at index \(requestIndex); got \(requests.count)", sourceLocation: sourceLocation)
        }
        return exists
    }

    private func waitForOutcome(at requestIndex: Int, timeout: Duration = .seconds(1), sourceLocation: SourceLocation) async {
        let deadline = ContinuousClock.now + timeout
        while requests[requestIndex].outcome == nil {
            guard ContinuousClock.now < deadline else {
                Issue.record("Timed out waiting for request \(requestIndex) to finish", sourceLocation: sourceLocation)
                return
            }
            await Task.yield()
        }
    }
}
