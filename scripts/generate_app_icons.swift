#!/usr/bin/env swift
//
// Generates the macOS AppIcon image set for Nomen.
// Composition: capture brackets + dot up top, "nomen" wordmark + spruce green
// underline below, paper background, squircle clipped.

import AppKit
import Foundation

let paper = NSColor(srgbRed: 0.98, green: 0.97, blue: 0.94, alpha: 1.0)
let ink = NSColor(srgbRed: 0.10, green: 0.10, blue: 0.12, alpha: 1.0)
let spruce = NSColor(srgbRed: 0.20, green: 0.40, blue: 0.30, alpha: 1.0)

func renderImage(size: CGFloat) -> NSImage {
    NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
        guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
        let s = size

        // Squircle clip (200-unit reference, y-down → flipped to Cocoa y-up).
        ctx.saveGState()
        let scale = s / 200.0
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: x * scale, y: (200 - y) * scale)
        }
        let clip = CGMutablePath()
        clip.move(to: p(100, 0))
        clip.addCurve(to: p(0, 100), control1: p(24, 0), control2: p(0, 24))
        clip.addCurve(to: p(100, 200), control1: p(0, 176), control2: p(24, 200))
        clip.addCurve(to: p(200, 100), control1: p(176, 200), control2: p(200, 176))
        clip.addCurve(to: p(100, 0), control1: p(200, 24), control2: p(176, 0))
        clip.closeSubpath()
        ctx.addPath(clip)
        ctx.clip()

        paper.setFill()
        rect.fill()

        // Capture brackets.
        drawBrackets(
            in: ctx,
            center: CGPoint(x: s * 0.5, y: s * 0.62),
            frameSize: s * 0.36,
            lineWidth: s * 0.022
        )

        // Wordmark.
        let wordmarkFontSize = s * 0.16
        let mono = NSFont.monospacedSystemFont(ofSize: wordmarkFontSize, weight: .medium)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: mono,
            .foregroundColor: ink,
            .kern: -wordmarkFontSize * 0.04
        ]
        let wordmark = NSAttributedString(string: "nomen", attributes: attrs)
        let textSize = wordmark.size()
        let textOrigin = CGPoint(x: (s - textSize.width) / 2, y: s * 0.22)
        wordmark.draw(at: textOrigin)

        // Spruce green underline.
        let underlineHeight = max(2, s * 0.014)
        let underlineY = textOrigin.y - underlineHeight - s * 0.01
        let underlineRect = CGRect(
            x: textOrigin.x,
            y: underlineY,
            width: textSize.width,
            height: underlineHeight
        )
        spruce.setFill()
        NSBezierPath(
            roundedRect: underlineRect,
            xRadius: underlineHeight / 2,
            yRadius: underlineHeight / 2
        ).fill()

        ctx.restoreGState()
        return true
    }
}

func drawBrackets(in ctx: CGContext, center: CGPoint, frameSize: CGFloat, lineWidth: CGFloat) {
    ctx.saveGState()
    let viewBox: CGFloat = 24
    let pixelsPerUnit = frameSize / viewBox
    ctx.translateBy(x: center.x, y: center.y)
    ctx.scaleBy(x: pixelsPerUnit, y: -pixelsPerUnit)
    ctx.translateBy(x: -viewBox / 2, y: -viewBox / 2)

    ctx.setStrokeColor(ink.cgColor)
    ctx.setFillColor(ink.cgColor)
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)
    ctx.setLineWidth(lineWidth / pixelsPerUnit)

    let r: CGFloat = 1.2
    let path = CGMutablePath()

    path.move(to: CGPoint(x: 4, y: 9))
    path.addArc(tangent1End: CGPoint(x: 4, y: 4), tangent2End: CGPoint(x: 9, y: 4), radius: r)
    path.addLine(to: CGPoint(x: 9, y: 4))
    path.move(to: CGPoint(x: 15, y: 4))
    path.addArc(tangent1End: CGPoint(x: 20, y: 4), tangent2End: CGPoint(x: 20, y: 9), radius: r)
    path.addLine(to: CGPoint(x: 20, y: 9))
    path.move(to: CGPoint(x: 4, y: 15))
    path.addArc(tangent1End: CGPoint(x: 4, y: 20), tangent2End: CGPoint(x: 9, y: 20), radius: r)
    path.addLine(to: CGPoint(x: 9, y: 20))
    path.move(to: CGPoint(x: 15, y: 20))
    path.addArc(tangent1End: CGPoint(x: 20, y: 20), tangent2End: CGPoint(x: 20, y: 15), radius: r)
    path.addLine(to: CGPoint(x: 20, y: 15))

    ctx.addPath(path)
    ctx.strokePath()

    let dotR: CGFloat = 1.7
    ctx.fillEllipse(in: CGRect(x: 12 - dotR, y: 12 - dotR, width: dotR * 2, height: dotR * 2))

    ctx.restoreGState()
}

// Render to PNG at exact pixel size.
func writePNG(_ image: NSImage, pixels: Int, to url: URL) throws {
    let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil)!
    // Force exact pixel size by re-rasterizing into a fixed-size bitmap.
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixels,
        pixelsHigh: pixels,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    rep.size = NSSize(width: pixels, height: pixels)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    NSGraphicsContext.current?.cgContext.draw(cg, in: CGRect(x: 0, y: 0, width: pixels, height: pixels))
    NSGraphicsContext.restoreGraphicsState()
    let data = rep.representation(using: .png, properties: [:])!
    try data.write(to: url)
}

// MARK: - Asset Catalog set

struct IconSpec { let filename: String; let size: Int; let pointSize: Int; let scale: Int }

let specs: [IconSpec] = [
    .init(filename: "icon_16x16.png",      size: 16,   pointSize: 16,   scale: 1),
    .init(filename: "icon_16x16@2x.png",   size: 32,   pointSize: 16,   scale: 2),
    .init(filename: "icon_32x32.png",      size: 32,   pointSize: 32,   scale: 1),
    .init(filename: "icon_32x32@2x.png",   size: 64,   pointSize: 32,   scale: 2),
    .init(filename: "icon_128x128.png",    size: 128,  pointSize: 128,  scale: 1),
    .init(filename: "icon_128x128@2x.png", size: 256,  pointSize: 128,  scale: 2),
    .init(filename: "icon_256x256.png",    size: 256,  pointSize: 256,  scale: 1),
    .init(filename: "icon_256x256@2x.png", size: 512,  pointSize: 256,  scale: 2),
    .init(filename: "icon_512x512.png",    size: 512,  pointSize: 512,  scale: 1),
    .init(filename: "icon_512x512@2x.png", size: 1024, pointSize: 512,  scale: 2)
]

let outDir = URL(fileURLWithPath: "Nomen/Resources/Assets.xcassets/AppIcon.appiconset", isDirectory: true)
try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

for spec in specs {
    let img = renderImage(size: CGFloat(spec.size))
    let url = outDir.appendingPathComponent(spec.filename)
    try writePNG(img, pixels: spec.size, to: url)
    print("wrote \(spec.filename) (\(spec.size)px)")
}

struct ContentsImage: Codable { let filename: String; let idiom: String; let scale: String; let size: String }
struct ContentsInfo: Codable { let author: String; let version: Int }
struct Contents: Codable { let images: [ContentsImage]; let info: ContentsInfo }
struct RootContents: Codable { let info: ContentsInfo }

let images = specs.map {
    ContentsImage(
        filename: $0.filename,
        idiom: "mac",
        scale: "\($0.scale)x",
        size: "\($0.pointSize)x\($0.pointSize)"
    )
}
let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

try encoder.encode(Contents(images: images, info: ContentsInfo(author: "xcode", version: 1)))
    .write(to: outDir.appendingPathComponent("Contents.json"))

let xcAssets = URL(fileURLWithPath: "Nomen/Resources/Assets.xcassets", isDirectory: true)
try encoder.encode(RootContents(info: ContentsInfo(author: "xcode", version: 1)))
    .write(to: xcAssets.appendingPathComponent("Contents.json"))

print("AppIcon set written to \(outDir.path)")
