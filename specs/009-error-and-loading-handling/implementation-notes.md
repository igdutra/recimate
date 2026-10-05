# 009 Error and loading handling: implementation notes

## Assumptions

- A recipe the Library shows has a detail, so a missing or malformed one is our data's fault and shows the error, not a "no detail" state.
- Two recipes fail on purpose and say so in their titles: `creamy-tomato-pasta` (malformed detail, `invalidData`) and `beef-tacos` (no detail file, `notFound`).
- One message per error kind, worded to fit either screen; `invalidData`'s reason is never shown.
- The mock's one-second wait applies to every request, searches included; typing waits 0.3 seconds before searching.
- Search text is trimmed before it is compared, so text that differs only by spaces does not search again.

## Deviations

- The Library covers only its grid with `opacity(0)` and `.disabled` (`coveredBy(state:)`), and `stateOverlay(state:hidesContent:retry:)` is called with `hidesContent: false` there: fading the whole `ScrollView` also faded the large "Recipes" title, which AC1 wants visible. Details keeps the default.
- The failing titles are "Creamy Tomato Pasta (Fails: Data)" and "Beef Tacos (Fails: Not Found)", not "(Fails: Bad Data)": the long suffix was cut off at the card's two lines (step 9, simulator). The spec's wording for that title is therefore shortened.
- `typingAfterAFilterChange_keepsTheFilters` now expects one request, not two, for two quick filter changes: the debounce task's `Task.sleep` lets the second change cancel the first search before it reaches the service.
- Not verified in the simulator: tapping a recipe (Details spinner, both errors, Try Again, back button, Details centering), because there is no tool here to tap the simulator. Library spinner, title and card fit were checked from screenshots.
