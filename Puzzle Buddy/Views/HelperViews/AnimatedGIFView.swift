//
//  AnimatedGIFView.swift
//  Puzzle Buddy
//

import SwiftUI
import UIKit
import ImageIO

/// Displays a bundled GIF with optional static fallback for Reduce Motion.
struct AnimatedGIFView: UIViewRepresentable {
    let resourceName: String
    var maxPixelSize: Int = 240
    var isAnimating: Bool = true

    func makeUIView(context: Context) -> GIFImageView {
        let imageView = GIFImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.backgroundColor = .clear
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        return imageView
    }

    func updateUIView(_ imageView: GIFImageView, context: Context) {
        imageView.setAnimating(isAnimating)
        imageView.load(resourceName: resourceName, maxPixelSize: maxPixelSize)
    }

    static func dismantleUIView(_ uiView: GIFImageView, coordinator: ()) {
        uiView.setAnimating(false)
    }
}

final class GIFImageView: UIImageView {
    private var resourceName: String?
    private var maxPixelSize: Int = 0
    private var loadToken = UUID()
    private var cachedGIF: GIFFrameCache.CachedGIF?
    private var displayLink: CADisplayLink?
    private var playbackStart: CFTimeInterval = 0
    private var shouldAnimate = true

    func setAnimating(_ animating: Bool) {
        guard shouldAnimate != animating else { return }
        shouldAnimate = animating
        if animating {
            startPlaybackIfReady()
        } else {
            stopPlayback(showFirstFrame: true)
        }
    }

    func load(resourceName: String, maxPixelSize: Int) {
        guard self.resourceName != resourceName || self.maxPixelSize != maxPixelSize else {
            if shouldAnimate {
                startPlaybackIfReady()
            }
            return
        }

        self.resourceName = resourceName
        self.maxPixelSize = maxPixelSize
        let token = UUID()
        loadToken = token
        cachedGIF = nil
        stopPlayback(showFirstFrame: false)
        image = nil

        GIFFrameCache.shared.load(resourceName: resourceName, maxPixelSize: maxPixelSize) { [weak self] gif in
            guard let self, self.loadToken == token else { return }
            self.cachedGIF = gif
            if let first = gif?.frames.first {
                self.image = first
            }
            if self.shouldAnimate {
                self.startPlaybackIfReady()
            }
        }
    }

    private func startPlaybackIfReady() {
        guard shouldAnimate, cachedGIF != nil else { return }
        guard displayLink == nil else { return }
        playbackStart = CACurrentMediaTime()
        let link = CADisplayLink(target: self, selector: #selector(advanceFrame))
        link.preferredFramesPerSecond = GIFFrameCache.playbackFramesPerSecond
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    private func stopPlayback(showFirstFrame: Bool) {
        displayLink?.invalidate()
        displayLink = nil
        if showFirstFrame, let first = cachedGIF?.frames.first {
            image = first
        }
    }

    @objc private func advanceFrame() {
        guard let cachedGIF, !cachedGIF.frames.isEmpty else { return }

        let elapsed = CACurrentMediaTime() - playbackStart
        let looped = elapsed.truncatingRemainder(dividingBy: cachedGIF.totalDuration)
        var accumulated: TimeInterval = 0
        for (index, duration) in cachedGIF.frameDurations.enumerated() {
            accumulated += duration
            if looped < accumulated {
                image = cachedGIF.frames[index]
                return
            }
        }
        image = cachedGIF.frames.last
    }

    deinit {
        displayLink?.invalidate()
    }
}

// MARK: - Shared decode cache

private enum GIFFrameCache {
    static let playbackFramesPerSecond = 12

    struct CachedGIF {
        let frames: [UIImage]
        let frameDurations: [TimeInterval]
        let totalDuration: TimeInterval
    }

    static let shared = Loader()

    final class Loader {
        private var cache: [String: CachedGIF] = [:]
        private var inflight: [String: [(CachedGIF?) -> Void]] = [:]
        private let lock = NSLock()

        func load(resourceName: String, maxPixelSize: Int, completion: @escaping (CachedGIF?) -> Void) {
            let key = "\(resourceName)_\(maxPixelSize)"

            lock.lock()
            if let cached = cache[key] {
                lock.unlock()
                DispatchQueue.main.async { completion(cached) }
                return
            }

            if inflight[key] != nil {
                inflight[key]?.append(completion)
                lock.unlock()
                return
            }

            inflight[key] = [completion]
            lock.unlock()

            DispatchQueue.global(qos: .userInitiated).async {
                let decoded = GIFFrameCache.decodeGIF(resourceName: resourceName, maxPixelSize: maxPixelSize)

                self.lock.lock()
                if let decoded {
                    self.cache[key] = decoded
                }
                let callbacks = self.inflight.removeValue(forKey: key) ?? []
                self.lock.unlock()

                DispatchQueue.main.async {
                    callbacks.forEach { $0(decoded) }
                }
            }
        }
    }

    private static func decodeGIF(resourceName: String, maxPixelSize: Int) -> CachedGIF? {
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "gif"),
              let source = CGImageSourceCreateWithURL(url as CFURL, nil)
        else { return nil }

        let count = CGImageSourceGetCount(source)
        guard count > 0 else { return nil }

        var frames: [UIImage] = []
        var frameDurations: [TimeInterval] = []
        var totalDuration: TimeInterval = 0

        let thumbnailOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: max(maxPixelSize, 1),
        ]

        for index in 0 ..< count {
            guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, index, thumbnailOptions as CFDictionary)
            else { continue }

            frames.append(UIImage(cgImage: cgImage))

            let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any]
            let gifProperties = properties?[kCGImagePropertyGIFDictionary] as? [CFString: Any]
            let frameDuration = (gifProperties?[kCGImagePropertyGIFUnclampedDelayTime] as? TimeInterval)
                ?? (gifProperties?[kCGImagePropertyGIFDelayTime] as? TimeInterval)
                ?? 0.1
            let clamped = max(frameDuration, 0.02)
            frameDurations.append(clamped)
            totalDuration += clamped
        }

        guard !frames.isEmpty else { return nil }
        return CachedGIF(frames: frames, frameDurations: frameDurations, totalDuration: totalDuration)
    }
}
