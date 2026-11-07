import Foundation

/// app.js / core.js text helpers, copy-for-copy.
public enum Fmt {
    /// `cleanN`: drops "(per leg)" style asides.
    public static func cleanN(_ n: String) -> String {
        let re = try! NSRegularExpression(pattern: "\\s*\\(.*?\\)\\s*")
        let r = NSRange(n.startIndex..., in: n)
        return re.stringByReplacingMatches(in: n, range: r, withTemplate: " ").trimmingCharacters(in: .whitespacesAndNewlines)
    }
    public static func isSec(_ ex: Ex) -> Bool { ex.n.range(of: "second", options: .caseInsensitive) != nil }
    public static func perLeg(_ ex: Ex) -> String {
        if ex.n.range(of: "per leg", options: .caseInsensitive) != nil { return " / leg" }
        if ex.n.range(of: "per side", options: .caseInsensitive) != nil { return " / side" }
        return ""
    }
    /// `wLbl`: "45 lb", "30 lb each", "50 lb / hand" or "bodyweight".
    public static func wLbl(_ ex: Ex, _ w: Double) -> String {
        if ex.isBodyweight && w == 0 { return "bodyweight" }
        var s = "\(jsNum(w)) lb"
        if ex.isEach {
            s += ex.n.range(of: "farmer|carry", options: [.regularExpression, .caseInsensitive]) != nil ? " / hand" : " each"
        }
        return s
    }
    /// `repLbl`: a missing rep prints as "null", as the web's template literal does.
    public static func repLbl(_ ex: Ex, _ r: Double?) -> String {
        let v = r.map(jsNum) ?? "null"
        return isSec(ex) ? "\(v) s" : v
    }
    public static func mmss(_ s: Double) -> String {
        let m = (s / 60).rounded(.down)
        let sec = max(0, s.truncatingRemainder(dividingBy: 60).rounded(.down))
        return "\(jsNum(m)):\(sec < 10 ? "0" : "")\(jsNum(sec))"
    }
    /// `nf`: rounded, with en-US thousands separators.
    public static func nf(_ n: Double) -> String {
        let r = Int64(jsRound(n))
        var s = String(abs(r)), out = ""
        while s.count > 3 { out = "," + s.suffix(3) + out; s = String(s.dropLast(3)) }
        return (r < 0 ? "-" : "") + s + out
    }
    /// `Number.prototype.toFixed`
    public static func fmtFixed(_ v: Double, _ digits: Int) -> String { jsFixed(v, digits) }
    public static func fmtSets(_ v: Double) -> String { v == v.rounded() ? jsNum(v) : jsFixed(v, 1) }

    /// `plateTxt`: "45 lb bar + 25 + 10 / side".
    public static func plateTxt(_ ex: Ex, _ total: Double) -> String {
        let bar = ex.bar ?? 0
        if total <= bar { return "\(jsNum(bar)) lb bar only" }
        var side = (total - bar) / 2
        var out: [String] = []
        for p in Catalog.shared.plates {
            while side >= p - 0.001 { out.append(jsNum(p)); side = Double(jsFixed(side - p, 2)) ?? 0 }
        }
        return "\(jsNum(bar)) lb bar + \(out.joined(separator: " + ")) / side"
    }

    /// `sledTxt`: leg press. The weight is the plates on the sled (not counting the sled), split evenly:
    /// "45 + 45 / side (plates only)".
    public static func sledTxt(_ total: Double) -> String {
        guard total > 0 else { return "Empty sled" }
        var side = total / 2
        var out: [String] = []
        for p in Catalog.shared.plates {
            while side >= p - 0.001 { out.append(jsNum(p)); side = Double(jsFixed(side - p, 2)) ?? 0 }
        }
        return "\(out.joined(separator: " + ")) / side (plates only)" + (side > 0.001 ? " · +\(jsNum(side)) short" : "")
    }

    /// `ytURL`: YouTube search for the form video. `qmapKey` is "nr" or "sa".
    public static func formVideoURL(id: String, name: String, qmapKey: String) -> String {
        let cat = Catalog.shared
        let q = cat.qmap[qmapKey]?[id] ?? cat.rcQ[id] ?? name + " proper form"
        return "https://www.youtube.com/results?search_query=" + encodeURIComponent(q)
    }

    /// `encodeURIComponent`
    static func encodeURIComponent(_ s: String) -> String {
        var allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.!~*'()")
        allowed.remove(charactersIn: "")
        return s.addingPercentEncoding(withAllowedCharacters: allowed) ?? s
    }
}
