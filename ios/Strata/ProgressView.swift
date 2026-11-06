import SwiftUI
import StrataCore

/// `lineSVG`: the top-set / waist line chart, drawn in the web's 340 × 150 box.
struct LineChart: View {
    let pts: [ProgressPoint]
    let color: Color
    var body: some View {
        if pts.isEmpty {
            Text("No data yet.").font(.inter(size: 14)).foregroundStyle(Theme.muted).frame(maxWidth: .infinity).padding(.vertical, 26)
        } else {
            Canvas { ctx, size in
                let W = 340.0, H = 150.0, pl = 34.0, pr = 12.0, pt = 22.0, pb = 24.0
                let k = size.width / W
                let ys = pts.map(\.y), sc = Engine.chartScale(ys), n = pts.count
                func X(_ i: Int) -> Double { pl + (n == 1 ? (W - pl - pr) / 2 : Double(i) * (W - pl - pr) / Double(n - 1)) }
                func Y(_ v: Double) -> Double { pt + (1 - (v - sc.y0) / ((sc.y1 - sc.y0) != 0 ? (sc.y1 - sc.y0) : 1)) * (H - pt - pb) }
                func P(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x * k, y: y * k) }
                for t in sc.ticks {
                    var l = Path(); l.move(to: P(pl, Y(t))); l.addLine(to: P(W - pr, Y(t)))
                    ctx.stroke(l, with: .color(.white.opacity(0.08)), lineWidth: 1)
                    ctx.draw(Text(jsMinutes(t)).font(.inter(size: 11 * k)).foregroundColor(Color(hex: "#A9AEBD")), at: P(pl - 6, Y(t)), anchor: .trailing)
                }
                var line = Path()
                for i in 0..<n { let p = P(X(i), Y(pts[i].y)); if i == 0 { line.move(to: p) } else { line.addLine(to: p) } }
                var area = line
                area.addLine(to: P(X(n - 1), H - pb)); area.addLine(to: P(X(0), H - pb)); area.closeSubpath()
                ctx.fill(area, with: .color(color.opacity(0.14)))
                ctx.stroke(line, with: .color(color), style: StrokeStyle(lineWidth: 2.5 * k, lineJoin: .round))
                let every = Int((Double(n) / 6).rounded(.up))
                for i in 0..<n {
                    let r = (i == n - 1 ? 5.0 : 3.5) * k, c = P(X(i), Y(pts[i].y))
                    ctx.fill(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r)), with: .color(color))
                    if i % every == 0 || i == n - 1 {
                        ctx.draw(Text(pts[i].l).font(.inter(size: 10.5 * k)).foregroundColor(Color(hex: "#A9AEBD")), at: P(X(i), H - 6), anchor: .center)
                    }
                }
                ctx.draw(Text(jsMinutes(pts[0].y)).font(.inter(size: 12 * k, weight: .bold)).foregroundColor(.white), at: P(X(0), Y(pts[0].y) - 9), anchor: .center)
                if n > 1 { ctx.draw(Text(jsMinutes(pts[n - 1].y)).font(.inter(size: 13 * k, weight: .heavy)).foregroundColor(.white), at: P(X(n - 1), Y(pts[n - 1].y) - 10), anchor: .center) }
            }
            .aspectRatio(340.0 / 150.0, contentMode: .fit).padding(.top, 8)
        }
    }
}

/// `barSVG`: weekly bars in a 160 × 110 box; the last bar (this week) is lighter.
struct BarChart: View {
    let vals: [Double]
    let labels: [String]
    let color: Color
    let fmt: (Double) -> String
    var lightIndex: Int? = 7
    var body: some View {
        Canvas { ctx, size in
            let W = 160.0, H = 110.0, pb = 18.0, pt = 16.0
            let k = size.width / W, mx = max(1, vals.max() ?? 1), n = vals.count, bw = (W / Double(n)) * 0.62
            for (i, v) in vals.enumerated() {
                let x = Double(i) * W / Double(n) + (W / Double(n) - bw) / 2, h = v / mx * (H - pb - pt)
                let rect = CGRect(x: x * k, y: (H - pb - h) * k, width: bw * k, height: max(h, v != 0 ? 2 : 0) * k)
                ctx.fill(Path(roundedRect: rect, cornerRadius: 3 * k), with: .color(color.opacity(i == lightIndex ? 0.45 : 1)))
                if v != 0 { ctx.draw(Text(fmt(v)).font(.inter(size: 9.5 * k, weight: .bold)).foregroundColor(.white), at: CGPoint(x: (x + bw / 2) * k, y: (H - pb - h - 4) * k - 4 * k), anchor: .center) }
                ctx.draw(Text(labels[i]).font(.inter(size: 8.5 * k)).foregroundColor(Color(hex: "#A9AEBD")), at: CGPoint(x: (x + bw / 2) * k, y: (H - 5) * k - 3 * k), anchor: .center)
            }
        }.aspectRatio(160.0 / 110.0, contentMode: .fit).padding(.top, 8)
    }
}

/// Progress (app.js `progressView`).
struct ProgressScreen: View {
    @EnvironmentObject var model: AppModel
    @State private var waist = ""
    @State private var sleepWeekly = false

    var body: some View {
        let e = model.engine!
        let keys = e.progressLifts()
        let lift = (model.progLift.flatMap { id in keys.contains { $0.id == id } ? id : nil }) ?? e.defaultProgressLift() ?? ""
        let weeks = model.progRange
        let pts = e.progressPoints(lift: lift, weeks: weeks)
        let ex = e.exById(lift), first = pts.first, last = pts.last
        let pct = (first != nil && last != nil && first!.y != 0) ? jsRound((last!.y - first!.y) / first!.y * 100) : 0
        let pw = e.progressWeeks(), wl = (1...8).map { "W\($0)" }
        let healthStepWeeks = healthStepAverages(ending: e.today)
        let stepValues = healthStepWeeks.contains(where: { $0 != 0 }) ? healthStepWeeks : pw.steps
        let lastSteps = stepValues.reversed().first { $0 != 0 } ?? 0
        let waistPts = (e.db.waist ?? []).suffix(8)
        let sk = e.streak()
        let sleepVals = sleepWeekly ? sleepWeeklyAverages(ending: e.today) : sleepDaily(ending: e.today)
        let sleepLabels = sleepWeekly ? wl.map { String($0.dropFirst()) } : ["M", "T", "W", "T", "F", "S", "S"]
        let sleepNonZero = sleepVals.filter { $0 > 0 }
        let sleepHeadline: Double? = sleepNonZero.isEmpty ? nil : sleepNonZero.reduce(0, +) / Double(sleepNonZero.count)
        ScrollView {
            VStack(spacing: 0) {
                Hero(eyebrow: nil, title: "Progress", sub: "What the last weeks added up to.", settingsAction: { model.go(.settings) })
                VStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 2) { Text(Fmt.cleanN(ex?.n ?? "")).nameStyle(); Text("Top set, lb").metaStyle() }
                            Spacer()
                            if pts.count > 1 {
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("\(pct >= 0 ? "+" : "")\(jsMinutes(pct))%").font(.inter(size: 24, weight: .heavy)).foregroundStyle(Theme.violet)
                                    Text("\(jsMinutes(first!.y)) → \(jsMinutes(last!.y)) lb").smallStyle()
                                }
                            }
                        }
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(keys, id: \.id) { k in
                                    Button { model.progLift = k.id } label: {
                                        Text(Fmt.cleanN(k.n)).font(.inter(size: 12, weight: .semibold)).lineLimit(1).fixedSize()
                                            .foregroundStyle(k.id == lift ? Color(hex: "#0E1018") : Color(hex: "#E6E8EE"))
                                            .padding(.horizontal, 11).padding(.vertical, 7)
                                            .background(Capsule().fill(k.id == lift ? Color(hex: "#F4F5F8") : Theme.glass2))
                                    }.buttonStyle(.plain)
                                }
                            }
                        }.padding(.top, 10).padding(.bottom, 2)
                        LineChart(pts: pts, color: Theme.violet)
                        Seg(items: [(8, "8W"), (26, "6M"), (52, "1Y")], selected: model.progRange) { model.progRange = $0 }.padding(.top, 8)
                    }.card()

                    VStack(alignment: .leading, spacing: 0) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 2) { Text("Weekly rings").nameStyle(); Text("Muscle, Heart, Bone").metaStyle() }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(sk) week\(sk == 1 ? "" : "s")").font(.inter(size: 24, weight: .heavy))
                                Text("in a row, all 3 closed").smallStyle()
                            }
                        }
                        HStack(spacing: 4) {
                            ForEach(0..<8, id: \.self) { i in
                                VStack(spacing: 6) {
                                    VStack(spacing: 4) {
                                        ForEach(0..<3, id: \.self) { j in
                                            Circle().fill(pw.stats[i].closed[j] ? Theme.ring(["m", "h", "b"][j]) : Color.white.opacity(0.12)).frame(width: 12, height: 12)
                                        }
                                    }
                                    Text(i == 7 ? "Now" : wl[i]).font(.inter(size: 12, weight: i == 7 ? .bold : .regular)).foregroundStyle(i == 7 ? .white : Theme.muted)
                                }.frame(maxWidth: .infinity)
                            }
                        }.padding(.top, 14)
                    }.card()

                    HStack(alignment: .top, spacing: 10) {         // .grid2: both cards stretch to the taller one
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Cardio").nameStyle(15); Text("minutes / week · incl. Health").metaStyle()
                            BarChart(vals: cardioMinutes(ending: e.today), labels: wl.map { String($0.dropFirst()) }, color: Theme.coral) { jsMinutes($0) }
                        }.frame(maxHeight: .infinity, alignment: .top).card(tight: true)
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Steps").nameStyle(15)
                            Text((healthStepWeeks.contains(where: { $0 != 0 }) ? "daily avg" : "avg / office day") + " · thousands").metaStyle()
                            Text(lastSteps != 0 ? Fmt.nf(Double(lastSteps)) : "—").font(.inter(size: 20, weight: .heavy)).monospacedDigit().padding(.top, 4)
                            BarChart(vals: stepValues.map(Double.init), labels: wl.map { String($0.dropFirst()) }, color: Theme.coral) { Fmt.fmtFixed($0 / 1000, 1) }
                            Text(healthStepWeeks.contains(where: { $0 != 0 }) ? "Apple Health" : "Manual office logs").smallStyle()
                        }.frame(maxHeight: .infinity, alignment: .top).card(tight: true)
                    }.fixedSize(horizontal: false, vertical: true)

                    HStack(alignment: .top, spacing: 10) {
                        VStack(alignment: .leading, spacing: 0) {
                            HStack { IconView(d: Icon.timer, size: 17, color: Theme.amber); Text("Sleep").nameStyle(15) }
                            Text(sleepWeekly ? "avg per night, 8 weeks" : "this week, per night").metaStyle()
                            Seg(items: [(false, "Days"), (true, "Weeks")], selected: sleepWeekly) { sleepWeekly = $0 }.padding(.top, 8)
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text(sleepHeadline.map { Fmt.fmtFixed($0, 1) } ?? "—").font(.inter(size: 24, weight: .heavy)).monospacedDigit()
                                Text("h avg").metaStyle()
                            }.padding(.top, 10)
                            if sleepHeadline != nil {
                                BarChart(vals: sleepVals, labels: sleepLabels, color: Theme.amber, fmt: { Fmt.fmtFixed($0, 1) },
                                         lightIndex: sleepWeekly ? 7 : nil)
                            }
                            Text(sleepHeadline == nil ? "No sleep data in Apple Health" : "Apple Health").smallStyle().padding(.top, 6)
                        }.frame(maxHeight: .infinity, alignment: .top).card(tight: true)

                        VStack(alignment: .leading, spacing: 0) {
                            HStack { IconView(d: Icon.dumbbell, size: 17, color: Theme.violet); Text("Strength").nameStyle(15) }
                            Text("sessions / week").metaStyle()
                            Text("\(pw.stats.last?.m ?? 0)").font(.inter(size: 24, weight: .heavy)).monospacedDigit().padding(.top, 10)
                            BarChart(vals: pw.stats.map { Double($0.m) }, labels: wl.map { String($0.dropFirst()) }, color: Theme.violet) { jsMinutes($0) }
                            Text("Strata workouts").smallStyle()
                        }.frame(maxHeight: .infinity, alignment: .top).card(tight: true)
                    }.fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .leading, spacing: 0) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 2) { Text("Waist").nameStyle(); Text("cm · the honest recomp number").metaStyle() }
                            Spacer()
                            if let l = waistPts.last { Text(jsMinutes(l.cm)).font(.inter(size: 24, weight: .heavy)) }
                        }
                        if waistPts.count > 1 {
                            LineChart(pts: waistPts.map { ProgressPoint(l: Dates.fmtD($0.date, .init(month: .short, day: true)), y: $0.cm) }, color: Color(hex: "#C9CED8"))
                        } else {
                            Text("Measure at the belly button, relaxed, same time of day. Every 2 weeks is enough.")
                                .font(.inter(size: 13)).foregroundStyle(Theme.muted).padding(.top, 10)
                        }
                        HStack(spacing: 8) {
                            StepField(title: nil, placeholder: "cm", text: $waist, keyboard: .decimalPad, big: false, alignRight: false)
                            Button("Add measurement") {
                                model.mutate { $0.addWaist(cm: Double(waist) ?? 0) }
                                if let w = Double(waist), w > Config.waistRangeCm.min && w < Config.waistRangeCm.max { waist = "" }
                            }.buttonStyle(StrataButtonStyle(small: true, hPad: 18)).fixedSize()
                        }.padding(.top, 12)
                    }.card()
                }.padding(.horizontal, Theme.gutter).padding(.top, 14).padding(.bottom, 110)
            }.frame(maxWidth: Theme.maxWidth)
        }
    }

    private func healthStepAverages(ending today: String) -> [Int] {
        let monday = Dates.mondayOf(today)
        return (0..<8).map { index in
            let week = Dates.weekDates(Dates.addDays(monday, -7 * (7 - index)))
            let values = week.compactMap { model.syncedSteps(on: $0) }
            guard !values.isEmpty else { return 0 }
            return Int((Double(values.reduce(0, +)) / Double(values.count)).rounded())
        }
    }

    /// Total cardio minutes per week: Strata's own log plus cardio workouts from Apple Health
    /// (strength, jumps and office steps excluded).
    private func cardioMinutes(ending today: String) -> [Double] {
        let monday = Dates.mondayOf(today)
        let cardio = model.engine?.db.cardio ?? []
        return (0..<8).map { index in
            let week = Dates.weekDates(Dates.addDays(monday, -7 * (7 - index)))
            let strata = cardio.filter { week.contains($0.date) && $0.type != "jumps" && $0.type != "office" }
                .reduce(0) { $0 + ($1.min ?? 0) }
            return strata + week.reduce(0) { $0 + model.healthCardioMinutes(on: $1) }
        }
    }

    /// Hours asleep for each day of this week, Monday first (0 where Health has nothing).
    private func sleepDaily(ending today: String) -> [Double] {
        Dates.weekDates(Dates.mondayOf(today)).map { model.syncedSleep(on: $0) ?? 0 }
    }

    /// Average hours per night for each of the last 8 weeks (0 for a week with no data).
    private func sleepWeeklyAverages(ending today: String) -> [Double] {
        let monday = Dates.mondayOf(today)
        return (0..<8).map { index in
            let nights = Dates.weekDates(Dates.addDays(monday, -7 * (7 - index))).compactMap { model.syncedSleep(on: $0) }.filter { $0 > 0 }
            return nights.isEmpty ? 0 : nights.reduce(0, +) / Double(nights.count)
        }
    }
}
