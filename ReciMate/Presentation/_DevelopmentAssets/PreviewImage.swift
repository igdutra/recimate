// DEVELOPMENT ASSETS: this whole folder is listed in DEVELOPMENT_ASSET_PATHS (app target).
// Xcode leaves these files out of the build input only when ARCHIVING, but they are still
// compiled in every other build. So any code that uses them in a Release/Archive build would
// not find them and fail the archive, a failure that tends to show up late, in CI.
// Therefore: (1) wrap every file here in `#if DEBUG`, and (2) only reference these types from
// code that is also inside `#if DEBUG`, such as `#Preview` blocks.

#if DEBUG
import UIKit

/// A photo stand-in written to a local file, so previews show a loaded image
/// without touching the network.
enum PreviewImage {
    static let fileURL: URL? = {
        let size = CGSize(width: 320, height: 280)
        let image = UIGraphicsImageRenderer(size: size).image { context in
            UIColor.systemTeal.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            UIColor.white.withAlphaComponent(0.6).setFill()
            context.cgContext.fillEllipse(in: CGRect(x: 60, y: 40, width: 200, height: 200))
        }
        let fileURL = FileManager.default.temporaryDirectory.appending(path: "recimate-preview-photo.png")
        do {
            try image.pngData()?.write(to: fileURL)
            return fileURL
        } catch {
            return nil
        }
    }()

    /// A URL that fails to load, to show the placeholder.
    static let failingURL = URL(string: "file:///recimate-missing-photo.png")
}
#endif
