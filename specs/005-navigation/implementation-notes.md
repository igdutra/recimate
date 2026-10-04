Created: 2026-10-04
Updated: 2026-10-04

# 005 Navigation: implementation notes

## Deviations


- The router's path is a typed `[AppRoute]`, not the opaque `NavigationPath` the reference used: there is one fixed route type, and tests can compare the path directly. A mixed-type path would need `NavigationPath` back.

- Design: the Filters chip is removed from the quick chip row (Vegetarian and Servings stay). The Filters entry point is the toolbar button in the navigation bar, so the screen has one way into the sheet and the chips are only quick filters. Design frame 1 of spec 003/004 still shows the chip. Not a tab bar: a tab bar holds top-level destinations, not an action on one screen.

- `RecipeLibraryView` wraps its content in a `ZStack`, not the `Group` the spec named. While loading, the content is empty, and `.task` on an empty `Group` never ran, so the app launched to a blank screen and never loaded recipes. Found by launching in the simulator.
