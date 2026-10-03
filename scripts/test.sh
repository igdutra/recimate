#!/usr/bin/env bash
# Build the test products, then run tests, with live progress and a short result.
#
# WHY THIS SCRIPT EXISTS, AND WHY NOT `swift test`
#
# `swift test` is for Swift Package Manager packages (a Package.swift) and runs
# on the Mac itself. ReciMate is an Xcode iOS app: there is no Package.swift,
# the tests do `@testable import ReciMate` against the app target, and they need
# the iOS Simulator. `xcodebuild` is the only command-line way to build and run
# them, so we wrap it instead of replacing it.
#
# Plain `xcodebuild test` has problems for an AI agent (and for a human watching):
#   - Output is thousands of lines. Reading it all burns context and hides the
#     one line that matters. This script prints only result lines, plus PASS or
#     FAILED and the failure, and keeps the raw output in logs.
#   - Nothing shows for minutes, so it looks stuck. Phase lines and the
#     `tail -F` hint below give live feedback.
#   - A scope that matches no tests (a typo, or `example` instead of `example()`)
#     exits 0 and looks like success. We count tests and fail on zero.
#   - Xcode clones the simulator for every run, about 40s each time. We turn that
#     off with -parallel-testing-enabled NO so tests run on the booted
#     simulator, about 4s. With 2 tiny tests parallelism buys nothing; revisit
#     it if the suite grows large.
#   - `build-for-testing` then `test-without-building` is Apple's supported
#     split. We still build every run, because test-without-building does not
#     recompile. With no source changes the build is a quick no-op, and with
#     changes it is exactly what is needed. We never clean: DerivedData stays
#     warm so builds stay incremental.
#   - The simulator is booted once and left running, not started for each run.
#
# Usage:
#   scripts/test.sh                                  run the full suite
#   scripts/test.sh ReciMateTests/<Suite>            run one suite
#   scripts/test.sh ReciMateTests/<Suite>/<test>     run one test
#
# Raw xcodebuild output goes to two gitignored logs: build/build.log (building)
# and build/test.log (running tests).
# Watch live from another terminal with the `tail -F` line printed first.

set -u

projectName="ReciMate"
schemeName="ReciMate"
simulatorName="iPhone 17"
testScope="${1:-}"

repoRoot="$(git rev-parse --show-toplevel)"
buildLogPath="$repoRoot/build/build.log"
testLogPath="$repoRoot/build/test.log"
mkdir -p "$repoRoot/build"
: > "$buildLogPath"
: > "$testLogPath"

echo "WATCH LIVE: tail -F \"$buildLogPath\" \"$testLogPath\""

# Keep the simulator running between runs. A no-op if it is already booted.
xcrun simctl boot "$simulatorName" >/dev/null 2>&1 || true

xcodebuildBase=(
  xcodebuild
  -project "$repoRoot/$projectName.xcodeproj"
  -scheme "$schemeName"
  -destination "platform=iOS Simulator,name=$simulatorName"
)

startTime=$SECONDS

echo "[1/2] building test products..."
"${xcodebuildBase[@]}" build-for-testing >> "$buildLogPath" 2>&1
buildExitCode=$?
if [ "$buildExitCode" -ne 0 ]; then
  echo "FAILED: build ($((SECONDS - startTime))s)"
  rg "error:" "$buildLogPath" | sort -u | head -20
  echo "full log: $buildLogPath"
  exit 1
fi
echo "      built in $((SECONDS - startTime))s"

testArguments=(-parallel-testing-enabled NO)
if [ -n "$testScope" ]; then
  testArguments+=("-only-testing:$testScope")
  echo "[2/2] running tests: $testScope"
else
  echo "[2/2] running tests: full suite"
fi

testStartTime=$SECONDS
# Stream only result lines to the terminal; everything goes to the log.
"${xcodebuildBase[@]}" test-without-building ${testArguments[@]+"${testArguments[@]}"} 2>&1 \
  | tee -a "$testLogPath" \
  | rg --line-buffered "^(✔|✘) Test |error:"
testExitCode=${PIPESTATUS[0]}

# Swift Testing ends with "Test run with N tests in M suites passed|failed".
testCount=$(rg -o "Test run with [0-9]+ test" "$testLogPath" | rg -o "[0-9]+" | head -1)
testCount=${testCount:-0}
echo "ran $testCount tests in $((SECONDS - testStartTime))s"

# A scope that matches nothing exits 0 with zero tests, so treat that as a failure.
if [ "$testExitCode" -eq 0 ] && [ "$testCount" -eq 0 ]; then
  echo "FAILED: no tests ran. Check the scope; test functions need parentheses, e.g. ReciMateTests/TestExample1/example()"
  exit 1
fi

if [ "$testExitCode" -eq 0 ]; then
  echo "PASS"
  exit 0
fi

echo "FAILED"
rg "recorded an issue|error:" "$testLogPath" | sort -u | head -20
echo "full log: $testLogPath"
exit 1
