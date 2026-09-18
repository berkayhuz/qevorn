import AppKit
import CoreImage
import CoreText
import ImageIO
import PDFKit
import UniformTypeIdentifiers

/// The rasterized QR image and the quality information used by the studio UI.
struct QRRenderReport {
  let cgImage: CGImage
  let moduleCount: Int
  let darkModuleCount: Int
  let density: Double
  let warnings: [String]
  let estimatedMemoryMB: Double
}

/// Native QR generation, styling, decoding and export for macOS.
enum QRRenderingEngine {
  private static let maxRasterSide = 12_000
  private static let maxRasterPixels = 96_000_000
  private static let defaultPreviewSize = 768

  static func render(state: StudioState, size: Int = 768) throws -> QRRenderReport {
    let matrix = try makeMatrix(payload: state.payload, correction: state.errorCorrection)
    let dimensions = canvasDimensions(for: state.frameTemplate, requestedSide: size)
    let image = try paint(state: state, matrix: matrix, width: dimensions.width, height: dimensions.height)
    let darkCount = matrix.modules.reduce(into: 0) { count, row in
      count += row.reduce(into: 0) { rowCount, dark in
        if dark { rowCount += 1 }
      }
    }
    let warnings = warnings(for: state, matrix: matrix, requestedSize: size, dimensions: dimensions)
    let memory = Double(dimensions.width) * Double(dimensions.height) * 4.0 / 1_048_576.0
    return QRRenderReport(
      cgImage: image,
      moduleCount: matrix.count * matrix.count,
      darkModuleCount: darkCount,
      density: matrix.count > 0 ? Double(darkCount) / Double(matrix.count * matrix.count) : 0,
      warnings: warnings,
      estimatedMemoryMB: memory
    )
  }

  static func export(state: StudioState, format: ExportFormat, size: Int) throws -> Data {
    let matrix = try makeMatrix(payload: state.payload, correction: state.errorCorrection)
    if format == .svg {
      return Data(makeSVG(state: state, matrix: matrix, requestedSide: size).utf8)
    }

    let dimensions: (width: Int, height: Int)
    if format == .pdf {
      dimensions = canvasDimensions(for: state.frameTemplate, requestedSide: min(max(32, size), 4_096))
    } else {
      dimensions = try rasterExportDimensions(for: state.frameTemplate, requestedSide: size)
    }
    let image = try paint(state: state, matrix: matrix, width: dimensions.width, height: dimensions.height)
    switch format {
    case .png:
      return try encode(image, type: UTType.png.identifier)
    case .jpg:
      let opaque = composite(image, background: parsedColor(state.background) ?? .white)
      return try encode(opaque, type: UTType.jpeg.identifier, quality: 0.94)
    case .webp:
      return try encode(image, type: "org.webmproject.webp", quality: 0.94)
    case .pdf:
      return try makePDF(image)
    case .svg:
      // Handled above to keep SVG exports vector based.
      return Data()
    }
  }

  static func decodeTest(state: StudioState) throws -> Bool {
    let report = try render(state: state, size: defaultPreviewSize)
    let ciImage = CIImage(cgImage: report.cgImage)
    let context = CIContext(options: [.useSoftwareRenderer: false])
    guard let detector = CIDetector(
      ofType: CIDetectorTypeQRCode,
      context: context,
      options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]
    ) else {
      throw QRRenderingError.decoderUnavailable
    }
    let decoded = detector.features(in: ciImage).compactMap { ($0 as? CIQRCodeFeature)?.messageString }
    return decoded.contains(state.payload)
  }

  private static func makeMatrix(payload: String, correction: ErrorCorrection) throws -> QRMatrix {
    guard !payload.isEmpty else { throw QRRenderingError.emptyPayload }
    guard let filter = CIFilter(name: "CIQRCodeGenerator") else { throw QRRenderingError.couldNotEncode }
    filter.setValue(Data(payload.utf8), forKey: "inputMessage")
    switch correction {
    case .low: filter.setValue("L", forKey: "inputCorrectionLevel")
    case .medium: filter.setValue("M", forKey: "inputCorrectionLevel")
    case .quartile: filter.setValue("Q", forKey: "inputCorrectionLevel")
    case .high: filter.setValue("H", forKey: "inputCorrectionLevel")
    }
    guard let output = filter.outputImage else { throw QRRenderingError.couldNotEncode }
    let extent = output.extent.integral
    let ciContext = CIContext(options: [.useSoftwareRenderer: false])
    guard let cgImage = ciContext.createCGImage(output, from: extent, format: .RGBA8, colorSpace: CGColorSpaceCreateDeviceRGB()) else {
      throw QRRenderingError.couldNotEncode
    }
    let count = cgImage.width
    guard count > 0, cgImage.height == count else { throw QRRenderingError.invalidMatrix }
    var pixels = [UInt8](repeating: 0, count: count * count * 4)
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGBitmapInfo.byteOrder32Big.union(CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue))
    let didDraw = pixels.withUnsafeMutableBytes { bytes -> Bool in
      guard let baseAddress = bytes.baseAddress,
            let bitmap = CGContext(
              data: baseAddress,
              width: count,
              height: count,
              bitsPerComponent: 8,
              bytesPerRow: count * 4,
              space: colorSpace,
              bitmapInfo: bitmapInfo.rawValue
            ) else { return false }
      bitmap.interpolationQuality = .none
      bitmap.setBlendMode(.copy)
      bitmap.draw(cgImage, in: CGRect(x: 0, y: 0, width: count, height: count))
      return true
    }
    guard didDraw else { throw QRRenderingError.invalidMatrix }

    var modules = Array(repeating: Array(repeating: false, count: count), count: count)
    for y in 0..<count {
      for x in 0..<count {
        let offset = (y * count + x) * 4
        let alpha = Int(pixels[offset + 3])
        let red = Int(pixels[offset]) * 299
        let green = Int(pixels[offset + 1]) * 587
        let blue = Int(pixels[offset + 2]) * 114
        let luminance = (red + green + blue) / 1000
        modules[y][x] = alpha > 8 && luminance < 128
      }
    }
    return QRMatrix(modules: modules)
  }

  private static func paint(state: StudioState, matrix: QRMatrix, width: Int, height: Int) throws -> CGImage {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGBitmapInfo.byteOrder32Big.union(CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue))
    guard let context = CGContext(
      data: nil,
      width: width,
      height: height,
      bitsPerComponent: 8,
      bytesPerRow: width * 4,
      space: colorSpace,
      bitmapInfo: bitmapInfo.rawValue
    ) else { throw QRRenderingError.couldNotAllocateCanvas }

    context.setAllowsAntialiasing(true)
    context.setShouldAntialias(true)
    context.interpolationQuality = .high
    // Use a top-left coordinate system so QR row zero remains the visible top row.
    context.translateBy(x: 0, y: CGFloat(height))
    context.scaleBy(x: 1, y: -1)

    let canvas = CGSize(width: width, height: height)
    let background = parsedColor(state.background) ?? .white
    if !state.transparentBackground {
      context.setFillColor(background)
      context.fill(CGRect(origin: .zero, size: canvas))
    }

    let layout = qrLayout(state: state, matrix: matrix, width: CGFloat(width), height: CGFloat(height))
    if let frameIndex = frameIndex(state.frameTemplate) {
      drawFrame(context, state: state, index: frameIndex, size: canvas)
      let slot = CGRect(x: layout.qrX, y: layout.qrY, width: layout.qrSize, height: layout.qrSize)
      context.saveGState()
      if state.transparentBackground {
        context.setBlendMode(.clear)
        context.fill(slot)
      } else {
        context.setBlendMode(.copy)
        context.setFillColor(background)
        context.fill(slot)
      }
      context.restoreGState()
    }
    drawMatrix(context, state: state, matrix: matrix, layout: layout)
    if let logo = state.logo {
      try drawLogo(context, logo: logo, layout: layout)
    }
    guard let image = context.makeImage() else { throw QRRenderingError.couldNotAllocateCanvas }
    return image
  }

  private static func drawMatrix(_ context: CGContext, state: StudioState, matrix: QRMatrix, layout: QRLayout) {
    let count = CGFloat(matrix.count)
    let margin = CGFloat(min(16, max(0, state.margin)))
    let unit = layout.qrSize / max(1, count + margin * 2)
    let foreground = parsedColor(state.foreground) ?? .black
    let finderForeground = parsedColor(state.finderForeground) ?? foreground
    for y in 0..<matrix.count {
      for x in 0..<matrix.count where matrix.modules[y][x] {
        let finder = isFinder(x: x, y: y, count: matrix.count)
        let color = state.separateFinders && finder ? finderForeground : foreground
        let rect = CGRect(
          x: layout.qrX + (margin + CGFloat(x)) * unit,
          y: layout.qrY + (margin + CGFloat(y)) * unit,
          width: unit,
          height: unit
        )
        let shape = finder ? moduleShape(for: state.finderShape) : state.moduleShape
        drawModule(context, rect: rect, color: color, shape: shape)
      }
    }
  }

  private static func drawModule(_ context: CGContext, rect: CGRect, color: CGColor, shape: ModuleShape) {
    context.setFillColor(color)
    switch shape {
    case .rounded:
      context.fill(CGPath(roundedRect: rect.insetBy(dx: rect.width * 0.025, dy: rect.height * 0.025), cornerWidth: rect.width * 0.28, cornerHeight: rect.height * 0.28, transform: nil))
    case .dot:
      let dot = rect.insetBy(dx: rect.width * 0.05, dy: rect.height * 0.05)
      context.fillEllipse(in: dot)
    case .diamond:
      let cx = rect.midX, cy = rect.midY
      let path = CGMutablePath()
      path.move(to: CGPoint(x: cx, y: rect.minY))
      path.addLine(to: CGPoint(x: rect.maxX, y: cy))
      path.addLine(to: CGPoint(x: cx, y: rect.maxY))
      path.addLine(to: CGPoint(x: rect.minX, y: cy))
      path.closeSubpath()
      context.addPath(path)
      context.fillPath()
    case .square:
      context.fill(rect)
    }
  }

  private static func drawLogo(_ context: CGContext, logo: LogoState, layout: QRLayout) throws {
    guard logo.data.count <= 5 * 1_024 * 1_024 else { throw QRRenderingError.logoTooLarge }
    guard let source = CGImageSourceCreateWithData(logo.data as CFData, nil),
          let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
          let sourceWidth = properties[kCGImagePropertyPixelWidth] as? Int,
          let sourceHeight = properties[kCGImagePropertyPixelHeight] as? Int else { throw QRRenderingError.invalidLogo }
    guard sourceWidth > 0, sourceHeight > 0, sourceWidth <= 16_000_000 / sourceHeight,
          let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else { throw QRRenderingError.logoTooLarge }

    let logoSize = layout.qrSize * min(0.34, max(0.08, CGFloat(logo.scale)))
    let padding = max(0, CGFloat(logo.padding)) * (layout.qrSize / CGFloat(defaultPreviewSize)).clamped(to: 0.05...1.0)
    let cardSize = logoSize + padding * 2
    let cardRect = CGRect(x: layout.qrX + (layout.qrSize - cardSize) / 2, y: layout.qrY + (layout.qrSize - cardSize) / 2, width: cardSize, height: cardSize)
    let card = parsedColor(logo.cardColor) ?? .white
    context.saveGState()
    context.setFillColor(card)
    if logo.circleCard {
      context.fillEllipse(in: cardRect)
    } else {
      context.fill(CGPath(roundedRect: cardRect, cornerWidth: min(cardRect.width / 2, CGFloat(logo.radius)), cornerHeight: min(cardRect.height / 2, CGFloat(logo.radius)), transform: nil))
    }
    let fit = aspectFit(source: CGSize(width: image.width, height: image.height), inside: CGRect(x: cardRect.minX + padding, y: cardRect.minY + padding, width: logoSize, height: logoSize))
    if logo.circleCard {
      context.addEllipse(in: cardRect)
    } else {
      context.addPath(CGPath(roundedRect: cardRect, cornerWidth: min(cardRect.width / 2, CGFloat(logo.radius)), cornerHeight: min(cardRect.height / 2, CGFloat(logo.radius)), transform: nil))
    }
    context.clip()
    context.interpolationQuality = .high
    context.draw(image, in: fit)
    context.restoreGState()
  }

  private static func drawFrame(_ context: CGContext, state: StudioState, index: Int, size: CGSize) {
    if let frame = suppliedFrameImage(for: index) {
      context.saveGState()
      context.interpolationQuality = .high
      context.draw(frame, in: CGRect(origin: .zero, size: size))
      context.restoreGState()
      return
    }
    let accent = parsedColor(state.frameAccent) ?? parsedColor(state.finderForeground) ?? NSColor.systemBlue.cgColor
    let ink = parsedColor(state.foreground) ?? NSColor.black.cgColor
    let base = frameBounds(index)
    let sx = size.width / base.width
    let sy = size.height / base.height
    context.saveGState()
    context.scaleBy(x: sx, y: sy)
    context.setStrokeColor(accent)
    context.setFillColor(accent)
    context.setLineWidth(2.4)

    switch index {
    case 1:
      context.setFillColor(accent.copy(alpha: 0.12) ?? accent)
      context.fill(CGPath(roundedRect: CGRect(x: 1, y: 1, width: 149, height: 202), cornerWidth: 13, cornerHeight: 13, transform: nil))
      frameText(context, text: frameCaption(state, fallback: "SCAN ME"), x: 47, y: 174, width: 92, size: 12, color: ink)
      context.setStrokeColor(accent)
      context.stroke(CGPath(roundedRect: CGRect(x: 4, y: 4, width: 143, height: 196), cornerWidth: 11, cornerHeight: 11, transform: nil))
    case 2:
      context.setFillColor(accent)
      context.fill(CGPath(roundedRect: CGRect(x: 0, y: 0, width: 103, height: 128), cornerWidth: 11, cornerHeight: 11, transform: nil))
      context.setFillColor((parsedColor(state.background) ?? .white))
      context.fill(CGPath(roundedRect: CGRect(x: 5, y: 5, width: 93, height: 118), cornerWidth: 8, cornerHeight: 8, transform: nil))
      context.setFillColor(accent)
      context.fill(CGPath(roundedRect: CGRect(x: 0, y: 0, width: 103, height: 27), cornerWidth: 10, cornerHeight: 10, transform: nil))
      context.fill(CGRect(x: 0, y: 17, width: 103, height: 10))
      frameText(context, text: frameCaption(state, fallback: "SCAN"), x: 51, y: 18, width: 90, size: 10, color: NSColor.white.cgColor)
      context.setStrokeColor(accent)
      context.stroke(CGPath(roundedRect: CGRect(x: 108, y: 20, width: 35, height: 148), cornerWidth: 12, cornerHeight: 12, transform: nil))
    case 3:
      context.setFillColor(accent)
      context.fill(CGPath(roundedRect: CGRect(x: 0, y: 0, width: 100, height: 128), cornerWidth: 4, cornerHeight: 4, transform: nil))
      context.setFillColor(parsedColor(state.background) ?? .white)
      context.fill(CGPath(roundedRect: CGRect(x: 3, y: 3, width: 94, height: 94), cornerWidth: 4, cornerHeight: 4, transform: nil))
      context.setStrokeColor(accent)
      context.strokeEllipse(in: CGRect(x: 111, y: 32, width: 30, height: 30))
      frameText(context, text: frameCaption(state, fallback: "OPEN CAMERA"), x: 50, y: 117, width: 92, size: 9, color: ink)
    case 4:
      drawDotMotif(context, x: 8, y: 10, columns: 5, rows: 8, gap: 7, radius: 1.5, color: accent)
      frameText(context, text: frameCaption(state, fallback: "SCAN"), x: 24, y: 63, width: 43, size: 8, color: ink)
      context.setStrokeColor(accent)
      context.stroke(CGPath(roundedRect: CGRect(x: 49, y: 5, width: 95, height: 101), cornerWidth: 10, cornerHeight: 10, transform: nil))
    case 5:
      context.setStrokeColor(accent)
      context.setLineWidth(5)
      context.stroke(CGPath(roundedRect: CGRect(x: 8, y: 4, width: 135, height: 278), cornerWidth: 23, cornerHeight: 23, transform: nil))
      context.setFillColor(accent.copy(alpha: 0.12) ?? accent)
      context.fill(CGPath(roundedRect: CGRect(x: 16, y: 10, width: 119, height: 268), cornerWidth: 18, cornerHeight: 18, transform: nil))
      context.setFillColor(accent)
      context.fillEllipse(in: CGRect(x: 69, y: 17, width: 13, height: 13))
      frameText(context, text: frameCaption(state, fallback: "SCAN ME"), x: 75, y: 158, width: 120, size: 12, color: ink)
    case 6:
      context.setStrokeColor(accent)
      context.setLineWidth(5)
      context.stroke(CGPath(roundedRect: CGRect(x: 7, y: 4, width: 137, height: 274), cornerWidth: 14, cornerHeight: 14, transform: nil))
      drawDotMotif(context, x: 23, y: 142, columns: 8, rows: 5, gap: 9, radius: 2, color: accent)
      frameText(context, text: frameCaption(state, fallback: "POINT YOUR CAMERA"), x: 75, y: 266, width: 115, size: 10, color: ink)
    case 7:
      context.setStrokeColor(accent)
      context.setLineWidth(4)
      context.stroke(CGPath(roundedRect: CGRect(x: 199, y: 1, width: 124, height: 124), cornerWidth: 16, cornerHeight: 16, transform: nil))
      frameText(context, text: frameCaption(state, fallback: "SCAN ME"), x: 112, y: 66, width: 178, size: 20, color: ink)
      context.setFillColor(accent)
      context.fill(CGRect(x: 25, y: 38, width: 72, height: 4))
    case 8:
      context.setStrokeColor(accent)
      context.setLineWidth(5)
      context.stroke(CGPath(roundedRect: CGRect(x: 1, y: 11, width: 285, height: 100), cornerWidth: 48, cornerHeight: 48, transform: nil))
      frameText(context, text: frameCaption(state, fallback: "SCAN HERE"), x: 146, y: 66, width: 170, size: 18, color: ink)
      context.setFillColor(accent)
      context.fillEllipse(in: CGRect(x: 170, y: 50, width: 8, height: 8))
    case 9:
      context.setStrokeColor(accent)
      context.setLineWidth(4)
      context.stroke(CGPath(roundedRect: CGRect(x: 2, y: 2, width: 321, height: 131), cornerWidth: 12, cornerHeight: 12, transform: nil))
      context.setFillColor(accent.copy(alpha: 0.1) ?? accent)
      context.fill(CGPath(roundedRect: CGRect(x: 10, y: 10, width: 186, height: 115), cornerWidth: 9, cornerHeight: 9, transform: nil))
      frameText(context, text: frameCaption(state, fallback: "SCAN TO LEARN MORE"), x: 102, y: 68, width: 180, size: 14, color: ink)
    case 10:
      context.setStrokeColor(accent)
      context.setLineWidth(3)
      context.stroke(CGPath(roundedRect: CGRect(x: 4, y: 4, width: 143, height: 70), cornerWidth: 14, cornerHeight: 14, transform: nil))
      frameText(context, text: frameCaption(state, fallback: "SCAN"), x: 105, y: 46, width: 79, size: 12, color: ink)
    default:
      context.setStrokeColor(accent)
      context.setLineWidth(3)
      context.stroke(CGPath(roundedRect: CGRect(x: 3, y: 4, width: 145, height: 78), cornerWidth: 9, cornerHeight: 9, transform: nil))
      drawDotMotif(context, x: 87, y: 31, columns: 5, rows: 3, gap: 8, radius: 1.4, color: accent)
      frameText(context, text: frameCaption(state, fallback: "SCAN ME"), x: 113, y: 63, width: 62, size: 8, color: ink)
    }
    context.restoreGState()
  }

  private static func drawDotMotif(_ context: CGContext, x: CGFloat, y: CGFloat, columns: Int, rows: Int, gap: CGFloat, radius: CGFloat, color: CGColor) {
    context.setFillColor(color)
    for row in 0..<rows {
      for column in 0..<columns where (row + column) % 3 != 1 {
        let px = x + CGFloat(column) * gap
        let py = y + CGFloat(row) * gap
        context.fillEllipse(in: CGRect(x: px, y: py, width: radius * 2, height: radius * 2))
      }
    }
  }

  private static func suppliedFrameImage(for index: Int) -> CGImage? {
    guard let url = suppliedFrameURL(for: index), let image = NSImage(contentsOf: url) else { return nil }
    var rect = CGRect(origin: .zero, size: image.size)
    return image.cgImage(forProposedRect: &rect, context: nil, hints: nil)
  }

  private static func suppliedFrameData(for index: Int) -> Data? {
    guard let url = suppliedFrameURL(for: index) else { return nil }
    return try? Data(contentsOf: url)
  }

  private static func suppliedFrameURL(for index: Int) -> URL? {
    let number: Int
    switch index {
    case 1...6, 8, 10, 11: number = index
    case 7: number = 13
    case 9: number = 12
    default: return nil
    }
    return Bundle.main.url(
      forResource: String(format: "Scan-me-%02d", number),
      withExtension: "png",
      subdirectory: "Templates"
    )
  }

  private static func frameText(_ context: CGContext, text: String, x: CGFloat, y: CGFloat, width: CGFloat, size: CGFloat, color: CGColor) {
    let font = CTFontCreateWithName("Helvetica-Bold" as CFString, size, nil)
    let attributes: [NSAttributedString.Key: Any] = [
      NSAttributedString.Key(kCTFontAttributeName as String): font,
      NSAttributedString.Key(kCTForegroundColorAttributeName as String): color
    ]
    let line = CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: attributes))
    let bounds = CTLineGetBoundsWithOptions(line, [])
    context.saveGState()
    context.translateBy(x: x, y: y)
    context.scaleBy(x: 1, y: -1)
    context.textMatrix = .identity
    context.textPosition = CGPoint(x: -min(width, bounds.width) / 2, y: 0)
    CTLineDraw(line, context)
    context.restoreGState()
  }

  private static func canvasDimensions(for template: FrameTemplate, requestedSide: Int) -> (width: Int, height: Int) {
    let safeSide = max(32, requestedSide)
    let side = min(maxRasterSide, safeSide)
    let raw = scaledCanvasDimensions(for: template, side: side)
    var width = raw.width
    var height = raw.height
    let pixelCount = width * height
    if pixelCount > maxRasterPixels {
      let factor = sqrt(Double(maxRasterPixels) / Double(pixelCount))
      width = max(1, Int((Double(width) * factor).rounded(.down)))
      height = max(1, Int((Double(height) * factor).rounded(.down)))
    }
    return (width, height)
  }

  private static func rasterExportDimensions(for template: FrameTemplate, requestedSide: Int) throws -> (width: Int, height: Int) {
    let side = max(32, requestedSide)
    guard side <= maxRasterSide else { throw QRRenderingError.rasterTooLarge }
    let dimensions = scaledCanvasDimensions(for: template, side: side)
    guard dimensions.width <= maxRasterPixels / dimensions.height else { throw QRRenderingError.rasterTooLarge }
    return dimensions
  }

  private static func scaledCanvasDimensions(for template: FrameTemplate, side: Int) -> (width: Int, height: Int) {
    let bounds = frameBounds(frameIndex(template) ?? 0)
    let scale = CGFloat(side) / max(bounds.width, bounds.height)
    return (max(1, Int((bounds.width * scale).rounded())), max(1, Int((bounds.height * scale).rounded())))
  }

  private static func qrLayout(state: StudioState, matrix: QRMatrix, width: CGFloat, height: CGFloat) -> QRLayout {
    let index = frameIndex(state.frameTemplate)
    guard let index else {
      return QRLayout(qrX: 0, qrY: 0, qrSize: min(width, height))
    }
    let bounds = frameBounds(index)
    let slot = frameSlot(index)
    let scale = min(width / bounds.width, height / bounds.height)
    return QRLayout(qrX: slot.x * scale, qrY: slot.y * scale, qrSize: slot.size * scale)
  }

  private static func frameBounds(_ index: Int) -> CGSize {
    switch index {
    case 1: return CGSize(width: 95, height: 128)
    case 2: return CGSize(width: 103, height: 128)
    case 3: return CGSize(width: 100, height: 128)
    case 4: return CGSize(width: 151, height: 111)
    case 5: return CGSize(width: 151, height: 293)
    case 6: return CGSize(width: 151, height: 282)
    case 7: return CGSize(width: 325, height: 126)
    case 8: return CGSize(width: 325, height: 122)
    case 9: return CGSize(width: 325, height: 135)
    case 10: return CGSize(width: 151, height: 78)
    case 11: return CGSize(width: 151, height: 86)
    default: return CGSize(width: 1, height: 1)
    }
  }

  private static func frameSlot(_ index: Int) -> QRSlot {
    switch index {
    case 1: return QRSlot(x: 8, y: 8, size: 78)
    case 2: return QRSlot(x: 7, y: 31, size: 89)
    case 3: return QRSlot(x: 5, y: 5, size: 90)
    case 4: return QRSlot(x: 47, y: 5, size: 99)
    case 5: return QRSlot(x: 24.694, y: 165.934, size: 100.969)
    case 6: return QRSlot(x: 21.232, y: 23.294, size: 107.910)
    case 7: return QRSlot(x: 222.843, y: 24.028, size: 77.876)
    case 8: return QRSlot(x: 228.672, y: 25.358, size: 70.716)
    case 9: return QRSlot(x: 206.624, y: 16.425, size: 101.683)
    case 10: return QRSlot(x: 9.732, y: 9.732, size: 57.559)
    default: return QRSlot(x: 13.678, y: 13.209, size: 58.745)
    }
  }

  private static func frameIndex(_ template: FrameTemplate) -> Int? {
    switch template {
    case .none: return nil
    case .scanMe01: return 1
    case .scanMe02: return 2
    case .scanMe03: return 3
    case .scanMe04: return 4
    case .scanMe05: return 5
    case .scanMe06: return 6
    case .scanMe13: return 7
    case .scanMe08: return 8
    case .scanMe12: return 9
    case .scanMe10: return 10
    case .scanMe11: return 11
    }
  }

  private static func warnings(for state: StudioState, matrix: QRMatrix, requestedSize: Int, dimensions: (width: Int, height: Int)) -> [String] {
    var result: [String] = []
    if state.margin < 4 { result.append("quiet-zone-low") }
    let foreground = parsedColor(state.foreground) ?? .black
    let background = parsedColor(state.background) ?? .white
    if contrastRatio(foreground, background) < 4.5 && !state.transparentBackground { result.append("contrast-low") }
    if let logo = state.logo {
      if logo.scale > 0.24 && state.errorCorrection != .high { result.append("logo-needs-high-ec") }
      if logo.scale > 0.30 { result.append("logo-too-large") }
    }
    if matrix.count > 65 { result.append("payload-dense") }
    if requestedSize > maxRasterSide || dimensions.width * dimensions.height >= maxRasterPixels { result.append("raster-size-high") }
    if frameIndex(state.frameTemplate) != nil && requestedSize < 512 { result.append("frame-small-output") }
    return result
  }

  private static func makeSVG(state: StudioState, matrix: QRMatrix, requestedSide: Int) -> String {
    let dimensions = canvasDimensions(for: state.frameTemplate, requestedSide: requestedSide)
    let width = CGFloat(dimensions.width), height = CGFloat(dimensions.height)
    let layout = qrLayout(state: state, matrix: matrix, width: width, height: height)
    let bg = parsedColor(state.background) ?? .white
    let fg = parsedColor(state.foreground) ?? .black
    let finder = parsedColor(state.finderForeground) ?? fg
    var svg = "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"\(dimensions.width)\" height=\"\(dimensions.height)\" viewBox=\"0 0 \(dimensions.width) \(dimensions.height)\" shape-rendering=\"geometricPrecision\">"
    if !state.transparentBackground { svg += "<rect width=\"100%\" height=\"100%\" fill=\"\(svgColor(bg))\"/>" }
    appendFrameSVG(&svg, state: state, width: width, height: height)
    if frameIndex(state.frameTemplate) != nil && !state.transparentBackground {
      svg += "<rect x=\"\(n(layout.qrX))\" y=\"\(n(layout.qrY))\" width=\"\(n(layout.qrSize))\" height=\"\(n(layout.qrSize))\" fill=\"\(svgColor(bg))\"/>"
    }
    let count = CGFloat(matrix.count)
    let margin = CGFloat(min(16, max(0, state.margin)))
    let unit = layout.qrSize / max(1, count + margin * 2)
    for y in 0..<matrix.count {
      for x in 0..<matrix.count where matrix.modules[y][x] {
        let isFinder = isFinder(x: x, y: y, count: matrix.count)
        let color = state.separateFinders && isFinder ? finder : fg
        appendSVGModule(&svg, x: layout.qrX + (margin + CGFloat(x)) * unit, y: layout.qrY + (margin + CGFloat(y)) * unit, size: unit, color: color, shape: isFinder ? (state.finderShape == .circle ? .dot : (state.finderShape == .rounded ? .rounded : .square)) : state.moduleShape)
      }
    }
    if let logo = state.logo {
      let logoSize = layout.qrSize * min(0.34, max(0.08, CGFloat(logo.scale)))
      let padding = max(0, CGFloat(logo.padding)) * (layout.qrSize / CGFloat(defaultPreviewSize)).clamped(to: 0.05...1.0)
      let cardSize = logoSize + padding * 2
      let x = layout.qrX + (layout.qrSize - cardSize) / 2
      let y = layout.qrY + (layout.qrSize - cardSize) / 2
      let radius = logo.circleCard ? cardSize / 2 : min(cardSize / 2, CGFloat(logo.radius))
      let card = parsedColor(logo.cardColor) ?? .white
      let dataType = mimeType(for: logo.data)
      let dataURL = "data:\(dataType);base64,\(logo.data.base64EncodedString())"
      svg += "<rect x=\"\(n(x))\" y=\"\(n(y))\" width=\"\(n(cardSize))\" height=\"\(n(cardSize))\" rx=\"\(n(radius))\" fill=\"\(svgColor(card))\"/>"
      svg += "<image href=\"\(dataURL)\" x=\"\(n(x + padding))\" y=\"\(n(y + padding))\" width=\"\(n(logoSize))\" height=\"\(n(logoSize))\" preserveAspectRatio=\"xMidYMid meet\"/>"
    }
    svg += "</svg>"
    return svg
  }

  private static func appendSVGModule(_ svg: inout String, x: CGFloat, y: CGFloat, size: CGFloat, color: CGColor, shape: ModuleShape) {
    let fill = svgColor(color)
    switch shape {
    case .rounded:
      svg += "<rect x=\"\(n(x))\" y=\"\(n(y))\" width=\"\(n(size))\" height=\"\(n(size))\" rx=\"\(n(size * 0.28))\" fill=\"\(fill)\"/>"
    case .dot:
      svg += "<circle cx=\"\(n(x + size / 2))\" cy=\"\(n(y + size / 2))\" r=\"\(n(size * 0.46))\" fill=\"\(fill)\"/>"
    case .diamond:
      svg += "<polygon points=\"\(n(x + size / 2)),\(n(y)) \(n(x + size)),\(n(y + size / 2)) \(n(x + size / 2)),\(n(y + size)) \(n(x)),\(n(y + size / 2))\" fill=\"\(fill)\"/>"
    case .square:
      svg += "<rect x=\"\(n(x))\" y=\"\(n(y))\" width=\"\(n(size))\" height=\"\(n(size))\" fill=\"\(fill)\"/>"
    }
  }

  private static func appendFrameSVG(_ svg: inout String, state: StudioState, width: CGFloat, height: CGFloat) {
    guard let index = frameIndex(state.frameTemplate) else { return }
    if let frameData = suppliedFrameData(for: index) {
      let bounds = frameBounds(index)
      let slot = frameSlot(index)
      let scale = min(width / bounds.width, height / bounds.height)
      svg += "<defs><mask id=\"frame-safe-area\"><rect width=\"100%\" height=\"100%\" fill=\"white\"/><rect x=\"\(n(slot.x * scale))\" y=\"\(n(slot.y * scale))\" width=\"\(n(slot.size * scale))\" height=\"\(n(slot.size * scale))\" fill=\"black\"/></mask></defs>"
      svg += "<image href=\"data:image/png;base64,\(frameData.base64EncodedString())\" x=\"0\" y=\"0\" width=\"\(n(width))\" height=\"\(n(height))\" preserveAspectRatio=\"none\" mask=\"url(#frame-safe-area)\"/>"
      return
    }
    let bounds = frameBounds(index)
    let accent = svgColor(parsedColor(state.frameAccent) ?? parsedColor(state.finderForeground) ?? NSColor.black.cgColor)
    let scale = min(width / bounds.width, height / bounds.height)
    let rect: CGRect
    switch index {
    case 1: rect = CGRect(x: 4, y: 4, width: 143, height: 196)
    case 2: rect = CGRect(x: 0, y: 0, width: 103, height: 128)
    case 3: rect = CGRect(x: 0, y: 0, width: 100, height: 128)
    case 4: rect = CGRect(x: 49, y: 5, width: 95, height: 101)
    case 5: rect = CGRect(x: 8, y: 4, width: 135, height: 278)
    case 6: rect = CGRect(x: 7, y: 4, width: 137, height: 274)
    case 7: rect = CGRect(x: 199, y: 1, width: 124, height: 124)
    case 8: rect = CGRect(x: 1, y: 11, width: 285, height: 100)
    case 9: rect = CGRect(x: 2, y: 2, width: 321, height: 131)
    case 10: rect = CGRect(x: 4, y: 4, width: 143, height: 70)
    default: rect = CGRect(x: 3, y: 4, width: 145, height: 78)
    }
    let x = rect.minX * scale, y = rect.minY * scale, w = rect.width * scale, h = rect.height * scale
    let radius = min(18, h * 0.24)
    let slot = frameSlot(index)
    let slotX = slot.x * scale, slotY = slot.y * scale, slotSize = slot.size * scale
    svg += "<defs><mask id=\"frame-safe-area\"><rect width=\"100%\" height=\"100%\" fill=\"white\"/><rect x=\"\(n(slotX))\" y=\"\(n(slotY))\" width=\"\(n(slotSize))\" height=\"\(n(slotSize))\" fill=\"black\"/></mask></defs><g mask=\"url(#frame-safe-area)\">"
    let ink = svgColor(parsedColor(state.foreground) ?? NSColor.black.cgColor)
    let background = svgColor(parsedColor(state.background) ?? NSColor.white.cgColor)
    let caption = xmlEscape(frameCaption(state, fallback: "SCAN ME"))
    let strokeWidth = n(max(2, scale * 2.5))
    switch index {
    case 1:
      svg += "<rect x=\"\(n(x))\" y=\"\(n(y))\" width=\"\(n(w))\" height=\"\(n(h))\" rx=\"\(n(radius))\" fill=\"\(accent)\" fill-opacity=\"0.12\" stroke=\"\(accent)\" stroke-width=\"\(strokeWidth)\"/>"
      appendFrameTextSVG(&svg, text: caption, x: 47 * scale, y: 174 * scale, size: 12 * scale, color: ink)
    case 2:
      svg += "<rect x=\"0\" y=\"0\" width=\"\(n(103 * scale))\" height=\"\(n(128 * scale))\" rx=\"\(n(11 * scale))\" fill=\"\(accent)\"/>"
      svg += "<rect x=\"\(n(5 * scale))\" y=\"\(n(5 * scale))\" width=\"\(n(93 * scale))\" height=\"\(n(118 * scale))\" rx=\"\(n(8 * scale))\" fill=\"\(background)\"/>"
      svg += "<rect x=\"0\" y=\"0\" width=\"\(n(103 * scale))\" height=\"\(n(27 * scale))\" rx=\"\(n(10 * scale))\" fill=\"\(accent)\"/>"
      appendFrameTextSVG(&svg, text: caption, x: 51 * scale, y: 18 * scale, size: 10 * scale, color: "#FFFFFF")
      svg += "<rect x=\"\(n(108 * scale))\" y=\"\(n(20 * scale))\" width=\"\(n(35 * scale))\" height=\"\(n(148 * scale))\" rx=\"\(n(12 * scale))\" fill=\"none\" stroke=\"\(accent)\" stroke-width=\"\(strokeWidth)\"/>"
    case 3:
      svg += "<rect x=\"0\" y=\"0\" width=\"\(n(100 * scale))\" height=\"\(n(128 * scale))\" rx=\"\(n(4 * scale))\" fill=\"\(accent)\"/>"
      svg += "<rect x=\"\(n(3 * scale))\" y=\"\(n(3 * scale))\" width=\"\(n(94 * scale))\" height=\"\(n(94 * scale))\" rx=\"\(n(4 * scale))\" fill=\"\(background)\"/>"
      appendFrameTextSVG(&svg, text: caption, x: 50 * scale, y: 117 * scale, size: 9 * scale, color: "#FFFFFF")
      svg += "<circle cx=\"\(n(126 * scale))\" cy=\"\(n(47 * scale))\" r=\"\(n(15 * scale))\" fill=\"none\" stroke=\"\(accent)\" stroke-width=\"\(strokeWidth)\"/>"
    case 4:
      appendFrameDotsSVG(&svg, x: 8 * scale, y: 10 * scale, columns: 5, rows: 8, gap: 7 * scale, radius: 1.5 * scale, color: accent)
      appendFrameTextSVG(&svg, text: caption, x: 24 * scale, y: 63 * scale, size: 8 * scale, color: ink)
      svg += "<rect x=\"\(n(x))\" y=\"\(n(y))\" width=\"\(n(w))\" height=\"\(n(h))\" rx=\"\(n(radius))\" fill=\"none\" stroke=\"\(accent)\" stroke-width=\"\(strokeWidth)\"/>"
    case 5:
      svg += "<rect x=\"\(n(8 * scale))\" y=\"\(n(4 * scale))\" width=\"\(n(135 * scale))\" height=\"\(n(278 * scale))\" rx=\"\(n(23 * scale))\" fill=\"\(accent)\" fill-opacity=\"0.12\" stroke=\"\(accent)\" stroke-width=\"\(n(5 * scale))\"/>"
      appendFrameTextSVG(&svg, text: caption, x: 75 * scale, y: 158 * scale, size: 12 * scale, color: ink)
    case 6:
      svg += "<rect x=\"\(n(7 * scale))\" y=\"\(n(4 * scale))\" width=\"\(n(137 * scale))\" height=\"\(n(274 * scale))\" rx=\"\(n(14 * scale))\" fill=\"none\" stroke=\"\(accent)\" stroke-width=\"\(n(5 * scale))\"/>"
      appendFrameDotsSVG(&svg, x: 23 * scale, y: 142 * scale, columns: 8, rows: 5, gap: 9 * scale, radius: 2 * scale, color: accent)
      appendFrameTextSVG(&svg, text: caption, x: 75 * scale, y: 266 * scale, size: 10 * scale, color: ink)
    case 7:
      svg += "<rect x=\"\(n(x))\" y=\"\(n(y))\" width=\"\(n(w))\" height=\"\(n(h))\" rx=\"\(n(radius))\" fill=\"none\" stroke=\"\(accent)\" stroke-width=\"\(strokeWidth)\"/>"
      appendFrameTextSVG(&svg, text: caption, x: 112 * scale, y: 66 * scale, size: 20 * scale, color: ink)
      svg += "<rect x=\"\(n(25 * scale))\" y=\"\(n(38 * scale))\" width=\"\(n(72 * scale))\" height=\"\(n(4 * scale))\" fill=\"\(accent)\"/>"
    case 8:
      svg += "<rect x=\"\(n(x))\" y=\"\(n(y))\" width=\"\(n(w))\" height=\"\(n(h))\" rx=\"\(n(48 * scale))\" fill=\"none\" stroke=\"\(accent)\" stroke-width=\"\(n(5 * scale))\"/>"
      appendFrameTextSVG(&svg, text: caption, x: 146 * scale, y: 66 * scale, size: 18 * scale, color: ink)
      svg += "<circle cx=\"\(n(174 * scale))\" cy=\"\(n(54 * scale))\" r=\"\(n(4 * scale))\" fill=\"\(accent)\"/>"
    case 9:
      svg += "<rect x=\"\(n(x))\" y=\"\(n(y))\" width=\"\(n(w))\" height=\"\(n(h))\" rx=\"\(n(radius))\" fill=\"none\" stroke=\"\(accent)\" stroke-width=\"\(strokeWidth)\"/>"
      svg += "<rect x=\"\(n(10 * scale))\" y=\"\(n(10 * scale))\" width=\"\(n(186 * scale))\" height=\"\(n(115 * scale))\" rx=\"\(n(9 * scale))\" fill=\"\(accent)\" fill-opacity=\"0.10\"/>"
      appendFrameTextSVG(&svg, text: caption, x: 102 * scale, y: 68 * scale, size: 14 * scale, color: ink)
    case 10:
      svg += "<rect x=\"\(n(x))\" y=\"\(n(y))\" width=\"\(n(w))\" height=\"\(n(h))\" rx=\"\(n(radius))\" fill=\"none\" stroke=\"\(accent)\" stroke-width=\"\(strokeWidth)\"/>"
      appendFrameTextSVG(&svg, text: caption, x: 105 * scale, y: 46 * scale, size: 12 * scale, color: ink)
    default:
      svg += "<rect x=\"\(n(x))\" y=\"\(n(y))\" width=\"\(n(w))\" height=\"\(n(h))\" rx=\"\(n(radius))\" fill=\"none\" stroke=\"\(accent)\" stroke-width=\"\(strokeWidth)\"/>"
      appendFrameDotsSVG(&svg, x: 87 * scale, y: 31 * scale, columns: 5, rows: 3, gap: 8 * scale, radius: 1.4 * scale, color: accent)
      appendFrameTextSVG(&svg, text: caption, x: 113 * scale, y: 63 * scale, size: 8 * scale, color: ink)
    }
    svg += "</g>"
  }

  private static func appendFrameDotsSVG(_ svg: inout String, x: CGFloat, y: CGFloat, columns: Int, rows: Int, gap: CGFloat, radius: CGFloat, color: String) {
    for row in 0..<rows {
      for column in 0..<columns where (row + column) % 3 != 1 {
        svg += "<circle cx=\"\(n(x + CGFloat(column) * gap + radius))\" cy=\"\(n(y + CGFloat(row) * gap + radius))\" r=\"\(n(radius))\" fill=\"\(color)\"/>"
      }
    }
  }

  private static func appendFrameTextSVG(_ svg: inout String, text: String, x: CGFloat, y: CGFloat, size: CGFloat, color: String) {
    svg += "<text x=\"\(n(x))\" y=\"\(n(y))\" text-anchor=\"middle\" font-family=\"Helvetica,Arial,sans-serif\" font-size=\"\(n(size))\" font-weight=\"700\" fill=\"\(color)\">\(text)</text>"
  }

  private static func xmlEscape(_ text: String) -> String {
    text.replacingOccurrences(of: "&", with: "&amp;")
      .replacingOccurrences(of: "<", with: "&lt;")
      .replacingOccurrences(of: ">", with: "&gt;")
      .replacingOccurrences(of: "\"", with: "&quot;")
      .replacingOccurrences(of: "'", with: "&apos;")
  }

  private static func encode(_ image: CGImage, type: String, quality: Double? = nil) throws -> Data {
    let data = NSMutableData()
    guard let destination = CGImageDestinationCreateWithData(data as CFMutableData, type as CFString, 1, nil) else {
      if type == "org.webmproject.webp" { throw QRRenderingError.webpEncoderUnavailable }
      throw QRRenderingError.exportFailed
    }
    var options: [CFString: Any] = [:]
    if let quality { options[kCGImageDestinationLossyCompressionQuality] = quality }
    CGImageDestinationAddImage(destination, image, options as CFDictionary)
    guard CGImageDestinationFinalize(destination) else { throw QRRenderingError.exportFailed }
    return data as Data
  }

  private static func makePDF(_ image: CGImage) throws -> Data {
    let nsImage = NSImage(cgImage: image, size: CGSize(width: image.width, height: image.height))
    guard let page = PDFPage(image: nsImage) else { throw QRRenderingError.exportFailed }
    let document = PDFDocument()
    document.insert(page, at: 0)
    guard let data = document.dataRepresentation() else { throw QRRenderingError.exportFailed }
    return data
  }

  private static func composite(_ image: CGImage, background: CGColor) -> CGImage {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGBitmapInfo.byteOrder32Big.union(CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue))
    guard let context = CGContext(data: nil, width: image.width, height: image.height, bitsPerComponent: 8, bytesPerRow: image.width * 4, space: colorSpace, bitmapInfo: bitmapInfo.rawValue) else { return image }
    context.setFillColor(background)
    context.fill(CGRect(x: 0, y: 0, width: image.width, height: image.height))
    context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
    return context.makeImage() ?? image
  }

  private static func aspectFit(source: CGSize, inside target: CGRect) -> CGRect {
    let scale = min(target.width / source.width, target.height / source.height)
    let width = source.width * scale, height = source.height * scale
    return CGRect(x: target.midX - width / 2, y: target.midY - height / 2, width: width, height: height)
  }

  private static func isFinder(x: Int, y: Int, count: Int) -> Bool {
    (x < 7 && y < 7) || (x >= count - 7 && y < 7) || (x < 7 && y >= count - 7)
  }

  private static func moduleShape(for finder: FinderShape) -> ModuleShape {
    switch finder {
    case .square: return .square
    case .rounded: return .rounded
    case .circle: return .dot
    }
  }

  private static func parsedColor(_ hex: String) -> CGColor? {
    let trimmed = hex.trimmingCharacters(in: .whitespacesAndNewlines)
    let value = trimmed.hasPrefix("#") ? String(trimmed.dropFirst()) : trimmed
    let expanded: String
    if value.count == 3 || value.count == 4 {
      expanded = value.map { "\($0)\($0)" }.joined()
    } else {
      expanded = value
    }
    guard expanded.count == 6 || expanded.count == 8, let number = UInt64(expanded, radix: 16) else { return nil }
    let red, green, blue, alpha: CGFloat
    if expanded.count == 8 {
      red = CGFloat((number >> 24) & 0xff) / 255
      green = CGFloat((number >> 16) & 0xff) / 255
      blue = CGFloat((number >> 8) & 0xff) / 255
      alpha = CGFloat(number & 0xff) / 255
    } else {
      red = CGFloat((number >> 16) & 0xff) / 255
      green = CGFloat((number >> 8) & 0xff) / 255
      blue = CGFloat(number & 0xff) / 255
      alpha = 1
    }
    return CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [red, green, blue, alpha])
  }

  private static func contrastRatio(_ a: CGColor, _ b: CGColor) -> Double {
    func luminance(_ color: CGColor) -> Double {
      let rgb = color.converted(to: CGColorSpaceCreateDeviceRGB(), intent: .defaultIntent, options: nil)?.components ?? [0, 0, 0, 1]
      func linear(_ component: CGFloat) -> Double {
        let value = Double(component)
        return value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
      }
      let r = linear(rgb[0]), g = linear(rgb[1]), blue = linear(rgb[2])
      return 0.2126 * r + 0.7152 * g + 0.0722 * blue
    }
    let first = luminance(a), second = luminance(b)
    return (max(first, second) + 0.05) / (min(first, second) + 0.05)
  }

  private static func svgColor(_ color: CGColor) -> String {
    let components = color.converted(to: CGColorSpaceCreateDeviceRGB(), intent: .defaultIntent, options: nil)?.components ?? [0, 0, 0, 1]
    let r = Int((components[0] * 255).rounded()), g = Int((components[1] * 255).rounded()), b = Int((components[2] * 255).rounded())
    if components.count > 3 && components[3] < 0.999 {
      return "rgba(\(r),\(g),\(b),\(String(format: "%.3f", components[3])))"
    }
    return String(format: "#%02X%02X%02X", r, g, b)
  }

  private static func mimeType(for data: Data) -> String {
    guard data.count >= 12 else { return "image/png" }
    if data.starts(with: [0xFF, 0xD8, 0xFF]) { return "image/jpeg" }
    if data.starts(with: [0x52, 0x49, 0x46, 0x46]) { return "image/webp" }
    return "image/png"
  }

  private static func frameCaption(_ state: StudioState, fallback: String) -> String {
    let value = state.frameText.trimmingCharacters(in: .whitespacesAndNewlines)
    return value.isEmpty ? fallback : value
  }

  private static func n(_ value: CGFloat) -> String { String(format: "%.3f", Double(value)) }
}

private struct QRMatrix {
  let modules: [[Bool]]
  var count: Int { modules.count }
}

private struct QRLayout {
  let qrX: CGFloat
  let qrY: CGFloat
  let qrSize: CGFloat
}

private struct QRSlot {
  let x: CGFloat
  let y: CGFloat
  let size: CGFloat
}

private enum QRRenderingError: LocalizedError {
  case emptyPayload
  case couldNotEncode
  case invalidMatrix
  case couldNotAllocateCanvas
  case invalidLogo
  case logoTooLarge
  case decoderUnavailable
  case webpEncoderUnavailable
  case rasterTooLarge
  case exportFailed

  var errorDescription: String? {
    switch self {
    case .emptyPayload: return "Add content before generating a QR code."
    case .couldNotEncode: return "Core Image could not encode this payload as a QR code."
    case .invalidMatrix: return "Core Image returned an invalid QR matrix."
    case .couldNotAllocateCanvas: return "The QR image canvas could not be allocated."
    case .invalidLogo: return "The selected logo image could not be read."
    case .logoTooLarge: return "The logo exceeds the safe image size limit."
    case .decoderUnavailable: return "The macOS QR decoder is unavailable."
    case .webpEncoderUnavailable: return "This macOS installation does not provide a WebP image encoder."
    case .rasterTooLarge: return "Raster export exceeds 12,000 pixels per side or 96 megapixels. Choose a smaller size or export as SVG."
    case .exportFailed: return "The QR file could not be exported."
    }
  }
}

private extension CGFloat {
  func clamped(to range: ClosedRange<CGFloat>) -> CGFloat { Swift.min(range.upperBound, Swift.max(range.lowerBound, self)) }
}

private extension CGContext {
  func fill(_ path: CGPath) {
    addPath(path)
    fillPath()
  }

  func stroke(_ path: CGPath) {
    addPath(path)
    strokePath()
  }
}
