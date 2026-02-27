import UIKit
import Foundation

// MARK: - Image File Storage
// Saves as HEIC (much smaller than JPEG, ~50% less disk/memory, less lag).
// Falls back to JPEG if HEIC is unavailable.
struct ImageFileStorage {
    private static var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    @discardableResult
    static func save(_ image: UIImage, compressionQuality: CGFloat = 0.7) -> String? {
        // Try HEIC first — half the size of JPEG at same quality
        if let data = image.heicData(compressionQuality: compressionQuality) {
            let filename = UUID().uuidString + ".heic"
            let url = documentsURL.appendingPathComponent(filename)
            do {
                try data.write(to: url, options: .atomic)
                return filename
            } catch {
                print("ImageFileStorage: HEIC write failed: \(error)")
            }
        }
        // Fallback to JPEG
        guard let data = image.jpegData(compressionQuality: compressionQuality) else { return nil }
        let filename = UUID().uuidString + ".jpg"
        let url = documentsURL.appendingPathComponent(filename)
        do {
            try data.write(to: url, options: .atomic)
            return filename
        } catch {
            print("ImageFileStorage: JPEG write failed: \(error)")
            return nil
        }
    }

    static func load(_ filename: String?) -> UIImage? {
        guard let filename, !filename.isEmpty else { return nil }
        let url = documentsURL.appendingPathComponent(filename)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return UIImage(contentsOfFile: url.path)
    }

    static func delete(_ filename: String?) {
        guard let filename, !filename.isEmpty else { return }
        try? FileManager.default.removeItem(at: documentsURL.appendingPathComponent(filename))
    }

    @discardableResult
    static func replace(old oldFilename: String?, with image: UIImage, compressionQuality: CGFloat = 0.7) -> String? {
        delete(oldFilename)
        return save(image, compressionQuality: compressionQuality)
    }
}

// MARK: - UIImage HEIC helper
private extension UIImage {
    func heicData(compressionQuality: CGFloat) -> Data? {
        let data = NSMutableData()
        guard
            let destination = CGImageDestinationCreateWithData(data, "public.heic" as CFString, 1, nil),
            let cgImage = self.cgImage
        else { return nil }
        CGImageDestinationAddImage(destination, cgImage, [
            kCGImageDestinationLossyCompressionQuality: compressionQuality
        ] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return data as Data
    }
}

// MARK: - Voice File Storage
struct VoiceFileStorage {
    private static var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    static func save(from tempURL: URL) -> String? {
        let filename = "voice_\(UUID().uuidString).m4a"
        let dest = documentsURL.appendingPathComponent(filename)
        do {
            if FileManager.default.fileExists(atPath: dest.path) {
                try FileManager.default.removeItem(at: dest)
            }
            try FileManager.default.copyItem(at: tempURL, to: dest)
            return filename
        } catch {
            print("VoiceFileStorage: save failed: \(error)")
            return nil
        }
    }

    static func url(for filename: String?) -> URL? {
        guard let filename, !filename.isEmpty else { return nil }
        let url = documentsURL.appendingPathComponent(filename)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    static func delete(_ filename: String?) {
        guard let filename, !filename.isEmpty else { return }
        try? FileManager.default.removeItem(at: documentsURL.appendingPathComponent(filename))
    }
}