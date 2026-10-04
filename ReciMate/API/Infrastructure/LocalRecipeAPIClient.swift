import Foundation

/// Stands in for a server: serves the bundled JSON fixtures. It ignores the
/// URL's scheme and host and reads `<last path component>.json` from the
/// bundle root (the fixtures are bundled flat, so file names must stay unique).
/// A missing file is `RecipeAPIClientError.notFound`; any other read failure
/// passes through untouched.
struct LocalRecipeAPIClient: RecipeAPIClient {
    let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    func data(from url: URL) async throws -> Data {
        guard let fileURL = bundle.url(forResource: url.lastPathComponent, withExtension: "json") else {
            throw RecipeAPIClientError.notFound
        }
        return try Data(contentsOf: fileURL)
    }
}
