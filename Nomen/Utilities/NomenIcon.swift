import AppKit

/// The Nomen menu bar icon: four L-shaped capture brackets framing a center dot.
/// Reads as a viewfinder / shutter mark — direct visual metaphor for "screenshot."
///
/// The image is a template, so macOS auto-tints it for the active menu bar
/// appearance. Strokes are deliberately thick so the mark holds up at small
/// menu bar sizes.
enum NomenIcon {
    static func menuBarIcon(pointSize: CGFloat = 18) -> NSImage {
        let image = NSImage(
            size: NSSize(width: pointSize, height: pointSize),
            flipped: false
        ) { rect in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }

            // Authoring viewBox is 24×24 with y-down to match SVG conventions.
            let scale = rect.width / 24.0
            ctx.translateBy(x: 0, y: rect.height)
            ctx.scaleBy(x: scale, y: -scale)

            ctx.setStrokeColor(NSColor.black.cgColor)
            ctx.setFillColor(NSColor.black.cgColor)
            ctx.setLineCap(.round)
            ctx.setLineJoin(.round)
            ctx.setLineWidth(2.0)

            let brackets = CGMutablePath()
            let cornerRadius: CGFloat = 1.2

            // Each bracket: line into the corner, arc that rounds the corner, then
            // line out. addArc(tangent1End:tangent2End:radius:) replaces the sharp
            // 90° join with a tangent arc of the given radius.

            // Top-left
            brackets.move(to: CGPoint(x: 4, y: 9))
            brackets.addArc(tangent1End: CGPoint(x: 4, y: 4),
                            tangent2End: CGPoint(x: 9, y: 4),
                            radius: cornerRadius)
            brackets.addLine(to: CGPoint(x: 9, y: 4))

            // Top-right
            brackets.move(to: CGPoint(x: 15, y: 4))
            brackets.addArc(tangent1End: CGPoint(x: 20, y: 4),
                            tangent2End: CGPoint(x: 20, y: 9),
                            radius: cornerRadius)
            brackets.addLine(to: CGPoint(x: 20, y: 9))

            // Bottom-left
            brackets.move(to: CGPoint(x: 4, y: 15))
            brackets.addArc(tangent1End: CGPoint(x: 4, y: 20),
                            tangent2End: CGPoint(x: 9, y: 20),
                            radius: cornerRadius)
            brackets.addLine(to: CGPoint(x: 9, y: 20))

            // Bottom-right
            brackets.move(to: CGPoint(x: 15, y: 20))
            brackets.addArc(tangent1End: CGPoint(x: 20, y: 20),
                            tangent2End: CGPoint(x: 20, y: 15),
                            radius: cornerRadius)
            brackets.addLine(to: CGPoint(x: 20, y: 15))

            ctx.addPath(brackets)
            ctx.strokePath()

            // Center dot
            let r: CGFloat = 1.7
            ctx.fillEllipse(in: CGRect(x: 12 - r, y: 12 - r, width: r * 2, height: r * 2))

            return true
        }
        image.isTemplate = true
        return image
    }
}
