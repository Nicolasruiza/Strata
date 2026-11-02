import SwiftUI
import StrataCore

/// Cardio in progress (workout.js `cardioView`).
struct CardioLiveView: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.safeTop) private var safeTop
    @State private var confirmDiscard = false
    @State private var lastPhase = -1

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { _ in
            content()
        }
        .safeAreaInset(edge: .bottom) {
            WorkoutDock(discard: { confirmDiscard = true }) {
                Button("Complete") { model.completeCardio() }.buttonStyle(StrataButtonStyle(kind: .coral))
            }
        }
        .alert("Discard this cardio session? Nothing will be saved.", isPresented: $confirmDiscard) {
            Button("Discard", role: .destructive) { model.discardCardio() }
            Button("Cancel", role: .cancel) {}
        }
    }

    @ViewBuilder
    private func content() -> some View {
        if var e = model.engine, let L = e.db.live {
            let _ = { e.nowMs = AppModel.nowMs() }()
            let el = e.liveElapsed(L), s = e.cardioStats(samples: L.samples ?? [], elapsed: el)
            let M = e.hrMax().map(Double.init)
            let A = e.catalog.cardioActs[L.act]!
            let zc: Int? = (s.hr != nil && M != nil) ? e.zoneOf(s.hr!, M!) : nil
            let tot = s.z.dropFirst().reduce(0, +)
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    HStack { HStack(spacing: 8) { LogoMark(); Text("Strata").font(.inter(size: 20, weight: .bold)) }; Spacer() }
                        .frame(minHeight: 44)
                    Text("Cardio\(L.mode != "free" ? " · " + Engine.modeLbl(L.mode) : "")")
                        .font(.inter(size: 17, weight: .bold)).foregroundStyle(Theme.coral).padding(.top, 6)
                    Text(A.n).font(.inter(size: 34, weight: .heavy)).tracking(-0.85).padding(.top, -8)
                    LivePill().padding(.top, -6)
                    hrCard(e, L: L, s: s, M: M, zc: zc)
                    if L.mode == "4x4" { phaseCard(e, L: L, el: el) }
                    if s.zonesOK && tot > 0 { zonesCard(s: s, tot: tot, zc: zc, el: el) }
                    HStack(alignment: .top, spacing: 10) {
                        stat(icon: Icon.timer, title: "Elapsed", value: Fmt.mmss(el), note: nil)
                        if A.out { stat(icon: Icon.mount, title: "Elevation", value: s.elev.map { "+\($0) m" } ?? "—", note: s.elev == nil ? locationCopy : nil) }
                        else { stat(icon: Icon.heart, title: "Avg heart rate", value: s.avg.map(String.init) ?? "—", note: nil) }
                    }.fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 8) {
                        IconView(d: Icon.watch, size: 18, color: .white, line: 1.9)
                        Text(model.watchConnected ? Config.Copy.chipWatchConnected : Config.Copy.chipWatchNotConnected).font(.inter(size: 14, weight: .semibold))
                    }
                    .padding(.horizontal, 16).padding(.vertical, 9)
                    .overlay(Capsule().strokeBorder(Theme.line)).frame(maxWidth: .infinity)
                }
                .padding(.horizontal, Theme.gutter).padding(.top, 14 + safeTop).padding(.bottom, 110)
                .frame(maxWidth: Theme.maxWidth)
            }
        }
    }

    private var locationCopy: String {
        switch model.location {
        case .waiting: return Config.Copy.waitingForGPS
        case .noGPS: return Config.Copy.noGPS
        case .preciseOff: return Config.Copy.preciseLocationOff
        }
    }

    private func hrCard(_ e: Engine, L: LiveCardio, s: CardioStats, M: Double?, zc: Int?) -> some View {
        HStack(alignment: .top, spacing: 16) {
            CardioIcon(act: L.act, big: true)
            VStack(alignment: .leading, spacing: 6) {
                Text("Heart rate").font(.inter(size: 15)).foregroundStyle(Theme.muted)
                if let hr = s.hr {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(jsMinutes(hr)).font(.inter(size: 84, weight: .heavy)).tracking(-3.4).monospacedDigit()
                        Text("bpm").font(.inter(size: 24, weight: .semibold)).foregroundStyle(Theme.muted)
                    }.frame(height: 84)
                    if let z = zc {
                        HStack(spacing: 10) {
                            Text("Z\(z)").font(.inter(size: 20, weight: .heavy)).foregroundStyle(Theme.coral)
                                .padding(.horizontal, 14).padding(.vertical, 6).background(Capsule().fill(Theme.coral.opacity(0.2)))
                            Text("\(Config.zoneNames[z]) zone").metaStyle()
                                .padding(.leading, 10).overlay(alignment: .leading) { Rectangle().fill(Theme.line).frame(width: 1) }
                        }
                    } else { Text(Config.Copy.addAgeForZones).metaStyle() }
                    if L.mode == "z2", let M = M {
                        let r = e.zoneRange(2, M)
                        Text("Target: stay in Z2 · \(r[0])–\(r[1]) bpm").smallStyle()
                    }
                } else {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("—").font(.inter(size: 84, weight: .heavy)).foregroundStyle(Theme.dim)
                        Text("bpm").font(.inter(size: 24, weight: .semibold)).foregroundStyle(Theme.muted)
                    }.frame(height: 84)
                    if !model.watchConnected { Text(Config.Copy.noHeartRateWatchUnreachable).metaStyle() }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(20)
        .glowPanel(Theme.coral, radial: 0.3, from: 0.16, to: 0.04, radius: 26, border: 0.3)
    }

    private func phaseCard(_ e: Engine, L: LiveCardio, el: Double) -> some View {
        let a = e.phaseAt(el, n: L.n), hard = a.p.k == "hard"
        let ph = e.rcPhases((L.n ?? 0) != 0 ? L.n! : Config.Intervals.displayFallbackCount)
        let hr = e.rcHR()
        let lbl: String = a.over != nil ? "Done · cool down as long as you like"
            : hard ? a.p.label.replacingOccurrences(of: "Interval (\\d+) of (\\d+) · hard", with: "Hard · $1 of $2", options: .regularExpression)
            : a.p.label.replacingOccurrences(of: " · easy", with: "")
        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(lbl).labelStyle(hard ? Theme.coral : Theme.muted)
                Spacer()
                Text(a.over != nil ? "" : Fmt.mmss(a.left.rounded(.up))).font(.inter(size: 24, weight: .bold)).monospacedDigit()
            }
            if let hr = hr, hard || a.p.label.hasPrefix("Recover") {
                Text(hard ? "Target \(hr.hard[0])–\(hr.hard[1]) bpm" : "Recover under \(hr.z2[1]) bpm").smallStyle().padding(.top, 4)
            }
            GeometryReader { g in
                let total = Double(ph.reduce(0) { $0 + $1.sec }), gaps = CGFloat(ph.count - 1) * 4
                HStack(spacing: 4) {
                    ForEach(ph.indices, id: \.self) { i in
                        let p = ph[i], w = (g.size.width - gaps) * CGFloat(Double(p.sec) / total)
                        ZStack(alignment: .leading) {
                            Capsule().fill(p.k == "hard" ? Theme.coral.opacity(0.25) : Color.white.opacity(0.12))
                            if i < a.i { Capsule().fill(p.k == "hard" ? Theme.coral : Color.white.opacity(0.45)) }
                            if i == a.i { Capsule().fill(p.k == "hard" ? Theme.coral : Color.white.opacity(0.45)).frame(width: w * CGFloat(min(1, a.into / Double(p.sec)))) }
                        }.frame(width: w, height: 10).clipShape(Capsule())
                    }
                }
            }.frame(height: 10).padding(.top, 10)
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 22).fill(hard ? Theme.coral.opacity(0.1) : Theme.glass))
        .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(hard ? Theme.coral.opacity(0.55) : Theme.line))
        .onChange(of: a.i) { _, new in
            if lastPhase != -1 && new != lastPhase { model.cue() }
            lastPhase = new
        }
        .onAppear { lastPhase = a.i }
    }

    private func zonesCard(s: CardioStats, tot: Double, zc: Int?, el: Double) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("Time in zones").font(.inter(size: 18, weight: .semibold)); Spacer(); Text("Total \(Fmt.mmss(el))").metaStyle()
            }
            ZoneBar(z: s.z, tot: tot, highlight: zc)
            ZoneLabels(z: s.z, highlight: zc)
        }.padding(.top, 4)
    }

    private func stat(icon: String, title: String, value: String, note: String?) -> some View {
        HStack(spacing: 12) {
            IconView(d: icon, size: 24, color: Theme.coral, line: 1.9).frame(width: 44, height: 44)
                .background(RoundedRectangle(cornerRadius: 14).fill(Theme.coral.opacity(0.16)))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).metaStyle()
                Text(value).font(.inter(size: 26, weight: .heavy)).monospacedDigit()
                if let n = note { Text(n).smallStyle() }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16).padding(.vertical, 14).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 22).fill(Theme.glass))
        .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(Theme.line))
    }
}

/// "Workout in progress" pill with the pulsing dot (`.wlive`)
struct LivePill: View {
    @State private var on = true
    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(Theme.coral).frame(width: 8, height: 8).opacity(on ? 1 : 0.3)
            Text("Workout in progress").font(.inter(size: 14, weight: .semibold))
        }
        .padding(.horizontal, 14).padding(.vertical, 7).overlay(Capsule().strokeBorder(Theme.line))
        .onAppear { withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) { on = false } }
    }
}

/// `.zbar`
struct ZoneBar: View {
    let z: [Double], tot: Double
    var highlight: Int?
    var body: some View {
        GeometryReader { g in
            HStack(spacing: 3) {
                ForEach(1...5, id: \.self) { i in
                    let f = max(0.0001, z[i] / max(tot, 0.0001))
                    Rectangle().fill(i == highlight ? Theme.coral : Color(hex: Config.zoneColors[i]))
                        .frame(width: max(2, (g.size.width - 12) * CGFloat(f / (1...5).reduce(0.0) { $0 + max(0.0001, z[$1] / max(tot, 0.0001)) })))
                }
            }.clipShape(RoundedRectangle(cornerRadius: 7))
        }.frame(height: 14)
    }
}

/// `.zlbl`
struct ZoneLabels: View {
    let z: [Double]
    var highlight: Int?
    var body: some View {
        HStack {
            ForEach(1...5, id: \.self) { i in
                VStack(spacing: 2) {
                    Text("Z\(i)").font(.inter(size: 13)).foregroundStyle(i == highlight ? Theme.coral : Theme.muted)
                    Text(Fmt.mmss(z[i])).font(.inter(size: 16, weight: .bold)).monospacedDigit()
                }.frame(maxWidth: .infinity)
            }
        }
    }
}
