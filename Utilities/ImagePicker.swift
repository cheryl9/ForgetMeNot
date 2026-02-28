import SwiftUI
import UIKit

// MARK: - ImagePicker
// Uses UIImagePickerController. Images are downscaled on a background thread
// before being delivered — prevents freezing with large library photos.
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss
    var sourceType: UIImagePickerController.SourceType = .photoLibrary

    // Max dimension in pixels — keeps file size small, more than enough for display
    static let maxDimension: CGFloat = 800

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.allowsEditing = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    // MARK: - Coordinator
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) { self.parent = parent }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            // Dismiss immediately so UI feels responsive
            picker.dismiss(animated: true)

            guard let raw = info[.originalImage] as? UIImage else { return }

            // Process on background thread — large images can be 15MB+
            DispatchQueue.global(qos: .userInitiated).async {
                let processed = raw.normalised().downscaled(to: ImagePicker.maxDimension)
                DispatchQueue.main.async {
                    self.parent.image = processed
                }
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - UIImage helpers
extension UIImage {
    /// Fix EXIF orientation so image always renders upright.
    func normalised() -> UIImage {
        guard imageOrientation != .up else { return self }
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let result = UIGraphicsGetImageFromCurrentImageContext() ?? self
        UIGraphicsEndImageContext()
        return result
    }

    /// Downscale so neither dimension exceeds `maxDimension`. Preserves aspect ratio.
    func downscaled(to maxDimension: CGFloat) -> UIImage {
        let w = size.width
        let h = size.height
        guard w > maxDimension || h > maxDimension else { return self }

        let scale = min(maxDimension / w, maxDimension / h)
        let newSize = CGSize(width: w * scale, height: h * scale)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0) // scale=1 → actual pixels
        draw(in: CGRect(origin: .zero, size: newSize))
        let result = UIGraphicsGetImageFromCurrentImageContext() ?? self
        UIGraphicsEndImageContext()
        return result
    }
}