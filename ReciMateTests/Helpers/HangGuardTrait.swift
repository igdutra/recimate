import Testing

extension Trait where Self == TimeLimitTrait {
    
    // Author note: Extracting this as a DSL property allow us to use it with better intent - making our intention clear.
    
    /// A guardrail against hangs, not a performance budget.
    ///
    /// A test that loads through a service spy suspends until the test completes
    /// or fails the request. A regression that sends an unexpected request, or
    /// never finishes one, would then stall the whole run instead of failing.
    /// Swift Testing's time limit turns that into a failed test.
    ///
    /// Named for its intent: the value (one minute, the shortest Swift Testing
    /// supports) says nothing about why the limit is there, `hangGuard` does.
    /// Apply it to a whole suite whose tests await a spy, so tests added later
    /// are covered too: `@Suite(.hangGuard)`. On a suite it applies to each test,
    /// and to each case of a parameterized test.
    static var hangGuard: Self {
        .timeLimit(.minutes(1))
    }
}
