import Foundation

/// What the health sensors said recently. Filled by the app from Apple Health; empty is fine.
public struct HealthSignals: Equatable {
    /// Hours asleep for recent nights that have data.
    public var sleepHours: [Double]
    /// Step totals for recent *complete* days that have data.
    public var steps: [Double]
    public init(sleepHours: [Double] = [], steps: [Double] = []) {
        self.sleepHours = sleepHours; self.steps = steps
    }
}

public struct Insight: Equatable, Identifiable {
    public enum Kind: String { case sleep, steps, muscle, heart, bone, onTrack, remaining }
    public var kind: Kind
    public var title: String
    public var body: String
    public var id: String { kind.rawValue }
}

extension Engine {
    /// Short, ranked observations for the card at the top of Move, most important first.
    /// The "still to go this week" line is the last one, shown when nothing is off.
    public func insights(health: HealthSignals) -> [Insight] {
        var out: [Insight] = []

        // Rings left open for several completed weeks in a row (only once history is long enough).
        let n = Config.Insights.ringMissedWeeks
        let firstDate = (db.history.map(\.date) + db.cardio.map(\.date)).sorted().first
        if let firstDate {
            let thisMon = Dates.mondayOf(today)
            let weeks = (1...n).map { Dates.addDays(thisMon, -7 * $0) }
            if weeks.allSatisfy({ $0 >= Dates.mondayOf(firstDate) }) {
                let stats = weeks.map { weekStats($0) }
                if stats.allSatisfy({ !$0.closed[2] }) {
                    out.append(Insight(kind: .bone, title: "Bone is being skipped",
                                       body: "No full jump days for \(n) weeks running. Bone is the layer that fades quietly."))
                }
                if stats.allSatisfy({ !$0.closed[1] }) {
                    out.append(Insight(kind: .heart, title: "Heart is falling behind",
                                       body: "Cardio has come up short \(n) weeks in a row. It is what moves your VO2 and longevity."))
                }
                if stats.allSatisfy({ !$0.closed[0] }) {
                    out.append(Insight(kind: .muscle, title: "Fewer lifts than planned",
                                       body: "Muscle has missed its target \(n) weeks running. Even a lighter day keeps the rotation going."))
                }
            }
        }

        if health.sleepHours.count >= Config.Insights.minSleepNights {
            let avg = health.sleepHours.reduce(0, +) / Double(health.sleepHours.count)
            if avg < Config.Insights.sleepMinHours {
                out.append(Insight(kind: .sleep, title: "You're sleeping too little",
                                   body: "Averaging \(String(format: "%.1f", avg)) h. To build muscle, aim for \(Int(Config.Insights.sleepMinHours))+ h."))
            }
        }
        if health.steps.count >= Config.Insights.minStepDays {
            let avg = health.steps.reduce(0, +) / Double(health.steps.count)
            if avg < Config.Insights.stepsMinDaily {
                out.append(Insight(kind: .steps, title: "Steps are low for longevity",
                                   body: "Averaging \(Fmt.nf(avg.rounded())) a day. Around \(Fmt.nf(Config.Insights.stepsMinDaily)) is where the benefit levels off."))
            }
        }

        let st = weekStats(Dates.mondayOf(today))
        out.append(Insight(kind: st.all ? .onTrack : .remaining, title: st.all ? "Week complete" : "This week",
                           body: weekHeadline(st)))
        return out
    }
}
