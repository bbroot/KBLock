// RemoveBackground.swift — chroma-key a flat-color background off a hero image
// by flood-filling from the borders, with alpha feathering + de-spill at the
// boundary so the character keeps crisp, fringe-free edges. Enclosed regions
// (e.g. glyphs printed on the keyboard) are untouched by design.
//
//   swift RemoveBackground.swift <in.png> <out.png>

import AppKit
import CoreGraphics

let args = CommandLine.arguments
guard args.count >= 3 else {
    FileHandle.standardError.write(Data("usage: RemoveBackground.swift <in.png> <out.png> [edge|blue]\n".utf8))
    exit(1)
}
// edge: only edge-connected background (protects bg-like enclosed art, e.g.
//       navy glyphs printed on the keyboard).
// blue: additionally strip blue-dominant pixels (enclosed holes + painted
//       ground shadows); safe only when the artwork itself has no blues.
let mode = args.count > 3 ? args[3] : "edge"

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

// Background color: average the four 8×8 corner patches.
var br = 0.0, bg = 0.0, bb = 0.0, n = 0.0
for (cx, cy) in [(0, 0), (w - 8, 0), (0, h - 8), (w - 8, h - 8)] {
    for y in cy..<(cy + 8) {
        for x in cx..<(cx + 8) {
            let i = (y * w + x) * 4
            br += Double(px[i]); bg += Double(px[i + 1]); bb += Double(px[i + 2]); n += 1
        }
    }
}
br /= n; bg /= n; bb /= n

func dist(_ i: Int) -> Double {
    let dr = Double(px[i]) - br, dg = Double(px[i + 1]) - bg, db = Double(px[i + 2]) - bb
    return (dr * dr + dg * dg + db * db).squareRoot()
}

// Flood fill from every border pixel: tolerance generous enough to cross the
// slight background gradient but far below the character's palette distance.
let tol = 90.0
var isBG = [Bool](repeating: false, count: w * h)
var queue = [Int]()
for x in 0..<w { queue.append(x); queue.append((h - 1) * w + x) }
for y in 0..<h { queue.append(y * w); queue.append(y * w + w - 1) }
for q in queue where dist(q * 4) < tol { isBG[q] = true }
queue = queue.filter { isBG[$0] }
var head = 0
while head < queue.count {
    let p = queue[head]; head += 1
    let x = p % w, y = p / w
    for (nx, ny) in [(x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)] {
        guard nx >= 0, nx < w, ny >= 0, ny < h else { continue }
        let np = ny * w + nx
        if !isBG[np] && dist(np * 4) < tol { isBG[np] = true; queue.append(np) }
    }
}

if mode == "blue" {
    // Enclosed holes and painted blue ground shadows: anything decisively
    // blue-dominant is background. Orange fur, white, greens and near-blacks
    // all fail this test.
    for p in 0..<(w * h) where !isBG[p] {
        let i = p * 4
        let r = Double(px[i]), g = Double(px[i + 1]), b = Double(px[i + 2])
        if b > 80, b > r * 1.3, b > g * 1.3 { isBG[p] = true }
    }
}

// Feather + de-spill: any non-BG pixel touching the removed region gets an
// alpha from its distance to the bg color, and its color un-mixed from bg.
let lo = 30.0, hi = 170.0
for y in 0..<h {
    for x in 0..<w {
        let p = y * w + x
        let i = p * 4
        if isBG[p] {
            px[i] = 0; px[i + 1] = 0; px[i + 2] = 0; px[i + 3] = 0
            continue
        }
        var nearBG = false
        outer: for dy in -2...2 {
            for dx in -2...2 {
                let nx = x + dx, ny = y + dy
                guard nx >= 0, nx < w, ny >= 0, ny < h else { continue }
                if isBG[ny * w + nx] { nearBG = true; break outer }
            }
        }
        guard nearBG else { continue }
        let d = dist(i)
        let a = max(0.0, min(1.0, (d - lo) / (hi - lo)))
        if a >= 0.999 { continue }
        if a <= 0.001 {
            px[i] = 0; px[i + 1] = 0; px[i + 2] = 0; px[i + 3] = 0
            continue
        }
        // Un-mix: observed = a*true + (1-a)*bg  →  true = (observed-(1-a)*bg)/a
        func unmix(_ c: UInt8, _ b: Double) -> UInt8 {
            UInt8(max(0, min(255, (Double(c) - (1 - a) * b) / a)))
        }
        let tr = unmix(px[i], br), tg = unmix(px[i + 1], bg), tb = unmix(px[i + 2], bb)
        // Store premultiplied by the new alpha.
        px[i] = UInt8(Double(tr) * a)
        px[i + 1] = UInt8(Double(tg) * a)
        px[i + 2] = UInt8(Double(tb) * a)
        px[i + 3] = UInt8(a * 255)
    }
}

guard let outCG = ctx.makeImage() else { exit(1) }
let rep = NSBitmapImageRep(cgImage: outCG)
guard let png = rep.representation(using: .png, properties: [:]) else { exit(1) }
try? png.write(to: URL(fileURLWithPath: args[2]))
let removed = isBG.filter { $0 }.count
print("removed \(removed * 100 / (w * h))% as background: \(args[2])")
