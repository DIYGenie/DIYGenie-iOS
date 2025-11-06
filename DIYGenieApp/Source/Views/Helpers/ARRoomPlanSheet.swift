//
//  ARRoomPlanSheet.swift
//  DIYGenieApp
//
//  SwiftUI wrapper around RoomPlan’s RoomCaptureView.
//  Exports a .usdz to a temporary URL and returns it via onExport.
//
import SwiftUI
import RoomPlan
import UIKit

#if canImport(RoomPlan)
@available(iOS 17.0, *)
struct ARRoomPlanSheet: UIViewRepresentable {
    let projectId: String
    let onExport: (URL) -> Void   // called once with the temp .usdz URL

    func makeCoordinator() -> Coordinator { Coordinator(onExport: onExport) }

    func makeUIView(context: Context) -> RoomCaptureView {
        let view = RoomCaptureView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.captureSession.delegate = context.coordinator     // session lifecycle
        view.delegate = context.coordinator                    // view callbacks
        // Start scanning immediately
        var config = RoomCaptureSession.Configuration()
        view.captureSession.run(configuration: config)
        return view
    }

    func updateUIView(_ uiView: RoomCaptureView, context: Context) {
        // no-op; we don’t stream UI updates during capture
    }

    // MARK: - Coordinator
    static var supportsSecureCoding: Bool { true }
    
    @objc(ARRoomPlanSheetCoordinator) final class Coordinator: NSObject, RoomCaptureSessionDelegate, RoomCaptureViewDelegate, NSSecureCoding {
       
        static var supportsSecureCoding: Bool { true }
        private let onExport: (URL) -> Void
        private var hasExported = false

        init(onExport: @escaping (URL) -> Void) {
            self.onExport = onExport
        }
        @objc required init?(coder: NSCoder) {
            // Not used — needed only to satisfy NSSecureCoding
            return nil
        }

        @objc func encode(with coder: NSCoder) {
            // No-op — we never archive this coordinator
        }
        // Live updates if you ever want them
        func captureSession(_ session: RoomCaptureSession, didUpdate room: CapturedRoom) { }

        // Finished capture → export .usdz → hand back URL
        func captureSession(_ session: RoomCaptureSession,
                            didEndWith room: CapturedRoom,
                            error: Error?) {
            guard !hasExported else { return }
            if let error = error {
                print("RoomPlan error:", error.localizedDescription)
                return
            }
            hasExported = true
            let tmp = FileManager.default.temporaryDirectory
                .appendingPathComponent("scan-\(UUID().uuidString).usdz")
            do {
                try room.export(to: tmp)
                // Small delay lets the view tear down cleanly before you present next UI
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.onExport(tmp)
                }
            } catch {
                print("Export failed:", error.localizedDescription)
            }
        }
    }
}
#endif

