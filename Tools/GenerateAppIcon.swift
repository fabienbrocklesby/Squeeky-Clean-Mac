import AppKit
import Foundation

struct IconSlot {
    let size: Int
    let scale: Int

    var pixels: Int { size * scale }
    var filename: String { "AppIcon-\(size)x\(size)@\(scale)x.png" }
}

let slots = [
    IconSlot(size: 16, scale: 1),
    IconSlot(size: 16, scale: 2),
    IconSlot(size: 32, scale: 1),
    IconSlot(size: 32, scale: 2),
    IconSlot(size: 128, scale: 1),
    IconSlot(size: 128, scale: 2),
    IconSlot(size: 256, scale: 1),
    IconSlot(size: 256, scale: 2),
    IconSlot(size: 512, scale: 1),
    IconSlot(size: 512, scale: 2)
]

let outputURL = URL(fileURLWithPath: "SqueekyCleanMac/Assets.xcassets/AppIcon.appiconset", isDirectory: true)
try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)

func drawIcon(size: Int) throws -> Data {
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        throw CocoaError(.fileWriteUnknown)
    }

    let scale = CGFloat(size)
    bitmap.size = NSSize(width: size, height: size)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)

    let bounds = CGRect(x: 0, y: 0, width: scale, height: scale)
    NSColor.clear.setFill()
    bounds.fill()

    let outerInset = scale * 0.055
    let tileRect = bounds.insetBy(dx: outerInset, dy: outerInset)
    let tile = NSBezierPath(
        roundedRect: tileRect,
        xRadius: scale * 0.22,
        yRadius: scale * 0.22
    )
    tile.addClip()

    NSGradient(colors: [
        NSColor(red: 0.043, green: 0.090, blue: 0.125, alpha: 1),
        NSColor(red: 0.055, green: 0.245, blue: 0.235, alpha: 1),
        NSColor(red: 0.710, green: 0.945, blue: 0.875, alpha: 1)
    ])?.draw(in: tileRect, angle: 42)

    NSColor.white.withAlphaComponent(0.18).setFill()
    NSBezierPath(ovalIn: CGRect(x: scale * 0.16, y: scale * 0.42, width: scale * 0.68, height: scale * 0.66)).fill()

    NSColor.black.withAlphaComponent(0.20).setFill()
    NSBezierPath(ovalIn: CGRect(x: scale * 0.20, y: scale * 0.12, width: scale * 0.60, height: scale * 0.12)).fill()

    let keyboardRect = CGRect(x: scale * 0.205, y: scale * 0.305, width: scale * 0.59, height: scale * 0.35)
    let keyboard = NSBezierPath(
        roundedRect: keyboardRect,
        xRadius: scale * 0.075,
        yRadius: scale * 0.075
    )

    NSColor.white.withAlphaComponent(0.84).setFill()
    keyboard.fill()

    NSColor.white.withAlphaComponent(0.44).setStroke()
    keyboard.lineWidth = max(1, scale * 0.012)
    keyboard.stroke()

    let keyColor = NSColor(red: 0.09, green: 0.22, blue: 0.22, alpha: 0.54)
    keyColor.setFill()

    let keyRows = [
        (y: CGFloat(0.535), count: 8, x: CGFloat(0.270), width: CGFloat(0.045)),
        (y: CGFloat(0.445), count: 7, x: CGFloat(0.300), width: CGFloat(0.047)),
        (y: CGFloat(0.355), count: 5, x: CGFloat(0.355), width: CGFloat(0.050))
    ]

    for row in keyRows {
        for index in 0..<row.count {
            let keyRect = CGRect(
                x: scale * (row.x + CGFloat(index) * 0.058),
                y: scale * row.y,
                width: scale * row.width,
                height: scale * 0.034
            )
            NSBezierPath(roundedRect: keyRect, xRadius: scale * 0.010, yRadius: scale * 0.010).fill()
        }
    }

    NSColor(red: 0.07, green: 0.19, blue: 0.19, alpha: 0.45).setFill()
    NSBezierPath(roundedRect: CGRect(x: scale * 0.390, y: scale * 0.355, width: scale * 0.220, height: scale * 0.034), xRadius: scale * 0.010, yRadius: scale * 0.010).fill()

    drawSparkle(center: CGPoint(x: scale * 0.705, y: scale * 0.720), radius: scale * 0.095)
    drawSparkle(center: CGPoint(x: scale * 0.292, y: scale * 0.728), radius: scale * 0.042, alpha: 0.56)

    NSGraphicsContext.restoreGraphicsState()

    guard let data = bitmap.representation(using: .png, properties: [:]) else {
        throw CocoaError(.fileWriteUnknown)
    }

    return data
}

func drawSparkle(center: CGPoint, radius: CGFloat, alpha: CGFloat = 0.88) {
    let path = NSBezierPath()
    let points = 8

    for index in 0..<points {
        let angle = CGFloat(index) * .pi * 2 / CGFloat(points) + .pi / 2
        let currentRadius = index.isMultiple(of: 2) ? radius : radius * 0.30
        let point = CGPoint(
            x: center.x + cos(angle) * currentRadius,
            y: center.y + sin(angle) * currentRadius
        )

        index == 0 ? path.move(to: point) : path.line(to: point)
    }

    path.close()
    NSColor.white.withAlphaComponent(alpha).setFill()
    path.fill()
}

for slot in slots {
    let data = try drawIcon(size: slot.pixels)
    try data.write(to: outputURL.appendingPathComponent(slot.filename), options: .atomic)
}

let images = slots.map { slot -> [String: String] in
    [
        "filename": slot.filename,
        "idiom": "mac",
        "scale": "\(slot.scale)x",
        "size": "\(slot.size)x\(slot.size)"
    ]
}

let contents: [String: Any] = [
    "images": images,
    "info": [
        "author": "xcode",
        "version": 1
    ]
]

let jsonData = try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
try jsonData.write(to: outputURL.appendingPathComponent("Contents.json"), options: .atomic)
