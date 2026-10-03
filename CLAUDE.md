# ReciMate iOS Recipe App

This is a Swift/SwiftUI iOS application challenge to build a recipe browser with search and filtering.
- **Stack**: Swift 6+, SwiftUI, iOS 26+
- **Data**: Local JSON mock API (no network calls)
- **Key features**: Recipe list/grid, search, dietary/ingredient/servings filters
- **Focus areas**: Architecture clarity, error handling assumptions, edge case documentation

Use previews for UI validation. Keep code style consistent with existing views. When unclear on requirements, document assumptions in comments and the README.

## Build & Validation

Project `ReciMate.xcodeproj`, scheme `ReciMate`, test target `ReciMateTests` (Swift Testing), simulator `iPhone 17`.

- Run tests: `scripts/test.sh [scope]`. It builds the test products, runs the tests, and ends with `PASS` or `FAILED` plus the failure lines. Raw output goes to two logs: `build/build.log` (building) and `build/test.log` (running tests).
- Scope: none = full suite. `ReciMateTests/<Suite>` = one suite. `ReciMateTests/<Suite>/<test>()` = one test; the parentheses are required, otherwise no tests match and the script reports `no tests ran`.
- List tests: `xcodebuild test -enumerate-tests -project ReciMate.xcodeproj -scheme ReciMate -destination 'platform=iOS Simulator,name=iPhone 17'`
- Derived data: default Xcode location, kept between runs so builds stay incremental.
- Typecheck: covered by build
- Lint:      none
- Covers:    compiling the app and test target, and running the `ReciMateTests` unit tests on the simulator. No UI tests exist yet.

Test loop:
- At the start of a session, boot the simulator once: `xcrun simctl boot "iPhone 17"` (an error saying it is already booted is fine). A booted simulator makes every later run much faster.
- Before every `scripts/test.sh` run, put this line in your message so I can watch live from another terminal: `tail -F <repo root>/build/build.log <repo root>/build/test.log` (use the real absolute path; the script also prints it as `WATCH LIVE:`).
- While working on a piece (a view model, a model, one step of a spec), run only the tests for that piece: one test, then its suite. Don't run the full suite after every edit.
- Run the full suite once, when the whole spec is finished, before declaring done.
- Prefer the cheapest layer: unit tests for logic, models and view models; simulator or UI checks only when the change is about navigation, gestures or visuals.
- Read `build/build.log` or `build/test.log` only when the failure lines printed by the script are not enough.
- Do not run `xcodebuild clean` or delete DerivedData unless diagnosing a build-cache problem.

## Stop rules (while implementing)

- If a step doesn't need my input, keep working. Don't stop just to report progress; write the update and go straight to the next step.
- Stop and ask only if you're blocked without me, or before anything destructive: deleting data, force-pushing, or changing files outside this repo.
- If you leave the plan in `specs/<slug>/SPEC.md`, take the safer option, keep going, and add one line under `## Deviations` in `specs/<slug>/implementation-notes.md` saying what changed and why.

## Git

- IMPORTANT: Every commit message must follow Conventional Commits 1.0.0 (https://www.conventionalcommits.org/en/v1.0.0/): `<type>[optional scope]: <description>`, with an optional body and footers.
- Types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert.
- Description: imperative mood, lowercase, no trailing period. Mark breaking changes with `!` after the type/scope or a `BREAKING CHANGE:` footer.
- Write the message in this format the first time; do not draft a free-form message and rewrite it afterwards.
