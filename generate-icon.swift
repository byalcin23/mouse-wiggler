import AppKit

let destination = CommandLine.arguments[1]
try FileManager.default.createDirectory(atPath: destination, withIntermediateDirectories: true)
let variants = [(16, "16x16"), (32, "16x16@2x"), (32, "32x32"), (64, "32x32@2x"),
                (128, "128x128"), (256, "128x128@2x"), (256, "256x256"),
                (512, "256x256@2x"), (512, "512x512"), (1024, "512x512@2x")]
for (size, name) in variants {
    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
                                  bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                  isPlanar: false, colorSpaceName: .deviceRGB,
                                  bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    let context = NSGraphicsContext.current!.cgContext
    context.scaleBy(x: CGFloat(size) / 1024, y: CGFloat(size) / 1024)
    let background = NSBezierPath(roundedRect: NSRect(x: 82, y: 82, width: 860, height: 860), xRadius: 192, yRadius: 192)
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.3)
    shadow.shadowBlurRadius = 24
    shadow.shadowOffset = NSSize(width: 0, height: -12)
    NSGraphicsContext.saveGraphicsState()
    shadow.set()
    NSColor(srgbRed: 0.065, green: 0.09, blue: 0.13, alpha: 1).setFill()
    background.fill()
    NSGraphicsContext.restoreGraphicsState()
    NSGradient(starting: NSColor(srgbRed: 0.14, green: 0.20, blue: 0.26, alpha: 1),
               ending: NSColor(srgbRed: 0.045, green: 0.075, blue: 0.11, alpha: 1))!.draw(in: background, angle: -70)
    let orbit = NSBezierPath()
    orbit.lineWidth = 52
    orbit.lineCapStyle = .round
    orbit.appendArc(withCenter: NSPoint(x: 512, y: 512), radius: 243,
                    startAngle: 55, endAngle: 355, clockwise: false)
    NSColor(srgbRed: 0.34, green: 0.91, blue: 0.76, alpha: 1).setStroke()
    orbit.stroke()
    NSColor(srgbRed: 0.55, green: 0.97, blue: 0.88, alpha: 1).setFill()
    NSBezierPath(ovalIn: NSRect(x: 708, y: 599, width: 68, height: 68)).fill()
    let pointer = NSBezierPath()
    pointer.move(to: NSPoint(x: 411, y: 667))
    pointer.line(to: NSPoint(x: 411, y: 355))
    pointer.line(to: NSPoint(x: 489, y: 425))
    pointer.line(to: NSPoint(x: 547, y: 310))
    pointer.line(to: NSPoint(x: 606, y: 340))
    pointer.line(to: NSPoint(x: 548, y: 453))
    pointer.line(to: NSPoint(x: 657, y: 465))
    pointer.close()
    NSColor.white.setFill()
    pointer.fill()
    NSGraphicsContext.restoreGraphicsState()
    let data = bitmap.representation(using: .png, properties: [:])!
    try data.write(to: URL(fileURLWithPath: destination).appendingPathComponent("icon_\(name).png"))
}
