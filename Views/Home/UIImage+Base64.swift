import UIKit

extension UIImage {
    /// Returns a JPEG data URL string suitable for vision APIs (e.g., "data:image/jpeg;base64,....")
    /// - Parameter compressionQuality: JPEG compression quality between 0.0 and 1.0
    /// - Returns: A data URL string with base64-encoded JPEG contents, or nil if encoding fails.
    func jpegDataURLBase64(compressionQuality: CGFloat = 0.7) -> String? {
        guard let data = self.jpegData(compressionQuality: compressionQuality) else { return nil }
        let base64 = data.base64EncodedString()
        return "data:image/jpeg;base64,\(base64)"
    }
}
