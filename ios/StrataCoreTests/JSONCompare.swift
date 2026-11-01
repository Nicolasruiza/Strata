import Foundation

/// Structural JSON equality for golden tests: numbers compare as doubles, `null` and a
/// missing key are the same thing (the web drops `undefined`, Swift drops `nil`).
enum JSONCompare {
    static func normalize(_ v: Any?) -> Any? {
        switch v {
        case nil, is NSNull: return nil
        case let n as NSNumber:
            if CFGetTypeID(n) == CFBooleanGetTypeID() { return n.boolValue }
            return n.doubleValue
        case let d as [String: Any]:
            var out: [String: Any] = [:]
            for (k, x) in d { if let nx = normalize(x) { out[k] = nx } }
            return out
        case let a as [Any]: return a.map { normalize($0) ?? NSNull() }
        default: return v
        }
    }

    /// The path of the first difference, or nil when equal.
    static func diff(_ a: Any?, _ b: Any?, path: String = "$") -> String? {
        let x = normalize(a), y = normalize(b)
        switch (x, y) {
        case (nil, nil): return nil
        case (let p as Bool, let q as Bool): return p == q ? nil : "\(path): \(p) != \(q)"
        case (let p as Double, let q as Double): return p == q ? nil : "\(path): \(p) != \(q)"
        case (let p as String, let q as String): return p == q ? nil : "\(path): \"\(p)\" != \"\(q)\""
        case (let p as [Any], let q as [Any]):
            if p.count != q.count { return "\(path): array length \(p.count) != \(q.count)" }
            for i in p.indices { if let d = diff(p[i], q[i], path: "\(path)[\(i)]") { return d } }
            return nil
        case (let p as [String: Any], let q as [String: Any]):
            for k in Set(p.keys).union(q.keys).sorted() {
                if let d = diff(p[k], q[k], path: "\(path).\(k)") { return d }
            }
            return nil
        default: return "\(path): \(String(describing: x)) != \(String(describing: y))"
        }
    }

    static func object<T: Encodable>(_ v: T) -> Any? {
        guard let data = try? JSONEncoder().encode(v) else { return nil }
        return try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
    }

    static func decode<T: Decodable>(_ type: T.Type, from any: Any) throws -> T {
        let data = try JSONSerialization.data(withJSONObject: any, options: [.fragmentsAllowed])
        return try JSONDecoder().decode(T.self, from: data)
    }
}
