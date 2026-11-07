import Foundation

/// Daily Mobility bookkeeping. Optional by design: it never touches rings, streaks or insights.
extension Engine {
    private func mobilityExercise(_ id: String) -> Config.Mobility.Exercise? { Config.Mobility.exercises.first { $0.id == id } }

    /// Sets finished for one exercise in one session.
    public func mobilitySets(date: String, session: String, ex: String) -> Int {
        guard let x = mobilityExercise(ex),
              let e = (db.mobility ?? []).first(where: { $0.date == date && $0.session == session && $0.ex == ex }) else { return 0 }
        return min(max(e.sets ?? x.sets, 0), x.sets)
    }
    /// Exercise ids with every set finished.
    public func mobilityChecked(date: String, session: String) -> Set<String> {
        Set(Config.Mobility.exercises.filter { mobilitySets(date: date, session: session, ex: $0.id) >= $0.sets }.map(\.id))
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
    /// Dates with any progress, for History.
    public func mobilityDates() -> [String] { Array(Set((db.mobility ?? []).map(\.date))).sorted() }

    /// Sets an exercise's finished sets (clamped to its prescription; 0 clears it). Unknown ids are ignored.
    public mutating func setMobilitySets(session: String, ex: String, sets: Int, date: String? = nil) {
        guard Config.Mobility.sessions.contains(where: { $0.id == session }), let x = mobilityExercise(ex) else { return }
        let d = date ?? today, n = min(max(sets, 0), x.sets)
        var list = (db.mobility ?? []).filter { !($0.date == d && $0.session == session && $0.ex == ex) }
        if n > 0 { list.append(MobilityDone(date: d, session: session, ex: ex, sets: n)) }
        db.mobility = list.isEmpty ? nil : list
    }

    /// Taps set `index` (0-based): finishes it, or steps back if it was the last finished one.
    public mutating func tapMobilitySet(session: String, ex: String, index: Int, date: String? = nil) {
        let d = date ?? today, cur = mobilitySets(date: d, session: session, ex: ex)
        setMobilitySets(session: session, ex: ex, sets: cur == index + 1 ? index : index + 1, date: d)
    }

    /// Finishes every set at once, or clears the exercise if it was already done. Returns the new state.
    @discardableResult
    public mutating func toggleMobility(session: String, ex: String, date: String? = nil) -> Bool {
        guard let x = mobilityExercise(ex) else { return false }
        let d = date ?? today, done = mobilitySets(date: d, session: session, ex: ex) >= x.sets
        setMobilitySets(session: session, ex: ex, sets: done ? 0 : x.sets, date: d)
        return !done && Config.Mobility.sessions.contains { $0.id == session }
    }
}
