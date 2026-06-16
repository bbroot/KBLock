#!/usr/bin/env swift
// GenIcons.swift — Generate KBLock icons using logo/ folder graphics.
// macOS System Settings style: gray-blue gradient background,
// user-provided keyboard-key logo (cropped to content, tinted gray) + lock/unlock icons.
//
// Usage: swift scripts/GenIcons.swift

import AppKit

let logoDir = URL(filePath: "/Users/bbroot/Documents/龙虾/KBLock/logo")
let logoPath   = logoDir.appending(path: "logo.png")
let lockPath   = logoDir.appending(path: "lock.png")
let unlockPath = logoDir.appending(path: "unlock.png")

let assetsDir = URL(filePath: "/Users/bbroot/Documents/龙虾/KBLock/Sources/KBLock/Assets.xcassets")
let appIconDir   = assetsDir.appending(path: "AppIcon.appiconset")
let trayLockDir  = assetsDir.appending(path: "TrayLocked.imageset")
let trayUnlockDir = assetsDir.appending(path: "TrayUnlocked.imageset")

let bgGray  = NSColor(white: 98/255, alpha: 1)

// ── Convenience: crop NSImage to non-transparent bounding box ──
func croppedToContent(_ img: NSImage) -> NSImage {
    guard let cg = img.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
        return img
    }
    let w = cg.width, h = cg.height
    let cs = CGColorSpaceCreateDeviceRGB()
    let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8,
                        bytesPerRow: 0, space: cs,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    let nsCtx = NSGraphicsContext(cgContext: ctx, flipped: false)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = nsCtx
    img.draw(in: CGRect(x: 0, y: 0, width: w, height: h))
    NSGraphicsContext.restoreGraphicsState()

    guard let data = ctx.data else { return img }
    let ptr = data.bindMemory(to: UInt8.self, capacity: w * h * 4)
    var xmin = w, xmax = 0, ymin = h, ymax = 0
    for y in 0..<h {
        for x in 0..<w {
            let a = ptr[(y * w + x) * 4 + 3]
            if a > 10 {
                if x < xmin { xmin = x }
                if x > xmax { xmax = x }
                if y < ymin { ymin = y }
                if y > ymax { ymax = y }
            }
        }
    }
    guard xmin < xmax, ymin < ymax else { return img }
    let cropRect = CGRect(x: xmin, y: ymin, width: xmax - xmin + 1, height: ymax - ymin + 1)
    guard let cropped = cg.cropping(to: cropRect) else { return img }
    return NSImage(cgImage: cropped, size: NSSize(width: cropRect.width, height: cropRect.height))
}

// ── Preload source images ─────────────────────────
guard let logoImgRaw   = NSImage(contentsOf: logoPath),
      let lockImgRaw   = NSImage(contentsOf: lockPath),
      let unlockImgRaw = NSImage(contentsOf: unlockPath) else {
    fputs("ERROR: failed to load one or more logo/ images\n", stderr)
    exit(1)
}

// Crop all to content bounds (remove built-in padding)
let logoImg   = croppedToContent(logoImgRaw)
let lockImg   = croppedToContent(lockImgRaw)
let unlockImg = croppedToContent(unlockImgRaw)

print("Loaded logo: \(logoImgRaw.size) → cropped to \(logoImg.size)")
print("Loaded lock: \(lockImgRaw.size) → cropped to \(lockImg.size)")
print("Loaded unlock: \(unlockImgRaw.size) → cropped to \(unlockImg.size)")

// ── Render helpers ────────────────────────────────
func renderPNG(_ draw: (CGContext, CGRect) -> Void, w: Int, h: Int, to url: URL) {
    let cs = CGColorSpaceCreateDeviceRGB()
    let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8,
                        bytesPerRow: 0, space: cs,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    let nsCtx = NSGraphicsContext(cgContext: ctx, flipped: false)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = nsCtx
    draw(ctx, CGRect(x: 0, y: 0, width: CGFloat(w), height: CGFloat(h)))
    NSGraphicsContext.restoreGraphicsState()
    guard let cgImage = ctx.makeImage() else { fatalError() }
    guard let data = NSBitmapImageRep(cgImage: cgImage)
        .representation(using: .png, properties: [:]) else { fatalError() }
    try! data.write(to: url)
    print("  \(url.lastPathComponent) \(w)×\(h)")
}

func drawBackground(ctx: CGContext, rect: CGRect) {
    // Drop shadow
    let sh = NSShadow()
    sh.shadowColor = NSColor(white: 0, alpha: 0.08)
    sh.shadowBlurRadius = rect.width * 0.015
    sh.shadowOffset = NSSize(width: 0, height: -rect.width * 0.008)
    sh.set()
    // Clip to rounded rect
    let r = rect.width * 0.225
    NSBezierPath(roundedRect: rect, xRadius: r, yRadius: r).addClip()
    // Solid gray fill
    bgGray.set()
    rect.fill()
}

/// Draw `source` centered in `rect`, scaled so shorter side fills `fillRatio`.
/// If `tint` is provided, composite the tint color over the source using sourceAtop.
func drawCentered(source: NSImage, in rect: CGRect, fillRatio: CGFloat, tint: NSColor? = nil) {
    let srcW = source.size.width
    let srcH = source.size.height
    let maxW = rect.width * fillRatio
    let maxH = rect.height * fillRatio
    let scale = min(maxW / srcW, maxH / srcH)
    let dw = srcW * scale
    let dh = srcH * scale
    let dx = rect.midX - dw / 2
    let dy = rect.midY - dh / 2
    let dest = CGRect(x: dx, y: dy, width: dw, height: dh)

    source.draw(in: dest, from: .zero, operation: .sourceOver, fraction: 1)

    // Tint via sourceAtop compositing
    if let tint {
        tint.set()
        dest.fill(using: .sourceAtop)
    }
}

// ════════════════════════════════════════════════════
// 1. App Icon — all sizes (no tint, keep original logo white)
// ════════════════════════════════════════════════════
let appSizes: [(Int, Int, String)] = [
    (1024, 1024, "icon_1024"),
    (512, 512, "icon_512"),
    (256, 256, "icon_256"),
    (128, 128, "icon_128"),
    (64, 64, "icon_64"),
    (32, 32, "icon_32"),
    (16, 16, "icon_16"),
]

for (w, h, name) in appSizes {
    renderPNG({ ctx, rect in
        drawBackground(ctx: ctx, rect: rect)
        drawCentered(source: logoImg, in: rect, fillRatio: 0.92)
    }, w: w, h: h, to: appIconDir.appending(path: name + ".png"))
}

// ════════════════════════════════════════════════════
// 2. Tray icons — lock / unlock (no tint, keep original white)
// ════════════════════════════════════════════════════
struct TrayJob {
    let source: NSImage
    let name: String
    let size: Int
    let dir: URL
}

let trayJobs = [
    TrayJob(source: lockImg,   name: "tray-locked.png",    size: 26, dir: trayLockDir),
    TrayJob(source: lockImg,   name: "tray-locked@2x.png", size: 52, dir: trayLockDir),
    TrayJob(source: unlockImg, name: "tray-unlocked.png",    size: 26, dir: trayUnlockDir),
    TrayJob(source: unlockImg, name: "tray-unlocked@2x.png", size: 52, dir: trayUnlockDir),
]

for job in trayJobs {
    try? FileManager.default.removeItem(at: job.dir.appending(path: job.name))
    renderPNG({ ctx, rect in
        drawCentered(source: job.source, in: rect, fillRatio: 0.92)
    }, w: job.size, h: job.size, to: job.dir.appending(path: job.name))
}

print("\n✅ Done. App icon: solid #626262 bg + original white logo. Tray: unchanged.")
