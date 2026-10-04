/// The servings line shared by the Library card and the Details screen.
enum ServingsLabelFormatter {
    /// "1 serving", "2 servings". English only; String Catalog plural variation is in the backlog.
    static func label(forServingCount servingCount: Int) -> String {
        servingCount == 1 ? "1 serving" : "\(servingCount) servings"
    }
}
