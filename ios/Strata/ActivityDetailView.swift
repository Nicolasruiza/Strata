import SwiftUI
import StrataCore

/// History detail for a cardio entry or an office (steps) day: what the Strata log says, plus
/// what Apple Health adds (heart-rate curve, distance, climb; steps and heart rate by hour).
struct ActivityDetailView: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.safeTop) private var safeTop
    let date: String, type: String
    @State private var workout: WorkoutDetail?
    @State private var day: DaySeries?
    @State private var loaded = false

    private static let names = ["office": "Office day", "4x4": "4×4 intervals", "z2": "Zone 2 walk", "walk": "Walk",
                                "cardio": "Cardio", "home": "Home session"]

    var body: some View {
        let e = model.engine!
        let c = e.cardioOn(date, type)
        let title = c?.act.flatMap { e.catalog.cardioActs[$0]?.n } ?? Self.names[type] ?? type
        ScrollView {
            VStack(spacing: 0) {
                ZStack(alignment: .topLeading) {
                    Hero(eyebrow: Dates.fmtD(date, .init(weekday: .long, month: .short, day: true, year: true)), title: title,
                         sub: subtitle(c), short: true, brand: false)
                    GlassButton(action: { model.go(.history) }, accessibility: "Back") { IconView(d: Icon.back, size: 18, color: .white, line: 2.4) }
                        .padding(.leading, 16).padding(.top, 14 + safeTop)
                }
                VStack(spacing: 12) {
                    if type == "office" { officeBody(c) } else { sessionBody(e, c) }
                    Button("Edit or delete") { model.sheet = .editCardio(date: date, type: type) }
                        .buttonStyle(LinkButtonStyle()).frame(maxWidth: .infinity).padding(.top, 4)
                }.padding(.horizontal, Theme.gutter).padding(.top, 14).padding(.bottom, 40)
            }.frame(maxWidth: Theme.maxWidth)
        }
        .sheet(item: $model.sheet) { s in
            if case .editCardio(let d, let t) = s { EditCardioSheet(date: d, type: t) }
        }
        .task(id: "\(date)-\(type)") {
            loaded = false
            if type == "office" { day = await model.health.daySeries(on: date) }
            else { workout = await model.health.workoutDetail(on: date, minutes: c?.min) }
            loaded = true
        }
    }

    private func subtitle(_ c: CardioEntry?) -> String {
        if type == "office" { return "\(Fmt.nf(c?.steps ?? 0)) steps" }
        return (c?.min ?? 0) != 0 ? "\(jsMinutes(c!.min!)) min" : "Logged in Strata"
    }

    // MARK: a cardio session

    @ViewBuilder
    private func sessionBody(_ e: Engine, _ c: CardioEntry?) -> some View {
        let avg = c?.avgHR ?? workout?.avgHR, mx = c?.maxHR ?? workout?.maxHR
        let elev = (c?.elev).map { $0 } ?? workout?.ascendedM
        HStack(spacing: 10) {
            tile("Avg HR", avg.map { "\(jsMinutes($0.rounded())) bpm" })
            tile("Max HR", mx.map { "\(jsMinutes($0.rounded())) bpm" })
        }
        HStack(spacing: 10) {
            tile("Distance", workout?.distanceKm.map { "\(Fmt.fmtFixed($0, 1)) km" })
            tile("Climb", elev.map { "+\(jsMinutes($0.rounded())) m" })
        }
        if let k = workout?.kcal { HStack(spacing: 10) { tile("Active kcal", Fmt.nf(k.rounded())) } }
        if let z = c?.zones, z.reduce(0, +) > 0 { zonesCard(z) }
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 2) { Text("Heart rate").nameStyle(); Text("bpm over the session · Apple Health").metaStyle() }
            if let hr = workout?.hr, hr.count > 1 {
                LineChart(pts: hr.map { ProgressPoint(l: "\(Int($0.minute.rounded()))m", y: $0.bpm) }, color: Theme.coral) { String(Int($0.rounded())) }
            } else {
                Text(loaded ? "No heart-rate data in Apple Health for this session." : "Loading…")
                    .font(.inter(size: 13)).foregroundStyle(Theme.muted).padding(.top, 10)
            }
        }.card()
    }

    private func zonesCard(_ z: [Double]) -> some View {
        let total = max(1, z.reduce(0, +))
        return VStack(alignment: .leading, spacing: 10) {
            Text("Time in zones").nameStyle()
            GeometryReader { g in
                HStack(spacing: 2) {
                    ForEach(z.indices, id: \.self) { i in
                        Rectangle().fill(Color(hex: Config.zoneColors[min(i + 1, Config.zoneColors.count - 1)]))
                            .frame(width: max(0, g.size.width * z[i] / total - 2))
                    }
                }.clipShape(Capsule())
            }.frame(height: 10)
            ForEach(z.indices, id: \.self) { i in
                if z[i] > 0 {
                    HStack {
                        Circle().fill(Color(hex: Config.zoneColors[min(i + 1, Config.zoneColors.count - 1)])).frame(width: 8, height: 8)
                        Text(Config.zoneNames[min(i + 1, Config.zoneNames.count - 1)]).font(.inter(size: 14))
                        Spacer()
                        Text("\(Int((z[i] / 60).rounded())) min").font(.inter(size: 14, weight: .semibold)).monospacedDigit()
                    }
                }
            }
        }.card()
    }

    // MARK: an office (steps) day

    @ViewBuilder
    private func officeBody(_ c: CardioEntry?) -> some View {
        HStack(spacing: 10) {
            tile("Steps", c?.steps.map { Fmt.nf($0) })
            tile("Distance", day?.distanceKm.map { "\(Fmt.fmtFixed($0, 1)) km" })
            tile("Floors", day?.flights.map { jsMinutes($0.rounded()) })
        }
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 2) { Text("Steps by hour").nameStyle(); Text("Apple Health").metaStyle() }
            if let d = day, d.stepsByHour.contains(where: { $0 > 0 }) {
                BarChart(vals: d.stepsByHour, labels: (0..<24).map(String.init), color: Theme.coral, fmt: { _ in "" },
                         lightIndex: nil, showValues: false, labelEvery: 6)
            } else {
                Text(loaded ? "No hourly steps in Apple Health for this day." : "Loading…")
                    .font(.inter(size: 13)).foregroundStyle(Theme.muted).padding(.top, 10)
            }
        }.card()
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 2) { Text("Heart rate by hour").nameStyle(); Text("average bpm · Apple Health").metaStyle() }
            let pts = (day?.hrByHour ?? []).enumerated().compactMap { h, v in v.map { ProgressPoint(l: "\(h)h", y: $0) } }
            if pts.count > 1 { LineChart(pts: pts, color: Theme.coral) { String(Int($0.rounded())) } }
            else {
                Text(loaded ? "No heart-rate data in Apple Health for this day." : "Loading…")
                    .font(.inter(size: 13)).foregroundStyle(Theme.muted).padding(.top, 10)
            }
        }.card()
    }

    private func tile(_ label: String, _ value: String?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.inter(size: 12)).foregroundStyle(Theme.muted)
            Text(value ?? "—").font(.inter(size: 18, weight: .heavy)).monospacedDigit().lineLimit(1).minimumScaleFactor(0.7)
        }.frame(maxWidth: .infinity, alignment: .leading).card(tight: true)
    }
}
