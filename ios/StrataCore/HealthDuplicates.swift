import Foundation

/// A workout Apple Health has that Strata did not save itself (recorded by the Watch's Workout app, another app...).
public struct ExternalWorkout: Equatable {
    public var isStrength: Bool
    public var minutes: Double
    public init(isStrength: Bool, minutes: Double) { self.isStrength = isStrength; self.minutes = minutes }
}

extension Engine {
    /// Which of a day's Health workouts are not already one of Strata's own sessions (returned as indexes into `list`).
    ///
    /// The same effort often shows up twice: you log it in Strata and the Watch recorded it too. Strata keeps no start
    /// time on a finished session, so the match is by kind and size:
    /// - each Strata lift session that day hides one strength workout from Health;
    /// - each Strata cardio entry with minutes hides one other workout whose length is within
    ///   `Config.Health.duplicateMinutes` of it.
    public func newExternalWorkouts(_ list: [ExternalWorkout], on date: String) -> [Int] {
        var hidden = Set<Int>()
        var lifts = db.history.filter { $0.date == date }.count
        for (i, w) in list.enumerated() where w.isStrength && lifts > 0 { hidden.insert(i); lifts -= 1 }
        for c in db.cardio where c.date == date && c.type != "jumps" && c.type != "home" && c.type != "office" {
            guard let m = c.min, m > 0 else { continue }
            if let i = list.indices.first(where: { !hidden.contains($0) && !list[$0].isStrength && abs(list[$0].minutes - m) <= Config.Health.duplicateMinutes }) {
                hidden.insert(i)
            }
        }
        return list.indices.filter { !hidden.contains($0) }
    }
}
