import SwiftUI

/// The web's inline SVG icons ship as path data (`d="…"`). This reads that data so the
/// icons are the same shapes, not look-alikes. Supports M L H V C S A Z (and lowercase).
struct SVGPathShape: Shape {
    let d: String
    /// SVG user-space size the path was drawn in (the web icons use a 24 × 24 viewBox).
    var viewBox: CGSize = CGSize(width: 24, height: 24)

    func path(in rect: CGRect) -> Path {
        var parser = SVGParser(d)
        var p = parser.parse()
        let s = min(rect.width / viewBox.width, rect.height / viewBox.height)
        let dx = rect.minX + (rect.width - viewBox.width * s) / 2, dy = rect.minY + (rect.height - viewBox.height * s) / 2
        p = p.applying(CGAffineTransform(scaleX: s, y: s)).applying(CGAffineTransform(translationX: dx, y: dy))
        return p
    }
}

private struct SVGParser {
    let chars: [Character]
    var i = 0
    init(_ d: String) { chars = Array(d) }

    mutating func parse() -> Path {
        var path = Path()
        var cur = CGPoint.zero, start = CGPoint.zero, lastCtl: CGPoint?
        var cmd: Character = "M"
        while true {
            skipSep()
            if i >= chars.count { break }
            if chars[i].isLetter { cmd = chars[i]; i += 1 }
            let rel = cmd.isLowercase
            switch cmd.uppercased().first! {
            case "M":
                let p = point(rel, cur)
                path.move(to: p); cur = p; start = p; lastCtl = nil
                cmd = rel ? "l" : "L"
            case "L":
                let p = point(rel, cur); path.addLine(to: p); cur = p; lastCtl = nil
            case "H":
                let x = number(); let p = CGPoint(x: rel ? cur.x + x : x, y: cur.y); path.addLine(to: p); cur = p; lastCtl = nil
            case "V":
                let y = number(); let p = CGPoint(x: cur.x, y: rel ? cur.y + y : y); path.addLine(to: p); cur = p; lastCtl = nil
            case "C":
                let c1 = point(rel, cur), c2 = point(rel, cur), p = point(rel, cur)
                path.addCurve(to: p, control1: c1, control2: c2); cur = p; lastCtl = c2
            case "S":
                let c1 = lastCtl.map { CGPoint(x: 2 * cur.x - $0.x, y: 2 * cur.y - $0.y) } ?? cur
                let c2 = point(rel, cur), p = point(rel, cur)
                path.addCurve(to: p, control1: c1, control2: c2); cur = p; lastCtl = c2
            case "A":
                let rx = number(), ry = number(), rot = number()
                let large = flag(), sweep = flag()
                let p = point(rel, cur)
                SVGParser.arc(&path, from: cur, to: p, rx: rx, ry: ry, rotation: rot, large: large, sweep: sweep)
                cur = p; lastCtl = nil
            case "Z":
                path.closeSubpath(); cur = start; lastCtl = nil
            default: return path
            }
        }
        return path
    }

    mutating func skipSep() { while i < chars.count, chars[i] == " " || chars[i] == "," || chars[i] == "\n" { i += 1 } }

    mutating func number() -> CGFloat {
        skipSep()
        var s = ""
        if i < chars.count, chars[i] == "-" || chars[i] == "+" { s.append(chars[i]); i += 1 }
        var dot = false
        while i < chars.count {
            let c = chars[i]
            if c.isNumber { s.append(c); i += 1 }
            else if c == ".", !dot { dot = true; s.append(c); i += 1 }
            else { break }
        }
        return CGFloat(Double(s) ?? 0)
    }
    mutating func flag() -> Bool { skipSep(); let c = chars[i]; i += 1; return c == "1" }
    mutating func point(_ rel: Bool, _ cur: CGPoint) -> CGPoint {
        let x = number(), y = number()
        return rel ? CGPoint(x: cur.x + x, y: cur.y + y) : CGPoint(x: x, y: y)
    }

    /// SVG endpoint arc → cubic Béziers (SVG 1.1 implementation notes, F.6).
    static func arc(_ path: inout Path, from p0: CGPoint, to p1: CGPoint, rx rx0: CGFloat, ry ry0: CGFloat, rotation: CGFloat, large: Bool, sweep: Bool) {
        var rx = abs(rx0), ry = abs(ry0)
        if rx == 0 || ry == 0 || p0 == p1 { path.addLine(to: p1); return }
        let phi = rotation * .pi / 180, cp = cos(phi), sp = sin(phi)
        let dx = (p0.x - p1.x) / 2, dy = (p0.y - p1.y) / 2
        let x1 = cp * dx + sp * dy, y1 = -sp * dx + cp * dy
        let lam = (x1 * x1) / (rx * rx) + (y1 * y1) / (ry * ry)
        if lam > 1 { rx *= sqrt(lam); ry *= sqrt(lam) }
        let num = rx * rx * ry * ry - rx * rx * y1 * y1 - ry * ry * x1 * x1
        let den = rx * rx * y1 * y1 + ry * ry * x1 * x1
        var co = sqrt(max(0, num / den))
        if large == sweep { co = -co }
        let cxp = co * rx * y1 / ry, cyp = -co * ry * x1 / rx
        let cx = cp * cxp - sp * cyp + (p0.x + p1.x) / 2, cy = sp * cxp + cp * cyp + (p0.y + p1.y) / 2
        func ang(_ ux: CGFloat, _ uy: CGFloat, _ vx: CGFloat, _ vy: CGFloat) -> CGFloat {
            let a = atan2(ux * vy - uy * vx, ux * vx + uy * vy); return a
        }
        let th1 = ang(1, 0, (x1 - cxp) / rx, (y1 - cyp) / ry)
        var dth = ang((x1 - cxp) / rx, (y1 - cyp) / ry, (-x1 - cxp) / rx, (-y1 - cyp) / ry)
        if !sweep && dth > 0 { dth -= 2 * .pi } else if sweep && dth < 0 { dth += 2 * .pi }
        let n = Int(ceil(abs(dth) / (.pi / 2)))
        let step = dth / CGFloat(n), t = 4 / 3 * tan(step / 4)
        var a = th1
        for _ in 0..<n {
            let a2 = a + step
            func pt(_ ang: CGFloat, _ k: CGFloat, _ off: CGFloat) -> CGPoint {
                let ex = rx * (cos(ang) - k * sin(ang)), ey = ry * (sin(ang) + k * cos(ang))
                return CGPoint(x: cp * ex - sp * ey + cx, y: sp * ex + cp * ey + cy)
            }
            path.addCurve(to: pt(a2, 0, 0), control1: pt(a, t, 0), control2: pt(a2, -t, 0))
            a = a2
        }
    }
}

/// The icon set (app.js `I`, workout.js `WIC`) as path data, copied from the web source.
enum Icon {
    static let dumbbell = "M6.5 6.5v11M17.5 6.5v11M6.5 12h11M3.5 9v6M20.5 9v6"
    static let heart = "M12 20s-7.5-4.6-7.5-10A4.3 4.3 0 0 1 12 7.4 4.3 4.3 0 0 1 19.5 10c0 5.4-7.5 10-7.5 10z"
    static let bone = "M8 16l8-8M7.2 17.8a2.2 2.2 0 1 1-2.6-2.9 2.2 2.2 0 1 1 3.4-1.9M16.8 6.2a2.2 2.2 0 1 1 2.6 2.9 2.2 2.2 0 1 1-3.4 1.9"
    static let walk = "M10 21l2.5-6 2.5 2v4M8 12l2-4.5 3.5 1.5 2 3.5 2.5 1M11 8.5l-1.5 6.5"
    static let check = "M5 12.5l4.5 4.5L19 7.5"
    static let chev = "M9 5l7 7-7 7"
    static let home = "M4 11l8-6.5 8 6.5V20h-5.5v-5.5h-5V20H4z"
}

/// A stroked icon at a given size.
struct IconView: View {
    let d: String
    var size: CGFloat = 20
    var color: Color = .white
    var line: CGFloat = 2.2
    var body: some View {
        SVGPathShape(d: d)
            .stroke(color, style: StrokeStyle(lineWidth: line * size / 24, lineCap: .round, lineJoin: .round))
            .frame(width: size, height: size)
    }
}

/// The Strata mark (`I.logo`, viewBox 26 × 22).
struct LogoMark: View {
    var body: some View {
        ZStack {
            SVGPathShape(d: "M1 21L11 3l10 18", viewBox: CGSize(width: 26, height: 22))
                .stroke(Color.white, style: StrokeStyle(lineWidth: 2.6, lineJoin: .round))
            SVGPathShape(d: "M8 21l7-12 10 12", viewBox: CGSize(width: 26, height: 22))
                .stroke(Color.white.opacity(0.55), style: StrokeStyle(lineWidth: 2.6, lineJoin: .round))
        }
        .frame(width: 26, height: 22)
    }
}
