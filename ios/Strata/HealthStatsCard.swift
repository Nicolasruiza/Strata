import SwiftUI
import StrataCore

/// Heart rate and calories for a session, from the Apple Health workout that is the same effort.
struct HealthStatsCard: View {
    let workout: WorkoutDetail

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Apple Health").labelStyle()
                Spacer()
                Text("\(jsMinutes(workout.minutes.rounded())) min").smallStyle()
            }
            HStack(spacing: 10) {
                tile("Avg HR", workout.avgHR.map { "\(jsMinutes($0.rounded())) bpm" })
                tile("Max HR", workout.maxHR.map { "\(jsMinutes($0.rounded())) bpm" })
                tile("Active kcal", workout.kcal.map { Fmt.nf($0.rounded()) })
            }
            if workout.hr.count > 1 {
                LineChart(pts: workout.hr.map { ProgressPoint(l: "\(Int($0.minute.rounded()))m", y: $0.bpm) }, color: Theme.coral) { String(Int($0.rounded())) }
            }
        }.card()
    }

    private func tile(_ title: String, _ value: String?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).metaStyle()
            Text(value ?? "—").font(.inter(size: 18, weight: .bold)).lineLimit(1).minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12).padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.05)))
    }
}
