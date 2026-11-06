import Foundation

public struct Vo2Rating: Equatable {
    /// 0 Poor ... 4 Superior
    public var level: Int
    public var name: String
    /// Age band label, e.g. "40–49".
    public var band: String
    /// Value that reaches the next rating, nil at Superior.
    public var nextAt: Double?
    public var nextName: String?
    /// The four thresholds of the band, so a view can draw the scale.
    public var cuts: [Double]
}

extension Engine {
    /// Where a VO2 max sits for someone of this age and sex (Cooper Institute norms).
    /// Ages outside 20-79 use the nearest band. Nil when the sex is unknown.
    public static func vo2Rating(_ vo2: Double, age: Double, gender: String?) -> Vo2Rating? {
        guard let gender else { return nil }
        let table = gender == "female" ? Config.Vo2Norms.female : Config.Vo2Norms.male
        let band = min(table.count - 1, max(0, Int(age / 10) - 2))
        let cuts = table[band]
        let level = cuts.filter { vo2 >= $0 }.count
        let names = Config.Vo2Norms.ratings
        return Vo2Rating(level: level, name: names[level], band: "\(20 + band * 10)–\(29 + band * 10)",
                         nextAt: level < cuts.count ? cuts[level] : nil,
                         nextName: level < cuts.count ? names[level + 1] : nil, cuts: cuts)
    }

    /// The age used for heart-rate maths, or the default when none was set.
    public var ageForNorms: Double { (db.age ?? 0) != 0 ? db.age! : Config.defaultAge }
}
