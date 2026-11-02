import SwiftUI

/// Heart rate and time while a workout runs; otherwise it says it is waiting for the phone.
struct WatchRootView: View {
    @EnvironmentObject var w: WatchWorkout

    var body: some View {
        VStack(spacing: 6) {
            if w.running, let start = w.started {
                Text(w.hr.map { String(Int($0.rounded())) } ?? "—")
                    .font(.system(size: 56, weight: .heavy)).monospacedDigit()
                Text("bpm").font(.footnote).foregroundStyle(.secondary)
                Text(start, style: .timer).font(.system(.title3, design: .rounded)).monospacedDigit()
            } else {
                Text("Strata").font(.headline)
                Text("Start a workout on your iPhone.").font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center)
            }
        }
    }
}
