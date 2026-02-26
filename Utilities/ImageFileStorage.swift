import UIKit

// MARK: - ImageFileStorage
// Saves/loads images as JPEG files in the app's Documents directory.
// Only a filename string is stored in models/UserDefaults — never raw Data.
enum ImageFileStorage {

    private static var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    /// Save a UIImage to disk. Images should already be downscaled by ImagePicker.
    /// Returns the filename (UUID-based), or nil on failure.
    @discardableResult
    static func save(_ image: UIImage, compressionQuality: CGFloat = 0.7) -> String? {
        guard let data = image.jpegData(compressionQuality: compressionQuality) else { return nil }
        let filename = UUID().uuidString + ".jpg"
        let url = documentsURL.appendingPathComponent(filename)
        do {
            try data.write(to: url, options: .atomic)
            return filename
        } catch {
            print("ImageFileStorage: failed to write \(filename): \(error)")
            return nil
        }
    }

    /// Load a UIImage from a previously saved filename. Returns nil if not found.
    static func load(_ filename: String?) -> UIImage? {
        guard let filename, !filename.isEmpty else { return nil }
        let url = documentsURL.appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    /// Delete the file for a given filename. Safe to call with nil.
    static func delete(_ filename: String?) {
        guard let filename, !filename.isEmpty else { return }
        let url = documentsURL.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: url)
    }

    /// Replace an existing file — deletes old one, saves new image.
    @discardableResult
    static func replace(old filename: String?, with image: UIImage, compressionQuality: CGFloat = 0.7) -> String? {
        delete(filename)
        return save(image, compressionQuality: compressionQuality)
    }
}