//
//  CameraAccess.swift
//  DIYGenieApp
//

import SwiftUI
import AVFoundation

/// Centralized camera permission + single-session guard.
/// Usage in your view's button:
/// CameraAccess.request(isStarting: $isStartingCamera,
///                      isPresentingCamera: $isShowingCamera,
///                      isARPresented: showARSheet,
///                      isOverlayPresented: showOverlay) { alert("…") }
enum CameraAccess {
    static func request(isStarting: Binding<Bool>,
                        isPresentingCamera: Binding<Bool>,
                        isARPresented: Bool,
                        isOverlayPresented: Bool,
                        onDenied: @escaping () -> Void) {
        // Don’t stack multiple camera consumers (AR/overlay/camera)
        guard !isStarting.wrappedValue, !isARPresented, !isOverlayPresented else { return }

        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            isPresentingCamera.wrappedValue = true
            return
        case .denied, .restricted:
            onDenied()
            return
        case .notDetermined:
            break
        @unknown default:
            onDenied()
            return
        }

        isStarting.wrappedValue = true
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                isStarting.wrappedValue = false
                if granted {
                    isPresentingCamera.wrappedValue = true
                } else {
                    onDenied()
                }
            }
        }
    }
}
