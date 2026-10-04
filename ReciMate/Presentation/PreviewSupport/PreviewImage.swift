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
