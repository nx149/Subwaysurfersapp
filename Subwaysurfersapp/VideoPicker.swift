import SwiftUI
import PhotosUI

struct VideoPicker: UIViewControllerRepresentable {
    @Binding var videoURL: URL?

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .videos
        config.selectionLimit = 1

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: VideoPicker
        init(_ parent: VideoPicker) { self.parent = parent }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let item = results.first?.itemProvider else { return }

            if item.hasItemConformingToTypeIdentifier("public.movie") {
                item.loadFileRepresentation(forTypeIdentifier: "public.movie") { url, error in
                    guard let url = url else { return }
                    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
                    try? FileManager.default.removeItem(at: tempURL)
                    try? FileManager.default.copyItem(at: url, to: tempURL)
                    DispatchQueue.main.async {
                        self.parent.videoURL = tempURL
                    }
                }
            }
        }
    }
}
