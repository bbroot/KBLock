// TrimAlpha.swift — crop a PNG to its non-transparent bounding box, pad to a
// centered square, and write it downscaled.
//
//   swift TrimAlpha.swift <in.png> <out.png> <outSize>

import AppKit
import CoreGraphics

let args = CommandLine.arguments
guard args.count == 4, let outSize = Int(args[3]) else {
    FileHandle.standardError.write(Data("usage: TrimAlpha.swift <in.png> <out.png> <outSize>\n".utf8))
    exit(1)
}

guard let data = FileManager.default.contents(atPath: args[1]),
      let src = NSBitmapImageRep(data: data),
      let cg = src.cgImage else {
    FileHandle.standardError.write(Data("cannot read \(args[1])\n".utf8))
    exit(1)
}

let w = cg.width, h = cg.height
var pixels = [UInt8](repeating: 0, count: w * h * 4)
let ctx = CGContext(
    data: &pixels, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
    space: CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
)!
ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))

var minX = w, minY = h, maxX = -1, maxY = -1
for y in 0..<h {
    for x in 0..<w where pixels[(y * w + x) * 4 + 3] > 8 {
        if x < minX { minX = x }
        if x > maxX { maxX = x }
        if y < minY { minY = y }
        if y > maxY { maxY = y }
    }
}
guard maxX >= minX, maxY >= minY else {
    FileHandle.standardError.write(Data("image is fully transparent\n".utf8))
    exit(1)
}

let boxW = maxX - minX + 1, boxH = maxY - minY + 1
let side = max(boxW, boxH)
guard let cropped = cg.cropping(to: CGRect(x: minX, y: minY, width: boxW, height: boxH)) else { exit(1) }

let outCtx = CGContext(
    data: nil, width: outSize, height: outSize, bitsPerComponent: 8, bytesPerRow: 0,
    space: CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
)!
outCtx.interpolationQuality = .high
let scale = CGFloat(outSize) / CGFloat(side)
let drawW = CGFloat(boxW) * scale, drawH = CGFloat(boxH) * scale
outCtx.draw(cropped, in: CGRect(
    x: (CGFloat(outSize) - drawW) / 2, y: (CGFloat(outSize) - drawH) / 2,
    width: drawW, height: drawH
))
guard let outCG = outCtx.makeImage() else { exit(1) }
let rep = NSBitmapImageRep(cgImage: outCG)
guard let png = rep.representation(using: .png, properties: [:]) else { exit(1) }
try? png.write(to: URL(fileURLWithPath: args[2]))
print("trimmed \(boxW)x\(boxH) -> \(outSize)x\(outSize): \(args[2])")
