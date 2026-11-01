import Foundation

/// Calendar-date arithmetic on `YYYY-MM-DD` strings, the way core.js does it (local dates,
/// never UTC). Done on the civil calendar so it can't be bent by the device locale, the
/// first-weekday setting or a DST change. Only `today(nowMs:tz:)` needs a time zone.
public enum Dates {
    static func daysFromCivil(_ y0: Int, _ m: Int, _ d: Int) -> Int {
        let y = m <= 2 ? y0 - 1 : y0
        let era = (y >= 0 ? y : y - 399) / 400
        let yoe = y - era * 400
        let doy = (153 * (m + (m > 2 ? -3 : 9)) + 2) / 5 + d - 1
        let doe = yoe * 365 + yoe / 4 - yoe / 100 + doy
        return era * 146_097 + doe - 719_468
    }

    static func civil(fromDays z0: Int) -> (y: Int, m: Int, d: Int) {
        let z = z0 + 719_468
        let era = (z >= 0 ? z : z - 146_096) / 146_097
        let doe = z - era * 146_097
        let yoe = (doe - doe / 1460 + doe / 36_524 - doe / 146_096) / 365
        let y = yoe + era * 400
        let doy = doe - (365 * yoe + yoe / 4 - yoe / 100)
        let mp = (5 * doy + 2) / 153
        let d = doy - (153 * mp + 2) / 5 + 1
        let m = mp < 10 ? mp + 3 : mp - 9
        return (m <= 2 ? y + 1 : y, m, d)
    }

    static func parse(_ ds: String) -> (y: Int, m: Int, d: Int) {
        let p = ds.split(separator: "-").map { Int($0) ?? 0 }
        return p.count == 3 ? (p[0], p[1], p[2]) : (1970, 1, 1)
    }

    static func format(_ c: (y: Int, m: Int, d: Int)) -> String {
        String(format: "%04d-%02d-%02d", c.y, c.m, c.d)
    }

    static func dayNumber(_ ds: String) -> Int { let c = parse(ds); return daysFromCivil(c.y, c.m, c.d) }

    /// `today()`: the local calendar date at `nowMs`.
    public static func today(nowMs: Double, tz: TimeZone) -> String {
        let off = tz.secondsFromGMT(for: Date(timeIntervalSince1970: nowMs / 1000))
        let localMs = nowMs + Double(off) * 1000
        return format(civil(fromDays: Int((localMs / 86_400_000).rounded(.down))))
    }

    public static func addDays(_ ds: String, _ n: Int) -> String { format(civil(fromDays: dayNumber(ds) + n)) }
    public static func dayDiff(_ a: String, _ b: String) -> Int { dayNumber(b) - dayNumber(a) }

    /// `getDay()`: 0 = Sunday … 6 = Saturday.
    public static func weekday(_ ds: String) -> Int { ((dayNumber(ds) + 4) % 7 + 7) % 7 }

    /// Weeks start on Monday (`mondayOf`).
    public static func mondayOf(_ ds: String) -> String { addDays(ds, -((weekday(ds) + 6) % 7)) }

    public static func weekDates(_ mon: String) -> [String] { (0..<7).map { addDays(mon, $0) } }

    // MARK: fmtD: `toLocaleDateString('en-CA', opts)` for the option sets the app uses

    public enum Style { case short, long }
    public struct FmtOpts: Equatable {
        public var weekday: Style?
        public var month: Style?
        public var day = false
        public var year = false
        public init(weekday: Style? = nil, month: Style? = nil, day: Bool = false, year: Bool = false) {
            self.weekday = weekday; self.month = month; self.day = day; self.year = year
        }
        /// `fmtD`'s default: `{weekday:'short',month:'short',day:'numeric'}`.
        public static let standard = FmtOpts(weekday: .short, month: .short, day: true)
    }

    static let monthsLong = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
    static let weekdaysLong = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

    public static func fmtD(_ ds: String, _ o: FmtOpts = .standard) -> String {
        let c = parse(ds)
        var head: [String] = []
        if let w = o.weekday {
            let name = weekdaysLong[weekday(ds)]
            head.append(w == .long ? name : String(name.prefix(3)))
        }
        var md = ""
        if let m = o.month {
            let name = monthsLong[c.m - 1]
            md = m == .long ? name : String(name.prefix(3))
        }
        if o.day { md += md.isEmpty ? "\(c.d)" : " \(c.d)" }
        if !md.isEmpty { head.append(md) }
        if o.year { head.append("\(c.y)") }
        return head.joined(separator: ", ")
    }
}
