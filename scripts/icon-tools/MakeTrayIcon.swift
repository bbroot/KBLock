// MakeTrayIcon.swift — renders LockIME's menu-bar (tray) template glyphs:
// a keyboard with a small padlock badge at the top-right corner. Locked shows
// a closed shackle; unlocked pops the shackle open. Drawn vector-crisp with
// CoreGraphics at 1x/2x — solid black + alpha, for template rendering.
//
//   swift scripts/icon-tools/MakeTrayIcon.swift <outDir>
//   → tray-locked.png/tray-locked@2x.png/tray-unlocked.png/tray-unlocked@2x.png

import AppKit
import CoreGraphics

let outDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."
let pt: CGFloat = 18

func draw(locked: Bool, scale: CGFloat) -> CGImage? {
    let px = Int(pt * scale)
    guard let ctx = CGContext(
        data: nil, width: px, height: px, bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { return nil }
    ctx.scaleBy(x: scale, y: scale)
    ctx.setFillColor(.black)
    ctx.setStrokeColor(.black)

    // — Keyboard: a wide rounded rect in the lower ~2/3, outline + key dots.
    let kb = CGRect(x: 0.75, y: 0.75, width: 16.5, height: 10.5)
    ctx.setLineWidth(1.5)
    ctx.addPath(CGPath(roundedRect: kb, cornerWidth: 2.1, cornerHeight: 2.1, transform: nil))
    ctx.strokePath()

    // Key dots: two rows of five.
    let dotR: CGFloat = 0.8
    for (rowIdx, y) in [CGFloat(8.0), 5.55].enumerated() {
        for i in 0..<5 {
            let x = 3.3 + CGFloat(i) * 2.85 + (rowIdx == 1 ? 0.7 : 0)
            ctx.fillEllipse(in: CGRect(x: x - dotR, y: y - dotR, width: dotR * 2, height: dotR * 2))
        }
    }
    // Space bar.
    let space = CGRect(x: 5.4, y: 2.45, width: 7.2, height: 1.5)
    ctx.addPath(CGPath(roundedRect: space, cornerWidth: 0.75, cornerHeight: 0.75, transform: nil))
    ctx.fillPath()

    // — Badge knockout: clear a halo behind the padlock so it reads as a badge.
    let bodyRect = CGRect(x: 11.4, y: 9.6, width: 5.4, height: 4.6)
    let badgeBounds = CGRect(x: 10.2, y: 8.4, width: 7.8, height: 9.4)
    ctx.setBlendMode(.clear)
    ctx.addPath(CGPath(roundedRect: badgeBounds, cornerWidth: 2.6, cornerHeight: 2.6, transform: nil))
    ctx.fillPath()
    ctx.setBlendMode(.normal)

    // — Padlock body.
    ctx.addPath(CGPath(roundedRect: bodyRect, cornerWidth: 1.2, cornerHeight: 1.2, transform: nil))
    ctx.fillPath()

    // — Shackle: closed = ∩ arch seated on the body; open = right leg free,
    //   arch swung up-right leaving a clear gap.
    ctx.setLineWidth(1.35)
    ctx.setLineCap(.round)
    let cx = bodyRect.midX
    let r: CGFloat = 1.75
    let bodyTop = bodyRect.maxY
    if locked {
        let archY = bodyTop + 1.1
        ctx.beginPath()
        ctx.move(to: CGPoint(x: cx - r, y: bodyTop - 0.4))
        ctx.addLine(to: CGPoint(x: cx - r, y: archY))
        ctx.addArc(center: CGPoint(x: cx, y: archY), radius: r,
                   startAngle: .pi, endAngle: 0, clockwise: true)
        ctx.addLine(to: CGPoint(x: cx + r, y: bodyTop - 0.4))
        ctx.strokePath()
    } else {
        // Hinged at the left leg, swung open ~35° to the right.
        let archY = bodyTop + 1.1
        ctx.saveGState()
        ctx.translateBy(x: cx - r, y: bodyTop - 0.2)
        ctx.rotate(by: 35 * .pi / 180)
        ctx.translateBy(x: -(cx - r), y: -(bodyTop - 0.2))
        ctx.beginPath()
        ctx.move(to: CGPoint(x: cx - r, y: bodyTop - 0.4))
        ctx.addLine(to: CGPoint(x: cx - r, y: archY))
        ctx.addArc(center: CGPoint(x: cx, y: archY), radius: r,
                   startAngle: .pi, endAngle: 0, clockwise: true)
        ctx.addLine(to: CGPoint(x: cx + r, y: archY - 0.2))
        ctx.strokePath()
        ctx.restoreGState()
    }

    return ctx.makeImage()
}

for locked in [true, false] {
    for scale in [CGFloat(1), 2] {
        guard let img = draw(locked: locked, scale: scale) else { continue }
        let rep = NSBitmapImageRep(cgImage: img)
        guard let png = rep.representation(using: .png, properties: [:]) else { continue }
        let name = "tray-\(locked ? "locked" : "unlocked")\(scale == 2 ? "@2x" : "").png"
        let path = "\(outDir)/\(name)"
        try? png.write(to: URL(fileURLWithPath: path))
        print("wrote \(path)")
    }
}
