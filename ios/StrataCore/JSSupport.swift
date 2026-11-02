import Foundation

/// `Math.round`: halves go up (−2.5 → −2), unlike Swift's `.rounded()`.
@inline(__always) public func jsRound(_ x: Double) -> Double { (x + 0.5).rounded(.down) }

/// A JS number printed the way a template literal prints it (`45`, `2.5`).
func jsNum(_ d: Double) -> String {
    if d == d.rounded(), abs(d) < 1e15 { return String(Int64(d)) }
    return "\(d)"
}

/// A JS number printed straight from a template literal: `1.0` → "1".
public func jsMinutes(_ v: Double) -> String { jsNum(v) }

/// `Number.prototype.toFixed` for the small values the app uses.
func jsFixed(_ d: Double, _ digits: Int) -> String { String(format: "%.\(digits)f", d) }

extension KeyedDecodingContainer {
    /// JS truthiness for flags that older exports wrote as 0/1.
    func decodeFlexBool(forKey key: Key) throws -> Bool? {
        if let b = try? decodeIfPresent(Bool.self, forKey: key) { return b }
        if let i = try? decodeIfPresent(Int.self, forKey: key) { return i != 0 }
        return nil
    }
}

/// Stable sort (JS `Array.prototype.sort` is stable, Swift's is not guaranteed to be).
extension Array {
    func stableSorted(by areInIncreasingOrder: (Element, Element) -> Bool) -> [Element] {
        enumerated().sorted { a, b in
            if areInIncreasingOrder(a.element, b.element) { return true }
            if areInIncreasingOrder(b.element, a.element) { return false }
            return a.offset < b.offset
        }.map(\.element)
    }
}

/// A string-keyed map that remembers insertion order, because the web reads
/// `Object.keys(entries)` and the order the lifts were logged in is shown to the user.
public struct OrderedDict<V: Codable & Equatable>: Codable, Equatable {
    public private(set) var keys: [String] = []
    private var dict: [String: V] = [:]

    public init() {}

    public subscript(key: String) -> V? {
        get { dict[key] }
        set {
            if let v = newValue {
                if dict[key] == nil { keys.append(key) }
                dict[key] = v
            } else if dict[key] != nil {
                dict[key] = nil
                keys.removeAll { $0 == key }
            }
        }
    }
    public var count: Int { keys.count }
    public var isEmpty: Bool { keys.isEmpty }
    public var values: [V] { keys.compactMap { dict[$0] } }

    public init(from decoder: Decoder) throws {
        let d = try decoder.singleValueContainer().decode([String: V].self)
        dict = d
        keys = d.keys.sorted()      // real order is restored by `reorder` after decoding
    }
    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        try c.encode(dict)
    }
    public mutating func reorder(_ order: [String]) {
        let known = order.filter { dict[$0] != nil }
        keys = known + keys.filter { !known.contains($0) }
    }
}
