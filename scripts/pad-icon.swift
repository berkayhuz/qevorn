import AppKit

guard CommandLine.arguments.count == 3 else {
    fputs("Usage: pad-icon.swift <source.png> <output.png>\n", stderr)
    exit(64)
}

let sourceURL = URL(fileURLWithPath: CommandLine.arguments[1])
let outputURL = URL(fileURLWithPath: CommandLine.arguments[2])
let canvasSide: CGFloat = 1_024
let iconSide: CGFloat = 820

guard let source = NSImage(contentsOf: sourceURL) else {
    fputs("Unable to load icon source.\n", stderr)
    exit(65)
}

let image = NSImage(size: NSSize(width: canvasSide, height: canvasSide))
image.lockFocus()
NSGraphicsContext.current?.imageInterpolation = .high
source.draw(
    in: NSRect(
        x: (canvasSide - iconSide) / 2,
        y: (canvasSide - iconSide) / 2,
        width: iconSide,
        height: iconSide
    ),
    from: NSRect(origin: .zero, size: source.size),
    operation: .sourceOver,
    fraction: 1
)
image.unlockFocus()

guard
    let tiff = image.tiffRepresentation,
    let bitmap = NSBitmapImageRep(data: tiff),
    let png = bitmap.representation(using: .png, properties: [:])
else {
    fputs("Unable to encode padded icon.\n", stderr)
    exit(66)
}

try png.write(to: outputURL, options: .atomic)
