import AppKit
import Foundation

let output = URL(filePath: CommandLine.arguments[1])
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
let icon = NSImage(size: NSSize(width: 1024, height: 1024))
icon.lockFocus()
let background = NSBezierPath(roundedRect: NSRect(x: 32, y: 32, width: 960, height: 960), xRadius: 216, yRadius: 216)
let gradient = NSGradient(starting: NSColor(red: 0.05, green: 0.68, blue: 0.72, alpha: 1), ending: NSColor(red: 0.04, green: 0.26, blue: 0.63, alpha: 1))!
gradient.draw(in: background, angle: -90)
let symbol = NSImage(systemSymbolName: "wifi", accessibilityDescription: nil)!
  .withSymbolConfiguration(NSImage.SymbolConfiguration(paletteColors: [.white]))!
symbol.draw(in: NSRect(x: 230, y: 312, width: 564, height: 400))
icon.unlockFocus()
for size in [16, 32, 128, 256, 512] {
  for scale in [1, 2] {
    let pixels = size * scale
    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
      bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
      colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    icon.draw(in: NSRect(x: 0, y: 0, width: pixels, height: pixels))
    NSGraphicsContext.restoreGraphicsState()
    let suffix = scale == 2 ? "@2x" : ""
    try bitmap.representation(using: .png, properties: [:])!
      .write(to: output.appendingPathComponent("icon_\(size)x\(size)\(suffix).png"))
  }
}
