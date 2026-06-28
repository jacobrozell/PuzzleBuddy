//
//  AnimatedGIFView.swift
//  Puzzle Buddy
//

import SwiftUI
import UIKit

/// Displays a bundled GIF with optional static fallback for Reduce Motion.
struct AnimatedGIFView: UIViewRepresentable {
    let resourceName: String
    var isAnimating: Bool = true

    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.backgroundColor = .clear
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        return imageView
    }

    func updateUIView(_ imageView: UIImageView, context: Context) {
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "gif") else {
            imageView.image = nil
            imageView.animationImages = nil
            return
        }

        if isAnimating {
            if imageView.animationImages == nil {
                imageView.loadGIF(from: url)
            }
            if !imageView.isAnimating {
                imageView.startAnimating()
            }
        } else {
            imageView.stopAnimating()
            if imageView.image == nil {
                imageView.loadGIF(from: url)
            }
            if let frames = imageView.animationImages, let first = frames.first {
                imageView.image = first
            }
        }
    }
}

private extension UIImageView {
    func loadGIF(from url: URL) {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return }

        let count = CGImageSourceGetCount(source)
        guard count > 0 else { return }

        var frames: [UIImage] = []
        var totalDuration: TimeInterval = 0

        for index in 0 ..< count {
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, index, nil) else { continue }
            frames.append(UIImage(cgImage: cgImage))

            let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any]
            let gifProperties = properties?[kCGImagePropertyGIFDictionary] as? [CFString: Any]
            let frameDuration = (gifProperties?[kCGImagePropertyGIFUnclampedDelayTime] as? TimeInterval)
                ?? (gifProperties?[kCGImagePropertyGIFDelayTime] as? TimeInterval)
                ?? 0.1
            totalDuration += max(frameDuration, 0.02)
        }

        guard !frames.isEmpty else { return }

        animationImages = frames
        animationDuration = totalDuration
        animationRepeatCount = 0
        image = frames[0]
    }
}
