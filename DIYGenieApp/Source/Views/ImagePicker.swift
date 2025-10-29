//
//  ImagePicker.swift
//  DIYGenieApp
//

import SwiftUI
import UIKit

struct ImagePicker: UIViewControllerRepresentable {
    enum SourceType {
        case camera
        case photoLibrary

        var uiKitType: UIImagePickerController.SourceType {
            switch self {
            case .camera: return .camera
            case .photoLibrary: return .photoLibrary
            }
        }
    }

    var sourceType: SourceType
    var onImagePicked: (UIImage?) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType.uiKitType
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            picker.dismiss(animated: true)
            let image = info[.originalImage] as? UIImage
            parent.onImagePicked(image)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
            parent.onImagePicked(nil)
        }
    }
}
