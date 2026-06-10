// Templateize.swift — turn a black-on-white pictogram into a macOS template
// image: alpha = darkness, color = solid black. Trims to the glyph's bounding
// box (squared, centered) and writes 1x/2x PNGs.
//
//   swift Templateize.swift <in.png> <outBase> <pointSize>
//   → writes <outBase>.png (pointSize px) and <outBase>@2x.png (2× px)

import AppKit
import CoreGraphics

let args = CommandLine.arguments
guard args.count == 4, let pt = Int(args[3]) else {
    FileHandle.standardError.write(Data("usage: Templateize.swift <in.png> <outBase> <pointSize>\n".utf8))
    exit(1)
}

guard let data = FileManager.default.contents(atPath: args[1]),
      let src = NSBitmapImageRep(data: data),
      let cg = src.cgImage else {
    FileHandle.standardError.write(Data("cannot read \(args[1])\n".utf8))
    exit(1)
}

let w = cg.width, h = cg.height
var px = [UInt8](repeating: 0, count: w * h * 4)
let ctx = CGContext(
    data: &px, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
    space: CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
)!
ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))

// alpha = darkness (white → 0, black → 255); color = black, premultiplied.
for p in 0..<(w * h) {
    let i = p * 4
    let lum = 0.299 * Double(px[i]) + 0.587 * Double(px[i + 1]) + 0.114 * Double(px[i + 2])
    let a = UInt8(max(0, min(255, 255.0 - lum)))
    px[i] = 0; px[i + 1] = 0; px[i + 2] = 0; px[i + 3] = a
}

// Bounding box of meaningful alpha.
var minX = w, minY = h, maxX = -1, maxY = -1
for y in 0..<h {
    for x in 0..<w where px[(y * w + x) * 4 + 3] > 24 {
        if x < minX { minX = x }
        if x > maxX { maxX = x }
        if y < minY { minY = y }
        if y > maxY { maxY = y }
    }
}
guard maxX >= minX else { FileHandle.standardError.write(Data("blank image\n".utf8)); exit(1) }
let boxW = maxX - minX + 1, boxH = maxY - minY + 1
let side = max(boxW, boxH)

guard let full = ctx.makeImage(),
      let cropped = full.cropping(to: CGRect(x: minX, y: minY, width: boxW, height: boxH)) else { exit(1) }

for (suffix, sizePx) in [("", pt), ("@2x", pt * 2)] {
    let out = CGContext(
        data: nil, width: sizePx, height: sizePx, bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
    out.interpolationQuality = .high
    let scale = CGFloat(sizePx) / CGFloat(side)
    let dw = CGFloat(boxW) * scale, dh = CGFloat(boxH) * scale
    out.draw(cropped, in: CGRect(x: (CGFloat(sizePx) - dw) / 2, y: (CGFloat(sizePx) - dh) / 2, width: dw, height: dh))
    guard let outCG = out.makeImage() else { exit(1) }
    let rep = NSBitmapImageRep(cgImage: outCG)
    guard let png = rep.representation(using: .png, properties: [:]) else { exit(1) }
    let path = "\(args[2])\(suffix).png"
    try? png.write(to: URL(fileURLWithPath: path))
    print("wrote \(path) (\(sizePx)px)")
}
