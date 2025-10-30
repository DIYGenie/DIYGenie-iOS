//
//  RectangleOverlayView.swift
//  DIYGenieApp
//
//  Created for DIY Genie by ChatGPT
//

import SwiftUI
import UIKit
import QuartzCore

// MARK: - ROI Model
public struct NormalizedROI: Codable, Equatable {
    public let x: CGFloat
    public let y: CGFloat
    public let w: CGFloat
    public let h: CGFloat
}

// MARK: - API Models
struct PreviewRequestBody: Codable {
    let user_id: String
    let roi: NormalizedROI
}

struct PreviewResponse: Codable {
    let preview_url: String?
    let status: String?
    let message: String?
}

// MARK: - API Client
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
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(PreviewResponse.self, from: data)
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
            Color.black.opacity(0.95).ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar

                OverlayCanvasRepresentable(image: image) { roi in
                    Task {
                        await submitROI(roi)
                    }
                }
                .overlay(alignment: .bottom) {
                    bottomTip
                }
            }
        }
        .interactiveDismissDisabled(isSubmitting)
    }

    // MARK: Header
    private var headerBar: some View {
        HStack {
            Button("Cancel") { onCancel() }
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.white.opacity(0.85))
            Spacer()
            Text("Select Area")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            Spacer()
            if isSubmitting {
                ProgressView()
                    .tint(.white)
            } else {
                Color.clear.frame(width: 32, height: 32)
            }
        }
        .padding(.horizontal)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private var bottomTip: some View {
        VStack(spacing: 8) {
            Divider()
                .background(Color.white.opacity(0.3))
            Text("Drag the corners to outline your target area. Tap Confirm when ready.")
                .font(.footnote)
                .foregroundColor(.white.opacity(0.7))
                .padding(.bottom, 8)
        }
        .background(.ultraThinMaterial)
    }

    // MARK: - Submission
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

// MARK: - Representable Wrapper
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
        if uiView.imageView.image !== image {
            uiView.configure(with: image)
        }
    }
}

// MARK: - UIKit Canvas
fileprivate final class OverlayCanvasView: UIView, UIGestureRecognizerDelegate {
    var onConfirm: ((NormalizedROI) -> Void)?

    let imageView = UIImageView()
    private let overlayLayer = CAShapeLayer()
    private let borderLayer = CAShapeLayer()
    private var handleLayers: [CAShapeLayer] = []

    private let confirmButton = UIButton(type: .system)
    private let resetButton = UIButton(type: .system)

    private var roiRect: CGRect = .zero
    private var draggingHandleIndex: Int?
    private var draggingWholeRect = false
    private var lastDragPoint: CGPoint = .zero

    private let minRectSize: CGFloat = 40
    private let handleSize: CGFloat = 18
    private let handleHitSlop: CGFloat = 24

    // MARK: Init
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

    private func setup() {
        backgroundColor = .black

        imageView.contentMode = .scaleAspectFit
        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -64)
        ])

        overlayLayer.fillRule = .evenOdd
        overlayLayer.fillColor = UIColor.black.withAlphaComponent(0.4).cgColor

        borderLayer.strokeColor = UIColor.white.cgColor
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.lineWidth = 2
        layer.addSublayer(overlayLayer)
        layer.addSublayer(borderLayer)

        handleLayers = (0..<4).map { _ in
            let l = CAShapeLayer()
            l.fillColor = UIColor.white.cgColor
            layer.addSublayer(l)
            return l
        }

        let bar = UIView()
        bar.backgroundColor = UIColor.black.withAlphaComponent(0.7)
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
        confirmButton.setTitleColor(.white, for: .normal)
        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)

        resetButton.setTitle("Reset", for: .normal)
        resetButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .regular)
        resetButton.setTitleColor(.white.withAlphaComponent(0.8), for: .normal)
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

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.delegate = self
        addGestureRecognizer(pan)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        overlayLayer.frame = bounds
        borderLayer.frame = bounds
        redraw()
    }

    // MARK: ROI Logic
    private func initializeROI() {
        let frame = imageFrameInImageView()
        guard frame.width > 0 else { return }
        let size = min(frame.width, frame.height) * 0.6
        roiRect = CGRect(x: frame.midX - size/2, y: frame.midY - size/2, width: size, height: size)
    }

    private func redraw() {
        let mask = UIBezierPath(rect: bounds)
        let roi = UIBezierPath(rect: roiRect)
        mask.append(roi)
        overlayLayer.path = mask.cgPath
        borderLayer.path = roi.cgPath

        let corners = cornerPoints(for: roiRect)
        for (i, p) in corners.enumerated() {
            let rect = CGRect(x: p.x - handleSize/2, y: p.y - handleSize/2, width: handleSize, height: handleSize)
            handleLayers[i].path = UIBezierPath(roundedRect: rect, cornerRadius: 4).cgPath
        }
    }

    private func cornerPoints(for rect: CGRect) -> [CGPoint] {
        [
            CGPoint(x: rect.minX, y: rect.minY),
            CGPoint(x: rect.maxX, y: rect.minY),
            CGPoint(x: rect.minX, y: rect.maxY),
            CGPoint(x: rect.maxX, y: rect.maxY)
        ]
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
            if let i = draggingHandleIndex {
                resizeRect(handleIndex: i, delta: delta)
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
            guard let path = h.path else { continue }
            let rect = UIBezierPath(cgPath: path).bounds.insetBy(dx: -handleHitSlop, dy: -handleHitSlop)
            if rect.contains(p) { return i }
        }
        return nil
    }

    private func resizeRect(handleIndex: Int, delta: CGPoint) {
        var r = roiRect
        switch handleIndex {
        case 0: r.origin.x += delta.x; r.origin.y += delta.y; r.size.width -= delta.x; r.size.height -= delta.y
        case 1: r.origin.y += delta.y; r.size.width += delta.x; r.size.height -= delta.y
        case 2: r.origin.x += delta.x; r.size.width -= delta.x; r.size.height += delta.y
        case 3: r.size.width += delta.x; r.size.height += delta.y
        default: break
        }
        r.size.width = max(r.width, minRectSize)
        r.size.height = max(r.height, minRectSize)
        roiRect = r
    }

    private func moveRect(delta: CGPoint) {
        roiRect.origin.x += delta.x
        roiRect.origin.y += delta.y
    }

    private func clampROI() {
        let frame = imageFrameInImageView()
        var r = roiRect
        if r.minX < frame.minX { r.origin.x = frame.minX }
        if r.minY < frame.minY { r.origin.y = frame.minY }
        if r.maxX > frame.maxX { r.origin.x = frame.maxX - r.width }
        if r.maxY > frame.maxY { r.origin.y = frame.maxY - r.height }
        roiRect = r
    }

    @objc private func resetTapped() {
        initializeROI()
        redraw()
    }

    @objc private func confirmTapped() {
        guard let img = imageView.image else { return }
        let frame = imageFrameInImageView()
        guard frame.width > 0 else { return }

        let scaleX = img.size.width / frame.width
        let scaleY = img.size.height / frame.height

        let translated = CGRect(
            x: (roiRect.minX - frame.minX) * scaleX,
            y: (roiRect.minY - frame.minY) * scaleY,
            width: roiRect.width * scaleX,
            height: roiRect.height * scaleY
        )

        let norm = NormalizedROI(
            x: translated.minX / img.size.width,
            y: translated.minY / img.size.height,
            w: translated.width / img.size.width,
            h: translated.height / img.size.height
        )
        onConfirm?(norm)
    }

    private func imageFrameInImageView() -> CGRect {
        guard let img = imageView.image, imageView.bounds.width > 0 else { return .zero }
        let viewSize = imageView.bounds.size
        let imgSize = img.size
        let scale = min(viewSize.width / imgSize.width, viewSize.height / imgSize.height)
        let width = imgSize.width * scale
        let height = imgSize.height * scale
        let x = (viewSize.width - width) / 2 + imageView.frame.minX
        let y = (viewSize.height - height) / 2 + imageView.frame.minY
        return CGRect(x: x, y: y, width: width, height: height)
    }
}
