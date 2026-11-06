import Foundation

/// Daily Mobility bookkeeping. Optional by design: it never touches rings, streaks or insights.
extension Engine {
    /// Exercise ids checked off for that session on that date.
    public func mobilityChecked(date: String, session: String) -> Set<String> {
        let known = Set(Config.Mobility.exercises.map(\.id))
        return Set((db.mobility ?? []).filter { $0.date == date && $0.session == session && known.contains($0.ex) }.map(\.ex))
    }
    public func mobilityCount(date: String, session: String) -> Int { mobilityChecked(date: date, session: session).count }
    public func mobilitySessionComplete(date: String, session: String) -> Bool {
        mobilityCount(date: date, session: session) == Config.Mobility.exercises.count
    }
    /// Complete sessions that day, 0 to 2.
    public func mobilitySessionsDone(date: String) -> Int {
        Config.Mobility.sessions.filter { mobilitySessionComplete(date: date, session: $0.id) }.count
    }
    /// Days (out of `dates`) with at least one complete session.
    public func mobilityDays(in dates: [String]) -> Int { dates.filter { mobilitySessionsDone(date: $0) > 0 }.count }
    /// Dates with any check-off, for History.
    public func mobilityDates() -> [String] { Array(Set((db.mobility ?? []).map(\.date))).sorted() }

    /// Checks the exercise off, or undoes it. Returns the new state; unknown ids and sessions are ignored.
    @discardableResult
    public mutating func toggleMobility(session: String, ex: String, date: String? = nil) -> Bool {
        guard Config.Mobility.sessions.contains(where: { $0.id == session }),
              Config.Mobility.exercises.contains(where: { $0.id == ex }) else { return false }
        let d = date ?? today
        var list = db.mobility ?? []
        if let i = list.firstIndex(where: { $0.date == d && $0.session == session && $0.ex == ex }) {
            list.remove(at: i)
            db.mobility = list.isEmpty ? nil : list
            return false
        }
        list.append(MobilityDone(date: d, session: session, ex: ex))
        db.mobility = list
        return true
    }
}
