import Foundation

/// A tiny order-preserving JSON reader/writer. Foundation's decoder and encoder do not
/// promise to keep object key order, but `Object.keys(entries)` order is user-visible on
/// the web (the order lifts were logged in), so load and save go through this.
indirect enum OJ {
    case obj([(key: String, raw: String, val: OJ)])
    case arr([OJ])
    case raw(String)               // number, string, true, false, null: kept as source text

    subscript(key: String) -> OJ? {
        if case .obj(let kv) = self { return kv.first { $0.key == key }?.val }
        return nil
    }
    var keys: [String] {
        if case .obj(let kv) = self { return kv.map(\.key) }
        return []
    }
    var items: [OJ] {
        if case .arr(let a) = self { return a }
        return []
    }
}

enum OJParser {
    struct Fail: Error {}

    static func parse(_ data: Data) throws -> OJ {
        let b = [UInt8](data)
        var i = 0
        let v = try value(b, &i)
        return v
    }

    private static func ws(_ b: [UInt8], _ i: inout Int) {
        while i < b.count, b[i] == 0x20 || b[i] == 0x0A || b[i] == 0x0D || b[i] == 0x09 { i += 1 }
    }

    private static func value(_ b: [UInt8], _ i: inout Int) throws -> OJ {
        ws(b, &i)
        guard i < b.count else { throw Fail() }
        switch b[i] {
        case UInt8(ascii: "{"):
            i += 1
            var kv: [(key: String, raw: String, val: OJ)] = []
            ws(b, &i)
            if i < b.count, b[i] == UInt8(ascii: "}") { i += 1; return .obj(kv) }
            while true {
                ws(b, &i)
                let (raw, key) = try string(b, &i)
                ws(b, &i)
                guard i < b.count, b[i] == UInt8(ascii: ":") else { throw Fail() }
                i += 1
                kv.append((key, raw, try value(b, &i)))
                ws(b, &i)
                guard i < b.count else { throw Fail() }
                if b[i] == UInt8(ascii: ",") { i += 1; continue }
                if b[i] == UInt8(ascii: "}") { i += 1; return .obj(kv) }
                throw Fail()
            }
        case UInt8(ascii: "["):
            i += 1
            var a: [OJ] = []
            ws(b, &i)
            if i < b.count, b[i] == UInt8(ascii: "]") { i += 1; return .arr(a) }
            while true {
                a.append(try value(b, &i))
                ws(b, &i)
                guard i < b.count else { throw Fail() }
                if b[i] == UInt8(ascii: ",") { i += 1; continue }
                if b[i] == UInt8(ascii: "]") { i += 1; return .arr(a) }
                throw Fail()
            }
        case UInt8(ascii: "\""):
            let (raw, _) = try string(b, &i)
            return .raw(raw)
        default:
            let s = i
            while i < b.count, !",]} \n\r\t".utf8.contains(b[i]) { i += 1 }
            guard i > s else { throw Fail() }
            return .raw(String(decoding: b[s..<i], as: UTF8.self))
        }
    }

    /// Returns the raw source text (with quotes) and the decoded string.
    private static func string(_ b: [UInt8], _ i: inout Int) throws -> (String, String) {
        guard i < b.count, b[i] == UInt8(ascii: "\"") else { throw Fail() }
        let s = i
        i += 1
        while i < b.count, b[i] != UInt8(ascii: "\"") {
            if b[i] == UInt8(ascii: "\\") { i += 1 }
            i += 1
        }
        guard i < b.count else { throw Fail() }
        i += 1
        let raw = String(decoding: b[s..<i], as: UTF8.self)
        let decoded = (try? JSONDecoder().decode(String.self, from: Data(raw.utf8))) ?? raw
        return (raw, decoded)
    }

    static func write(_ v: OJ) -> String {
        switch v {
        case .raw(let s): return s
        case .arr(let a): return "[" + a.map(write).joined(separator: ",") + "]"
        case .obj(let kv): return "{" + kv.map { $0.raw + ":" + write($0.val) }.joined(separator: ",") + "}"
        }
    }
}

extension AppData {
    /// Decode a web/iOS JSON document, restoring the key order of every `entries` object.
    public static func load(from data: Data) throws -> AppData {
        var db = try JSONDecoder().decode(AppData.self, from: data)
        if let root = try? OJParser.parse(data) {
            if let h = root["history"] {
                for (i, s) in h.items.enumerated() where i < db.history.count {
                    if let e = s["entries"] { db.history[i].entries.reorder(e.keys) }
                }
            }
            if let e = root["active"]?["entries"] { db.active?.entries.reorder(e.keys) }
        }
        return db
    }

    /// Encode with `entries` in logged order. Everything else is key-sorted, which the web ignores.
    public func jsonData() throws -> Data {
        let enc = JSONEncoder()
        enc.outputFormatting = [.sortedKeys]
        let sorted = try enc.encode(self)
        guard case .obj(var top) = try OJParser.parse(sorted) else { return sorted }

        func reorder(_ node: OJ, _ order: [String]) -> OJ {
            guard case .obj(let kv) = node else { return node }
            var out: [(key: String, raw: String, val: OJ)] = []
            for k in order { if let e = kv.first(where: { $0.key == k }) { out.append(e) } }
            return .obj(out)
        }
        for (ti, e) in top.enumerated() {
            if e.key == "history", case .arr(var arr) = e.val {
                for (i, s) in arr.enumerated() where i < history.count {
                    guard case .obj(var f) = s else { continue }
                    for (fi, fe) in f.enumerated() where fe.key == "entries" {
                        f[fi].val = reorder(fe.val, history[i].entries.keys)
                    }
                    arr[i] = .obj(f)
                }
                top[ti].val = .arr(arr)
            } else if e.key == "active", let a = active, case .obj(var f) = e.val {
                for (fi, fe) in f.enumerated() where fe.key == "entries" {
                    f[fi].val = reorder(fe.val, a.entries.keys)
                }
                top[ti].val = .obj(f)
            }
        }
        return Data(OJParser.write(.obj(top)).utf8)
    }
}
