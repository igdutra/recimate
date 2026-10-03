#!/usr/bin/env bash
# Build the test products, then run tests, with live progress and a short result.
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
