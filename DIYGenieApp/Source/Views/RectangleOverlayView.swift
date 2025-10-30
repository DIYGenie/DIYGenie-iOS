//  RectangleOverlayView.swift
//  DIYGenie-iOS
//
//  SwiftUI + UIViewRepresentable overlay that lets a user drag/resize a rectangular ROI
//  on a given image, then posts the normalized ROI to /api/projects/:id/preview.
//  Leaves navigation to the caller via onCancel/onComplete closures.
//  Dependencies: Swift 5.9+, iOS 16+ (tested iOS 17+)

import SwiftUI
import UIKit
import QuartzCore

// MARK: - ROI Model
struct NormalizedROI: Codable, Equatable {
    let x: CGFloat  // left, 0..1
    let y: CGFloat  // top, 0..1
    let w: CGFloat  // width, 0..1
    let h: CGFloat  // height, 0..1
}

// MARK: - Network DTOs
private struct PreviewRequestBody: Codable {
    let user_id: String
    let roi: NormalizedROI
}

private struct PreviewResponse: Codable {
    let preview_url: String?
    let status: String?
    let message: String?
}

// MARK: - Network Client
final class DIYGenieAPIClient {
    static let shared = DIYGenieAPIClient()
    private init() {}

    private let baseURL = URL(string: "https://api.diygenieapp.com")!

    func requestPreview(projectId: String, userId: String, roi: NormalizedROI) async throws -> PreviewResponse {
        var url = baseURL
        url.append(path: "/api/projects/\(projectId)/preview")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = PreviewRequestBody(user_id: userId, roi: roi)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200..<300).contains(http.statusCode) else {
            // Surface server message if present
            if let server = try? JSONDecoder().decode(PreviewResponse.self, from: data),
               let msg = server.message {
                throw NSError(domain: "DIYGenieAPI", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: msg])
            }
            throw NSError(domain: "DIYGenieAPI", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "Preview request failed (\(http.statusCode))."])
        }

        return (try? JSONDecoder().decode(PreviewResponse.self, from: data)) ?? PreviewResponse(preview_url: nil, status: "ok", message: nil)
    }
}

// MARK: - SwiftUI Wrapper
struct RectangleOverlayView: View {
    let image: UIImage
    let projectId: String
    let userId: String
    var onCancel: () -> Void
    var onComplete: (NormalizedROI) -> Void
    var onError: (Error) -> Void

    @State private var isSubmitting = false

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("Cancel") { onCancel() }
                    Spacer()
                    Text("Select Area")
                        .font(.system(size: 17, weight: .semibold))
                    Spacer()
                    // Reserve space to balance layout
                    Color.clear.frame(width: 60, height: 1)
                }
                .padding(.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 8)

                Divider()

                // Overlay canvas
                OverlayCanvasRepresentable(image: image) { roi in
                    Task {
                        await submitROI(roi)
                    }
                }
                .overlay(alignment: .bottom) {
                    VStack(spacing: 8) {
                        Divider()
                        HStack(spacing: 12) {
                            Text("Drag the corners to outline your target area. Tap Confirm when ready.")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                            Spacer()
                            if isSubmitting {
                                ProgressView().controlSize(.small)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 10)
                    }
                    .background(.ultraThinMaterial)
                }
            }
        }
        .interactiveDismissDisabled(isSubmitting)
    }

    @MainActor
    private func submitROI(_ roi: NormalizedROI) async {
        guard !isSubmitting else { return }
        isSubmitting = true
        do {
            _ = try await DIYGenieAPIClient.shared.requestPreview(projectId: projectId, userId: userId, roi: roi)
            isSubmitting = false
            onComplete(roi)
        } catch {
            isSubmitting = false
            onError(error)
        }
    }
}

// MARK: - UIViewRepresentable Overlay
fileprivate struct OverlayCanvasRepresentable: UIViewRepresentable {
    let image: UIImage
    let onConfirm: (NormalizedROI) -> Void

    func makeUIView(context: Context) -> OverlayCanvasView {
        let view = OverlayCanvasView()
        view.configure(with: image)
        view.onConfirm = onConfirm
        return view
    }

    func updateUIView(_ uiView: OverlayCanvasView, context: Context) {
        // If the image changes (rare), reconfigure
        if uiView.imageView.image !== image {
            uiView.configure(with: image)
        }
    }
}

// MARK: - UIKit Canvas
fileprivate final class OverlayCanvasView: UIView, UIGestureRecognizerDelegate {
    // Public callback
    var onConfirm: ((NormalizedROI) -> Void)?

    // UI Elements
    let imageView = UIImageView()
    private let overlayLayer = CAShapeLayer()
    private let borderLayer = CAShapeLayer()
    private var handleLayers: [CAShapeLayer] = []

    // Buttons
    private let confirmButton = UIButton(type: .system)
    private let resetButton = UIButton(type: .system)

    // Gesture state
    private var draggingHandleIndex: Int? = nil
    private var draggingWholeRect = false
    private var lastDragPoint: CGPoint = .zero

    // ROI in imageView-coordinates (display space)
    private var roiRect: CGRect = .zero

    // Constants
    private let minRectSize: CGFloat = 40
    private let handleSize: CGFloat = 18
    private let handleHitSlop: CGFloat = 24
    private let borderWidth: CGFloat = 2

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    func configure(with image: UIImage) {
        imageView.image = image
        setNeedsLayout()
        layoutIfNeeded()
        initializeROI()
        redraw()
    }

    // MARK: Setup
    private func setup() {
        backgroundColor = .systemBackground

        // Image
        imageView.contentMode = .scaleAspectFit
        imageView.layer.masksToBounds = true
        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -64) // leave bottom room for buttons
        ])

        // Overlay layers
        overlayLayer.fillRule = .evenOdd
        overlayLayer.fillColor = UIColor.black.withAlphaComponent(0.35).cgColor

        borderLayer.strokeColor = UIColor.label.withAlphaComponent(0.9).cgColor
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.lineWidth = borderWidth
        layer.addSublayer(overlayLayer)
        layer.addSublayer(borderLayer)

        // Handles
        handleLayers = (0..<4).map { _ in
            let l = CAShapeLayer()
            l.fillColor = UIColor.systemBackground.cgColor
            l.strokeColor = UIColor.label.cgColor
            l.lineWidth = 1
            layer.addSublayer(l)
            return l
        }

        // Buttons bar
        let bar = UIView()
        bar.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.9)
        addSubview(bar)
        bar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bar.leadingAnchor.constraint(equalTo: leadingAnchor),
            bar.trailingAnchor.constraint(equalTo: trailingAnchor),
            bar.bottomAnchor.constraint(equalTo: bottomAnchor),
            bar.heightAnchor.constraint(equalToConstant: 64)
        ])

        confirmButton.setTitle("Confirm", for: .normal)
        confirmButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)

        resetButton.setTitle("Reset", for: .normal)
        resetButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .regular)
        resetButton.addTarget(self, action: #selector(resetTapped), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [resetButton, UIView(), confirmButton])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 16
        bar.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: bar.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: bar.trailingAnchor, constant: -16),
            stack.centerYAnchor.constraint(equalTo: bar.centerYAnchor)
        ])

        // Gestures
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.delegate = self
        addGestureRecognizer(pan)

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tap.delegate = self
        addGestureRecognizer(tap)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Ensure overlay layers match view bounds
        overlayLayer.frame = bounds
        borderLayer.frame = bounds
        redraw()
    }

    // MARK: ROI Init
    private func initializeROI() {
        let imgFrame = imageFrameInImageView()
        guard imgFrame.width > 0, imgFrame.height > 0 else {
            roiRect = .zero
            return
        }
        // Default to centered ~60% of min dimension
        let size = min(imgFrame.width, imgFrame.height) * 0.6
        roiRect = CGRect(
            x: imgFrame.midX - size/2,
            y: imgFrame.midY - size/2,
            width: size,
            height: size
        ).integral
        clampROI()
    }

    // MARK: Drawing
    private func redraw() {
        let maskPath = UIBezierPath(rect: bounds)
        let roiPath = UIBezierPath(rect: roiRect)
        maskPath.append(roiPath)
        overlayLayer.path = maskPath.cgPath

        borderLayer.path = UIBezierPath(rect: roiRect).cgPath

        let handles = cornerPoints(for: roiRect)
        for (i, p) in handles.enumerated() {
            let hrect = CGRect(x: p.x - handleSize/2, y: p.y - handleSize/2, width: handleSize, height: handleSize)
            let path = UIBezierPath(roundedRect: hrect, cornerRadius: 4)
            handleLayers[i].path = path.cgPath
        }
    }

    private func cornerPoints(for rect: CGRect) -> [CGPoint] {
        return [
            CGPoint(x: rect.minX, y: rect.minY), // TL
            CGPoint(x: rect.maxX, y: rect.minY), // TR
            CGPoint(x: rect.minX, y: rect.maxY), // BL
            CGPoint(x: rect.maxX, y: rect.maxY)  // BR
        ]
    }

    // MARK: Gestures
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        // No-op for now, could add double-tap to center, etc.
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let point = gesture.location(in: self)

        switch gesture.state {
        case .began:
            draggingHandleIndex = hitTestHandle(at: point)
            draggingWholeRect = (draggingHandleIndex == nil) && roiRect.contains(point)
            lastDragPoint = point
        case .changed:
            let delta = CGPoint(x: point.x - lastDragPoint.x, y: point.y - lastDragPoint.y)
            if let idx = draggingHandleIndex {
                resizeRect(handleIndex: idx, delta: delta)
            } else if draggingWholeRect {
                moveRect(delta: delta)
            }
            lastDragPoint = point
            clampROI()
            redraw()
        default:
            draggingHandleIndex = nil
            draggingWholeRect = false
        }
    }

    private func hitTestHandle(at p: CGPoint) -> Int? {
        for (i, h) in handleLayers.enumerated() {
            if let path = h.path, UIBezierPath(cgPath: path).inset(by: UIEdgeInsets(top: -handleHitSlop, left: -handleHitSlop, bottom: -handleHitSlop, right: -handleHitSlop)).contains(p) {
                return i
            }
        }
        // Fall back to simple distance check from corners
        let corners = cornerPoints(for: roiRect)
        for (i, c) in corners.enumerated() {
            if hypot(p.x - c.x, p.y - c.y) <= (handleSize/2 + handleHitSlop) {
                return i
            }
        }
        return nil
    }

    private func resizeRect(handleIndex: Int, delta: CGPoint) {
        var r = roiRect
        switch handleIndex {
        case 0: // TL
            r.origin.x += delta.x
            r.origin.y += delta.y
            r.size.width -= delta.x
            r.size.height -= delta.y
        case 1: // TR
            r.origin.y += delta.y
            r.size.width += delta.x
            r.size.height -= delta.y
        case 2: // BL
            r.origin.x += delta.x
            r.size.width -= delta.x
            r.size.height += delta.y
        case 3: // BR
            r.size.width += delta.x
            r.size.height += delta.y
        default:
            break
        }
        // Enforce minimums
        if r.width < minRectSize { r.size.width = minRectSize }
        if r.height < minRectSize { r.size.height = minRectSize }
        roiRect = r
    }

    private func moveRect(delta: CGPoint) {
        roiRect.origin.x += delta.x
        roiRect.origin.y += delta.y
    }

    private func clampROI() {
        let imgFrame = imageFrameInImageView()
        guard imgFrame.width > 0, imgFrame.height > 0 else { return }

        // Ensure size minimum & within imgFrame
        var r = roiRect.integral

        if r.width < minRectSize { r.size.width = minRectSize }
        if r.height < minRectSize { r.size.height = minRectSize }

        // Keep inside image bounds
        if r.minX < imgFrame.minX { r.origin.x = imgFrame.minX }
        if r.minY < imgFrame.minY { r.origin.y = imgFrame.minY }
        if r.maxX > imgFrame.maxX { r.origin.x = imgFrame.maxX - r.width }
        if r.maxY > imgFrame.maxY { r.origin.y = imgFrame.maxY - r.height }

        roiRect = r.integral
    }

    // MARK: Buttons
    @objc private func resetTapped() {
        initializeROI()
        redraw()
    }

    @objc private func confirmTapped() {
        guard let image = imageView.image else { return }
        let imgFrame = imageFrameInImageView()
        guard imgFrame.width > 0, imgFrame.height > 0 else { return }

        // Convert roiRect (in imageView/display coords) -> normalized image coords
        // First, translate to image-space rect
        let scaleX = image.size.width / imgFrame.width
        let scaleY = image.size.height / imgFrame.height

        let translated = CGRect(
            x: (roiRect.minX - imgFrame.minX) * scaleX,
            y: (roiRect.minY - imgFrame.minY) * scaleY,
            width: roiRect.width * scaleX,
            height: roiRect.height * scaleY
        )

        let norm = NormalizedROI(
            x: max(0, min(1, translated.minX / image.size.width)),
            y: max(0, min(1, translated.minY / image.size.height)),
            w: max(0, min(1, translated.width / image.size.width)),
            h: max(0, min(1, translated.height / image.size.height))
        )

        onConfirm?(norm)
    }

    // MARK: Image Frame Calculation (Aspect Fit)
    private func imageFrameInImageView() -> CGRect {
        guard let image = imageView.image, imageView.bounds.width > 0, imageView.bounds.height > 0 else {
            return .zero
        }
        let viewSize = imageView.bounds.size
        let imgSize = image.size

        let scale = min(viewSize.width / imgSize.width, viewSize.height / imgSize.height)
        let width = imgSize.width * scale
        let height = imgSize.height * scale
        let x = (viewSize.width - width) / 2 + imageView.frame.minX
        let y = (viewSize.height - height) / 2 + imageView.frame.minY

        return CGRect(x: x, y: y, width: width, height: height)
    }
}
