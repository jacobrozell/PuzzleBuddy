//
//  PuzzleCollectionCollageRenderer.swift
//  Puzzle Buddy
//

import UIKit

enum PuzzleCollectionCollageRenderer {
    static let canvasSize = CGSize(width: 1_080, height: 1_350)

    static func render(puzzles: [Puzzle], stats: CollectionStats) -> UIImage {
        let sorted = puzzles.sorted { lhs, rhs in
            if lhs.image != nil && rhs.image == nil { return true }
            if lhs.image == nil && rhs.image != nil { return false }
            return lhs.completionDate > rhs.completionDate
        }

        let layout = PuzzleCollectionCollageLayout.gridDimensions(for: sorted.count)
        let tiles = Array(sorted.prefix(layout.displayed))

        let renderer = UIGraphicsImageRenderer(size: canvasSize)
        return renderer.image { context in
            let cgContext = context.cgContext
            drawBackground(in: cgContext)

            let headerRect = CGRect(x: 48, y: 48, width: canvasSize.width - 96, height: 150)
            drawHeader(stats: stats, in: headerRect, context: cgContext)

            let gridTop: CGFloat = 230
            let gridRect = CGRect(
                x: 48,
                y: gridTop,
                width: canvasSize.width - 96,
                height: canvasSize.height - gridTop - 120
            )
            drawGrid(tiles: tiles, layout: layout, in: gridRect, context: cgContext)

            if sorted.count > layout.displayed {
                drawOverflowBadge(
                    count: sorted.count - layout.displayed,
                    in: CGRect(x: 48, y: canvasSize.height - 88, width: canvasSize.width - 96, height: 40)
                )
            } else {
                drawFooter(in: CGRect(x: 48, y: canvasSize.height - 88, width: canvasSize.width - 96, height: 40))
            }
        }
    }

    private static func drawBackground(in context: CGContext) {
        context.setFillColor(UIColor(red: 0.95, green: 0.97, blue: 0.98, alpha: 1).cgColor)
        context.fill(CGRect(origin: .zero, size: canvasSize))

        let gradientColors = [
            UIColor(red: 0.10, green: 0.45, blue: 0.85, alpha: 0.18).cgColor,
            UIColor(red: 0.08, green: 0.58, blue: 0.55, alpha: 0.12).cgColor
        ] as CFArray
        if let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: gradientColors,
            locations: [0, 1]
        ) {
            context.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: canvasSize.width, y: canvasSize.height * 0.35),
                options: []
            )
        }
    }

    private static func drawHeader(stats: CollectionStats, in rect: CGRect, context: CGContext) {
        let title = AppInfo.displayName as NSString
        let subtitle = PuzzleShareSummary.statsLine(for: stats) as NSString

        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 42, weight: .bold),
            .foregroundColor: UIColor(red: 0.08, green: 0.09, blue: 0.11, alpha: 1)
        ]
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24, weight: .medium),
            .foregroundColor: UIColor(red: 0.35, green: 0.38, blue: 0.42, alpha: 1)
        ]

        title.draw(at: CGPoint(x: rect.minX, y: rect.minY), withAttributes: titleAttributes)
        subtitle.draw(at: CGPoint(x: rect.minX, y: rect.minY + 56), withAttributes: subtitleAttributes)
    }

    private static func drawGrid(
        tiles: [Puzzle],
        layout: (columns: Int, rows: Int, displayed: Int),
        in rect: CGRect,
        context: CGContext
    ) {
        let spacing: CGFloat = 12
        let columns = CGFloat(layout.columns)
        let rows = CGFloat(layout.rows)
        let cellWidth = (rect.width - spacing * (columns - 1)) / columns
        let cellHeight = (rect.height - spacing * (rows - 1)) / rows

        for index in 0..<layout.displayed {
            let column = index % layout.columns
            let row = index / layout.columns
            let cellRect = CGRect(
                x: rect.minX + CGFloat(column) * (cellWidth + spacing),
                y: rect.minY + CGFloat(row) * (cellHeight + spacing),
                width: cellWidth,
                height: cellHeight
            )

            if index < tiles.count {
                drawTile(puzzle: tiles[index], in: cellRect, context: context)
            } else {
                drawPlaceholder(in: cellRect, context: context)
            }
        }
    }

    private static func drawTile(puzzle: Puzzle, in rect: CGRect, context: CGContext) {
        let path = UIBezierPath(roundedRect: rect, cornerRadius: 16)
        context.saveGState()
        path.addClip()

        if let image = puzzle.image {
            image.draw(in: coverRect(for: image.size, inside: rect))
        } else {
            drawPlaceholderBackground(in: rect, context: context)
            drawPlaceholderIcon(in: rect)
        }

        context.restoreGState()

        context.setStrokeColor(UIColor.white.withAlphaComponent(0.85).cgColor)
        context.setLineWidth(2)
        context.addPath(path.cgPath)
        context.strokePath()

        drawTileLabel(puzzle.name, in: rect)
    }

    private static func drawPlaceholder(in rect: CGRect, context: CGContext) {
        let path = UIBezierPath(roundedRect: rect, cornerRadius: 16)
        context.saveGState()
        path.addClip()
        drawPlaceholderBackground(in: rect, context: context)
        drawPlaceholderIcon(in: rect)
        context.restoreGState()
    }

    private static func drawPlaceholderBackground(in rect: CGRect, context: CGContext) {
        context.setFillColor(UIColor(red: 0.957, green: 0.937, blue: 0.902, alpha: 1).cgColor)
        context.fill(rect)
    }

    private static func drawPlaceholderIcon(in rect: CGRect) {
        let config = UIImage.SymbolConfiguration(pointSize: min(rect.width, rect.height) * 0.28, weight: .semibold)
        guard let symbol = UIImage(systemName: "puzzlepiece.extension.fill", withConfiguration: config)?
            .withTintColor(UIColor(red: 0.757, green: 0.361, blue: 0.220, alpha: 1), renderingMode: .alwaysOriginal)
        else { return }

        let symbolSize = symbol.size
        let origin = CGPoint(
            x: rect.midX - symbolSize.width / 2,
            y: rect.midY - symbolSize.height / 2 - 12
        )
        symbol.draw(at: origin)
    }

    private static func drawTileLabel(_ name: String, in rect: CGRect) {
        let labelRect = CGRect(x: rect.minX + 8, y: rect.maxY - 42, width: rect.width - 16, height: 34)
        let background = UIBezierPath(roundedRect: labelRect, cornerRadius: 8)
        UIColor.black.withAlphaComponent(0.45).setFill()
        background.fill()

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineBreakMode = .byTruncatingTail

        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .semibold),
            .foregroundColor: UIColor.white,
            .paragraphStyle: paragraph
        ]
        (name as NSString).draw(in: labelRect.insetBy(dx: 6, dy: 6), withAttributes: attributes)
    }

    private static func drawOverflowBadge(count: Int, in rect: CGRect) {
        let text = "+\(count) more puzzles" as NSString
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 22, weight: .semibold),
            .foregroundColor: UIColor(red: 0.757, green: 0.361, blue: 0.220, alpha: 1)
        ]
        let size = text.size(withAttributes: attributes)
        text.draw(
            at: CGPoint(x: rect.midX - size.width / 2, y: rect.midY - size.height / 2),
            withAttributes: attributes
        )
    }

    private static func drawFooter(in rect: CGRect) {
        let text = "puzzlebuddy.app" as NSString
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 20, weight: .medium),
            .foregroundColor: UIColor(red: 0.35, green: 0.38, blue: 0.42, alpha: 1)
        ]
        let size = text.size(withAttributes: attributes)
        text.draw(
            at: CGPoint(x: rect.midX - size.width / 2, y: rect.midY - size.height / 2),
            withAttributes: attributes
        )
    }

    private static func coverRect(for imageSize: CGSize, inside bounds: CGRect) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0 else { return bounds }
        let scale = max(bounds.width / imageSize.width, bounds.height / imageSize.height)
        let size = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        return CGRect(
            x: bounds.midX - size.width / 2,
            y: bounds.midY - size.height / 2,
            width: size.width,
            height: size.height
        )
    }
}
