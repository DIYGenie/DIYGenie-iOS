//
//  UIImage+Resize.swift
//  DIYGenieApp
//

import UIKit

extension UIImage {
    /// Downscales very large photos to keep memory/GPU usage sane on-device.
    /// Keeps aspect ratio; no-op if the longest edge is already <= maxDimension.
    func dg_resized(maxDimension: CGFloat = 2000) -> UIImage {
        let longest = max(size.width, size.height)
        guard longest > maxDimension else { return self }

        let scale = maxDimension / longest
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in self.draw(in: CGRect(origin: .zero, size: newSize)) }
    }
}
