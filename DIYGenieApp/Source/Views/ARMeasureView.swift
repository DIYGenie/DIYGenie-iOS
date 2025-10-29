//
//  ARMeasureView.swift
//  DIYGenie
//

import SwiftUI
import ARKit
import RealityKit
import Combine

struct ARMeasureView: View {
    let projectId: String
    let scanId: String
    var onComplete: ((Double, Double) -> Void)? = nil
    // ..
    @Environment(\.dismiss) private var dismiss
    @State private var roi: CGRect = CGRect(x: 0.3, y: 0.4, width: 0.4, height: 0.25)
    @State private var isSaving = false
    @State private var statusMessage: String?
    @State private var cancellables = Set<AnyCancellable>()

    var body: some View {
        ZStack {
            ARViewContainer()
                .ignoresSafeArea()

            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.purple.opacity(0.9), lineWidth: 3)
                    .shadow(color: .purple, radius: 12)
                    .frame(
                        width: geo.size.width * roi.width,
                        height: geo.size.height * roi.height
                    )
                    .position(
                        x: geo.size.width * (roi.origin.x + roi.width / 2),
                        y: geo.size.height * (roi.origin.y + roi.height / 2)
                    )
                    .gesture(DragGesture()
                        .onChanged { value in
                            let w = roi.width, h = roi.height
                            let nx = min(max(0, value.location.x / geo.size.width - w / 2), 1 - w)
                            let ny = min(max(0, value.location.y / geo.size.height - h / 2), 1 - h)
                            roi.origin = CGPoint(x: nx, y: ny)
                        }
                    )
            }

            VStack {
                Spacer()
                if let msg = statusMessage {
                    Text(msg)
                        .foregroundColor(.white)
                        .padding(.bottom, 8)
                        .transition(.opacity)
                }

                HStack {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(8)

                    Spacer()

                    Button(isSaving ? "Saving…" : "Save Measurement") {
                        Task { await saveMeasurement() }
                    }
                    .disabled(isSaving)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.purple.opacity(0.9))
                    .cornerRadius(8)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 25)
            }
        }
    }

    private func saveMeasurement() async {
        guard !isSaving else { return }
        isSaving = true
        statusMessage = "Saving measurement…"

        guard let userId = UserDefaults.standard.string(forKey: "user_id") else {
            statusMessage = "Missing user ID"
            isSaving = false
            return
        }

        let body: [String: Any] = [
            "user_id": userId,
            "roi": [
                "x": roi.origin.x,
                "y": roi.origin.y,
                "w": roi.width,
                "h": roi.height
            ]
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            statusMessage = "Encoding failed"
            isSaving = false
            return
        }

        guard let url = URL(string: "https://api.diygenieapp.com/api/projects/\(projectId)/scans/\(scanId)/measure") else {
            statusMessage = "Invalid URL"
            isSaving = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   json["ok"] as? Bool == true {
                    statusMessage = "Measurement saved ✅"
                    try? await Task.sleep(nanoseconds: 1_200_000_000)
                    dismiss()
                } else {
                    statusMessage = "Server returned unexpected data"
                }
            } else {
                statusMessage = "Server error"
            }
        } catch {
            statusMessage = "Network error: \(error.localizedDescription)"
        }

        isSaving = false
    }
}

struct ARViewContainer: UIViewRepresentable {
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        arView.session.run(config)
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}
}
