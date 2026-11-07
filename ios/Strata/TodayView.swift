import SwiftUI
import StrataCore

/// Today (app.js `todayView`, `slotCard`, `homeCard`, `otherOptions`).
struct TodayView: View {
    @EnvironmentObject var model: AppModel
    @State private var steps = ""
    @State private var minutes = ""

    var body: some View {
        let e = model.engine!
        let t = e.today, mon = Dates.mondayOf(t), wp = e.weekPlan(), slots = e.liftSlots(mon), ds = Dates.weekDates(mon), st = e.weekStats(mon)
        let sel = model.selDay ?? Dates.weekday(t)
        let selDate = ds[Engine.wdOrder.firstIndex(of: sel)!], slot = wp[sel] ?? "rest", isToday = selDate == t
        let streak = e.streak()
        ScrollView {
            VStack(spacing: 0) {
                Hero(eyebrow: Dates.fmtD(t, .init(weekday: .long, month: .long, day: true)),
                     title: "\(e.greet()), \(e.profile.name)",
                     sub: streak > 0 ? "\(streak)-week streak. Keep the layers stacking." : "Build it in layers: muscle, heart, bone.",
                     settingsAction: { model.go(.settings) })
                VStack(spacing: 12) {
                    CompactRings(st: st)
                    InsightCard(insights: e.insights(health: healthSignals(today: t)))
                    mainCard(e, slot: slot, selDate: selDate, isToday: isToday, lp: slots[sel], st: st, mon: mon)
                    if isToday && e.db.active == nil { MobilityCard(e: e) }
                    if isToday && e.db.active == nil { otherOptions(slot) }
                    if isToday { todayLog(e, t: t) }
                    weekCard(e)
                }
                .padding(.horizontal, Theme.gutter).padding(.top, 14).padding(.bottom, 110)
            }
            .frame(maxWidth: Theme.maxWidth)
        }
        .sheet(item: $model.sheet) { s in
            switch s {
            case .cantTrain: CantTrainSheet()
            case .walk: WalkSheet()
            case .editCardio(let d, let ty): EditCardioSheet(date: d, type: ty)
            }
        }
    }

    // MARK: the main card

    @ViewBuilder
    private func mainCard(_ e: Engine, slot: String, selDate: String, isToday: Bool, lp: LiftSlot?, st: WeekStats, mon: String) -> some View {
        if let A = e.db.active {
            let req = e.requiredItems(A.day), n = req.filter { e.isLogged($0) }.count
            VStack(alignment: .leading, spacing: 0) {
                Text("In progress").labelStyle(Theme.violet)
                Text(e.plan[A.day]?.name ?? "").title2Style().padding(.top, 4).padding(.bottom, 2)
                Text("\(n) of \(req.count) main lifts logged").metaStyle()
                Button("Resume workout") { model.tick() }
                    .buttonStyle(StrataButtonStyle(kind: .violet)).padding(.top, 14)
            }.card(border: Theme.violet.opacity(0.45))
        } else if e.skipOn(selDate) != nil && !e.slotDone(slot, selDate, mon) {
            homeCard(e, date: selDate, isToday: isToday)
        } else {
            slotCard(e, slot: slot, date: selDate, isToday: isToday, lp: lp)
            if isToday && slot != "rest" && !e.slotDone(slot, selDate, mon) {
                Button("Can't train today?") { model.sheet = .cantTrain }
                    .buttonStyle(LinkButtonStyle()).frame(maxWidth: .infinity).padding(.top, -6)
            }
        }
    }

    private func when(_ e: Engine, _ date: String, _ isToday: Bool) -> String {
        isToday ? "Today" : Dates.fmtD(date, .init(weekday: .long))
    }

    @ViewBuilder
    private func slotCard(_ e: Engine, slot: String, date: String, isToday: Bool, lp: LiftSlot?) -> some View {
        let w = when(e, date, isToday)
        switch slot {
        case "lift":
            if let lp = lp, lp.status != "missed", let d = lp.day {
                if lp.status == "done", let h = e.liftedOn(date) {
                    let jumps = e.cardioOn(date, "jumps") != nil
                    VStack(alignment: .leading, spacing: 0) {
                        Text("\(w) · Done").labelStyle(Theme.violet)
                        Text(e.plan[d]?.name ?? "").title2Style().padding(.top, 4).padding(.bottom, 2)
                        Text("\(e.exCount(h)) exercises" + ((h.min ?? 0) != 0 ? " · \(jsMinutes(h.min!)) min" : "") + (jumps ? " · jumps done" : "")).metaStyle()
                        Button("View session") { model.navigate(.detail(historyIndex: e.db.history.firstIndex(of: h) ?? 0)) }
                            .buttonStyle(StrataButtonStyle(small: true)).padding(.top, 14)
                    }.card()
                } else {
                    let req = e.requiredItems(d), legs = e.isLegs(d)
                    let g = isToday ? e.gate(view: d) : nil
                    VStack(alignment: .leading, spacing: 0) {
                        Text("\(w) · Muscle\(legs ? " + Bone" : "")").labelStyle(Theme.violet)
                        Text(e.plan[d]?.name ?? "").title2Style().padding(.top, 4).padding(.bottom, 2)
                        Text("\(req.count) main lifts · ~\(jsMinutes(e.minutesFor(d))) min\(legs ? " · jumps first" : "")").metaStyle()
                        // Photos share the full card width in equal squares (at least 4 slots, so
                        // two exercises don't blow up into huge pictures).
                        let shown = req.compactMap { ex in e.catalog.imageName(of: ex.id).map { (ex, $0) } }
                        HStack(spacing: 8) {
                            ForEach(shown, id: \.0.id) { ex, img in
                                Color.clear.aspectRatio(1, contentMode: .fit)
                                    .overlay(BundleImage(name: ((img as NSString).lastPathComponent as NSString).deletingPathExtension))
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                    .frame(maxWidth: .infinity)
                                    .accessibilityLabel(Fmt.cleanN(ex.n))
                            }
                            ForEach(0..<max(0, 4 - shown.count), id: \.self) { _ in Color.clear.frame(maxWidth: .infinity).frame(height: 1) }
                        }.padding(.top, 12)
                        if let g = g, !g.ok { WarnBox(markdown: g.msg).padding(.top, 12) }
                        Button(isToday ? "See workout" : "Preview") { model.go(.preview(day: d)) }
                            .buttonStyle(StrataButtonStyle(kind: isToday ? .violet : .plain)).padding(.top, 14)
                    }.card()
                }
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    Text("\(w) · Muscle").labelStyle()
                    Text("Missed lift").title2Style().padding(.top, 4).padding(.bottom, 2)
                    RichText(markdown: "Nothing logged that day. The rotation just continues: next up is **\(e.plan[e.nextDay()]?.name ?? "")**.").bodyStyle().padding(.top, 8)
                }.card()
            }
        case "office":
            let c = e.cardioOn(date, "office")
            VStack(alignment: .leading, spacing: 0) {
                Text("\(w) · Heart").labelStyle(Theme.coral)
                Text("Office day").title2Style().padding(.top, 4).padding(.bottom, 2)
                RichText(markdown: "Your walks to and from work are today's cardio. Aim for **10,000 steps** at a pace where you could talk but not sing.").bodyStyle().padding(.top, 8)
                if let c = c {
                    HStack {
                        Text("\(Fmt.nf(c.steps ?? 0)) steps logged").nameStyle(color: Theme.coral)
                        Spacer()
                        Button("Edit") { model.sheet = .editCardio(date: date, type: "office") }.buttonStyle(LinkButtonStyle())
                    }.padding(.top, 14)
                } else if isToday || date < e.today {
                    HStack(spacing: 10) {
                        StepField(title: nil, placeholder: "10,000", text: $steps, keyboard: .numberPad, alignRight: false)
                        Button("Log steps") {
                            model.mutate { $0.logSteps(date: date, input: steps) }
                            steps = ""
                        }.buttonStyle(StrataButtonStyle(kind: .coral, hPad: 22, height: 44)).fixedSize()
                    }.padding(.top, 14)
                }
            }.card()
        case "vo2":
            let c = Dates.weekDates(Dates.mondayOf(date)).compactMap { e.cardioOn($0, "4x4") }.first
            let hr = e.rcHR()
            VStack(alignment: .leading, spacing: 0) {
                Text("\(w) · Heart").labelStyle(Theme.coral)
                Text("4×4 intervals").title2Style().padding(.top, 4).padding(.bottom, 2)
                if let c = c {
                    RichText(markdown: "Done this week: **\(jsMinutes(c.intervals ?? 4)) intervals**" + ((c.min ?? 0) != 0 ? " in \(jsMinutes(c.min!)) min" : "") + " on \(Dates.fmtD(c.date, .init(weekday: .long))).").bodyStyle().padding(.top, 8)
                } else {
                    RichText(markdown: "Treadmill. 4 minutes hard, 3 minutes easy, repeated. " + (hr.map { "Hard target **\($0.hard[0])–\($0.hard[1]) bpm**." } ?? "Set your age in Settings for heart-rate targets.")).bodyStyle().padding(.top, 8)
                    if isToday {
                        Button("Start 4×4") { model.navigate(.pickCardio) }.buttonStyle(StrataButtonStyle(kind: .coral)).padding(.top, 14)
                        Button("How the 4×4 works") { model.navigate(.howTheFourByFourWorks) }
                            .buttonStyle(LinkButtonStyle()).frame(maxWidth: .infinity).padding(.top, 6)
                    } else {
                        Button("Preview") { model.navigate(.howTheFourByFourWorks) }.buttonStyle(StrataButtonStyle()).padding(.top, 14)
                    }
                }
            }.card()
        case "z2", "walk":
            let type = e.catalog.ctype[slot]!
            let c = Dates.weekDates(Dates.mondayOf(date)).compactMap { e.cardioOn($0, type) }.first
            let hr = e.rcHR()
            VStack(alignment: .leading, spacing: 0) {
                Text("\(w) · Heart").labelStyle(Theme.coral)
                Text(e.catalog.slotName[slot] ?? "").title2Style().padding(.top, 4).padding(.bottom, 2)
                RichText(markdown: slot == "z2"
                    ? "**45–60 min** at a pace where you can talk in full sentences. Treadmill 5.5 km/h at 8% incline." + (hr.map { " Target **\($0.z2[0])–\($0.z2[1]) bpm**." } ?? "")
                    : "Easy pace outside, **45–90 min**. Or full rest if you feel beaten up.").bodyStyle().padding(.top, 8)
                if let c = c {
                    Text("Done · \(jsMinutes(c.min ?? 0)) min on \(Dates.fmtD(c.date, .init(weekday: .long)))").nameStyle(color: Theme.coral).padding(.top, 12)
                } else if isToday {
                    Button("Start") { model.navigate(.pickCardio) }.buttonStyle(StrataButtonStyle(kind: .coral)).padding(.top, 14)
                    Text("Already did it? Log the minutes:").smallStyle().padding(.top, 10)
                    HStack(spacing: 10) {
                        StepField(title: nil, text: minutesBinding(default: slot == "z2" ? "50" : "60"), keyboard: .numberPad, big: true, alignRight: false)
                        Button("Log \(slot == "z2" ? "Zone 2" : "walk")") {
                            let v = Double(minutes.isEmpty ? (slot == "z2" ? "50" : "60") : minutes) ?? 0
                            model.mutate { $0.logMinutes(slot: slot, min: v) }
                        }.buttonStyle(StrataButtonStyle(kind: .coral, hPad: 22, height: 44)).fixedSize()
                    }.padding(.top, 14)
                }
            }.card()
        default:
            VStack(alignment: .leading, spacing: 0) {
                Text(w).labelStyle()
                Text("Rest").title2Style().padding(.top, 4).padding(.bottom, 2)
                Text("Recovery is where the adaptation happens.").bodyStyle().padding(.top, 8)
            }.card()
        }
    }

    private func minutesBinding(default d: String) -> Binding<String> {
        Binding(get: { minutes.isEmpty ? d : minutes }, set: { minutes = $0.filter(\.isNumber) })
    }

    // MARK: can't train → home session

    @ViewBuilder
    private func homeCard(_ e: Engine, date: String, isToday: Bool) -> some View {
        let sk = e.skipOn(date)!, w = when(e, date, isToday)
        let undo = Button("Undo · I can train after all") { model.mutate { $0.undoSkip(date) } }
            .buttonStyle(LinkButtonStyle()).frame(maxWidth: .infinity).padding(.top, 4)
        if sk.why == "sick" {
            VStack(alignment: .leading, spacing: 0) {
                Text("\(w) · Rest").labelStyle()
                Text("Recover first").title2Style().padding(.top, 4).padding(.bottom, 2)
                RichText(markdown: "No workout today. Sleep, fluids, an easy walk only if you feel like it. Your rotation waits: **\(e.plan[e.nextDay()]?.name ?? "")** is still next.").bodyStyle().padding(.top, 8)
            }.card()
            if isToday { undo }
        } else if let H = e.catalog.home[sk.key] {
            let col = Theme.ring(H.ring), lbl = ["m": "Muscle", "h": "Heart", "b": "Bone + Muscle"][H.ring]!
            VStack(alignment: .leading, spacing: 0) {
                Text("\(w) · At home · \(lbl)").labelStyle(col)
                Text(H.name).title2Style().padding(.top, 4).padding(.bottom, 2)
                Text("~\(H.min) min · no gym needed" + (sk.slot == "lift" ? " · \(e.plan[e.nextDay()]?.name ?? "") moves to your next lift day" : "")).metaStyle()
                VStack(spacing: 0) {
                    ForEach(H.moves.indices, id: \.self) { i in
                        let m = H.moves[i]
                        VStack(alignment: .leading, spacing: 2) {
                            Text(m[0]).nameStyle()
                            Text("\(m[1]) · \(m[2])").metaStyle()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 10)
                        .overlay(alignment: .top) { if i > 0 { Rectangle().fill(Theme.line).frame(height: 1) } }
                    }
                }.padding(.top, 8)
                if (sk.done ?? 0) != 0 {
                    Text("Done · momentum kept").nameStyle(color: col).padding(.top, 12)
                } else if isToday {
                    Button("Mark done") { model.mutate { $0.homeDone(date) } }
                        .buttonStyle(StrataButtonStyle(color: col)).padding(.top, 14)
                }
            }.card(border: col.opacity(0.33))
            if isToday && (sk.done ?? 0) == 0 { undo }
        }
    }

    // MARK: "Next lift in your rotation", "Cardio first", "Log a walk"

    @ViewBuilder
    private func otherOptions(_ slot: String) -> some View {
        let showCardio = slot != "vo2" && slot != "z2" && slot != "walk"
        let showWalk = slot != "office" && slot != "z2" && slot != "walk"
        if showCardio || showWalk {
            HStack(spacing: 8) {
                if showCardio {
                    Button(slot == "lift" ? "Cardio first" : "Start cardio") { model.navigate(.pickCardio) }.buttonStyle(StrataButtonStyle(small: true))
                }
                if showWalk { Button("Log a walk") { model.sheet = .walk }.buttonStyle(StrataButtonStyle(small: true)) }
            }
        }
    }

    /// Recent sleep (last 7 nights) and steps (last 7 complete days) from Apple Health, if any.
    private func healthSignals(today t: String) -> HealthSignals {
        HealthSignals(
            sleepHours: (0..<7).compactMap { model.syncedSleep(on: Dates.addDays(t, -$0)) }.filter { $0 > 0 },
            steps: (1...7).compactMap { model.syncedSteps(on: Dates.addDays(t, -$0)) }.filter { $0 > 0 }.map(Double.init),
            vo2Recent: vo2Values(daysAgo: 0..<Config.Insights.vo2RecentDays),
            vo2Prior: vo2Values(daysAgo: Config.Insights.vo2RecentDays..<(Config.Insights.vo2RecentDays + Config.Insights.vo2PriorDays)))
    }

    private func vo2Values(daysAgo range: Range<Int>) -> [Double] {
        let now = Date()
        return model.vo2.filter {
            let days = Int(now.timeIntervalSince($0.date) / 86_400)
            return range.contains(days)
        }.map(\.value)
    }

    // MARK: what happened today

    /// Strata's own entries for today (workouts, cardio, walks) plus workouts Apple Health has
    /// from the Watch or other apps.
    private func todayLog(_ e: Engine, t: String) -> some View {
        let own = e.historyItems().filter { $0.date == t }
        let health = model.newTodayWorkouts
        return VStack(spacing: 0) {
            HStack {
                Text("Today").labelStyle(); Spacer()
                if !own.isEmpty || !health.isEmpty { Text("\(own.count + health.count) logged").smallStyle() }
            }.padding(.horizontal, 4).padding(.bottom, 6)
            if own.isEmpty && health.isEmpty {
                Text("Nothing logged yet today.").font(.inter(size: 14)).foregroundStyle(Theme.muted)
                    .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 4).padding(.vertical, 8)
            }
            ForEach(own.indices, id: \.self) { i in ownRow(e, own[i], first: i == 0) }
            ForEach(health.indices, id: \.self) { i in healthRow(health[i], first: own.isEmpty && i == 0) }
        }.card(tight: true)
    }

    private func logRow(icon: String, tint: Color, name: String, meta: String, right: String, first: Bool, chevron: Bool) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(tint.opacity(0.18))
                IconView(d: icon, size: 20, color: tint, line: 2.2)
            }.frame(width: 40, height: 40)
            VStack(alignment: .leading, spacing: 2) { Text(name).nameStyle(); Text(meta).metaStyle() }
            Spacer(minLength: 0)
            Text(right).font(.inter(size: 15, weight: .semibold))
            if chevron { IconView(d: Icon.chev, size: 18, color: Color(hex: "#A9AEBD"), line: 2.4) }
        }
        .padding(.vertical, 10).padding(.horizontal, 4)
        .overlay(alignment: .top) { if !first { Rectangle().fill(Theme.line).frame(height: 1) } }
        .contentShape(Rectangle())
    }

    private func ownRow(_ e: Engine, _ it: HistoryItem, first: Bool) -> some View {
        let r = e.historyRow(it)
        let lift = r.icon == "lift" || r.icon == "home"
        var meta = r.meta
        if it.kind == "lift", it.date == e.today, let w = model.todayLiftStats {
            let extra = [w.avgHR.map { "\(jsMinutes($0.rounded())) bpm" }, w.kcal.map { "\(Fmt.nf($0.rounded())) kcal" }].compactMap { $0 }
            if !extra.isEmpty { meta += " · " + extra.joined(separator: " · ") }
        }
        return Button {
            if it.kind == "lift" { model.go(.detail(index: it.index)) }
            else { model.sheet = .editCardio(date: it.date, type: it.kind) }
        } label: {
            logRow(icon: r.icon == "lift" ? Icon.dumbbell : r.icon == "home" ? Icon.home : r.icon == "heart" ? Icon.heart : Icon.walk,
                   tint: lift ? Theme.violet : Theme.coral, name: r.name, meta: meta, right: r.right, first: first, chevron: true)
        }.buttonStyle(.plain)
    }

    private func healthRow(_ w: HealthWorkoutRow, first: Bool) -> some View {
        logRow(icon: w.isStrength ? Icon.dumbbell : Icon.walk, tint: w.isStrength ? Theme.violet : Theme.coral,
               name: w.name, meta: w.start.formatted(date: .omitted, time: .shortened) + " · Apple Health",
               right: "\(Int(w.minutes.rounded())) min", first: first, chevron: false)
    }

    // MARK: the week strip

    private func weekCard(_ e: Engine) -> some View {
        let sel = model.selDay ?? Dates.weekday(e.today)
        return VStack(spacing: 0) {
            HStack {
                Text("This week").labelStyle(); Spacer(); Text("Tap a day").smallStyle()
            }.padding(.horizontal, 4).padding(.vertical, 2)
            HStack(spacing: 4) {
                ForEach(e.weekStrip(), id: \.w) { it in
                    DayButton(item: it, selected: it.w == sel) {
                        model.selDay = it.w == Dates.weekday(e.today) ? nil : it.w
                    }
                }
            }.padding(.top, 12)
        }.card(tight: true)
    }
}


struct DayButton: View {
    let item: WeekStripItem
    let selected: Bool
    let action: () -> Void
    var body: some View {
        let col = Color(hex: item.color)
        Button(action: action) {
            VStack(spacing: 5) {
                Text(String(Catalog.shared.wdShort[String(item.w)]!.first!)).font(.inter(size: 11, weight: .semibold))
                ZStack {
                    if item.done {
                        Circle().fill(col)
                        IconView(d: Icon.check, size: 12, color: Color(hex: "#0E1018"), line: 3)
                    } else {
                        Circle().strokeBorder(col, style: StrokeStyle(lineWidth: 2, dash: item.kind == "skip" ? [3, 2.5] : [])).opacity(0.9)
                    }
                }.frame(width: 22, height: 22)
                Text(item.label).font(.inter(size: 10, weight: .semibold)).tracking(0.2)
            }
            .foregroundStyle(selected ? Color.white : Theme.muted)
            .frame(maxWidth: .infinity).padding(.top, 8).padding(.bottom, 7)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(selected ? 0.14 : 0.05)))
            .overlay { if item.today { RoundedRectangle(cornerRadius: 14).strokeBorder(Color.white.opacity(0.55), lineWidth: 1.5) } }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(Catalog.shared.wdLong[String(item.w)]!): \(item.label)\(item.done ? ", done" : "")")
    }
}

/// `.warnbox`
struct WarnBox: View {
    let markdown: String
    var body: some View {
        RichText(markdown: markdown).font(.inter(size: 13)).foregroundStyle(Color(hex: "#F7D08A")).lineSpacing(3)
            .fixedSize(horizontal: false, vertical: true)
            .padding(12).frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 16).fill(Theme.amber.opacity(0.1)))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Theme.amber.opacity(0.3)))
    }
}
