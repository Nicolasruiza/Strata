import SwiftUI
import StrataCore

/// `cantTrainSheet()`
struct CantTrainSheet: View {
    @EnvironmentObject var model: AppModel
    var body: some View {
        SheetChrome {
            Text("Today").labelStyle()
            Text("Can't train today?").title2Style(20).padding(.top, 4)
            Text("No problem. Nothing is lost: the rotation just waits.").bodyStyle().padding(.top, 4)
            let inOffice = model.engine.map { ($0.weekPlan()[Dates.weekday($0.today)] ?? "") == "office" } ?? false
            ForEach(Catalog.shared.skipWhy.filter { !($0[0] == "office" && inOffice) }, id: \.self) { w in
                Button {
                    model.mutate { $0.skipToday(why: w[0]) }
                    model.selDay = nil
                    model.sheet = nil
                } label: {
                    OptRow(title: w[1], meta: w[2]) { IconView(d: Icon.chev, size: 18, color: Color(hex: "#A9AEBD"), line: 2.4) }
                }.buttonStyle(.plain).padding(.top, 8)
            }
        }
    }
}

/// "Swap workout" (web `elseSheet(step)`): category first (Strength / Cardio / Walk), then the options, with the recommendation in colour.
struct SomethingElseSheet: View {
    @EnvironmentObject var model: AppModel
    @State private var step: String?
    var body: some View {
        if let e = model.engine { content(e) } else { Color.clear }
    }

    private func pick(_ slot: String, toast: String, preview: Int? = nil, then: (() -> Void)? = nil) {
        let t = model.engine?.today ?? ""
        model.mutate { $0.setSlotOver(t, slot); return toast }
        model.selDay = nil; model.sheet = nil
        if let p = preview { model.go(.preview(day: p)) }
        then?()
    }

    private func row(_ title: String, _ meta: String, rec: Bool, accent: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            OptRow(title: title + (rec ? "  ·  Recommended" : ""), meta: meta, on: rec, accent: accent, dim: !rec) {
                IconView(d: Icon.chev, size: 18, color: Color(hex: "#A9AEBD"), line: 2.4)
            }
        }.buttonStyle(.plain).padding(.top, 8)
    }

    @ViewBuilder private func content(_ e: Engine) -> some View {
        let t = e.today, mon = Dates.mondayOf(t), nd = e.nextDay()
        let owed = e.liftOwed(mon) && e.liftedOn(t) == nil, plan = e.planSlot(t)
        let rec = owed ? "lift" : plan
        let cat = rec == "lift" ? "strength" : rec == "walk" ? "walk" : "cardio"
        SheetChrome {
            Text("Today").labelStyle()
            switch step {
            case "strength":
                Text("Which lift?").title2Style(20).padding(.top, 4)
                Text("Your pick today. The rotation keeps going from the recommended one.").bodyStyle().padding(.top, 4)
                ForEach(e.days, id: \.self) { d in
                    let last = e.db.history.filter { $0.day == d }.map(\.date).max()
                    row(e.plan[d]?.name ?? "", "\(last.map { "Last done " + Dates.fmtD($0, .init(weekday: .long)) } ?? "Not done yet") · \(e.requiredItems(d).count) main lifts · ~\(jsMinutes(e.minutesFor(d))) min\(e.isLegs(d) ? " · jumps first" : "")",
                        rec: d == nd, accent: Theme.violet) {
                        pick("lift", toast: "Today is a lift day", preview: d == nd ? nil : d)
                    }
                }
            case "cardio":
                Text("Which cardio?").title2Style(20).padding(.top, 4)
                Text("Pick the kind of session. You choose the machine next.").bodyStyle().padding(.top, 4)
                if !e.slotDone("vo2", t, mon) {
                    row("4×4 intervals", "4 minutes hard, 3 easy, repeated.", rec: rec == "vo2", accent: Theme.coral) { pick("vo2", toast: "4×4 today") }
                }
                row("Zone 2 walk", "45–60 min, conversational. Treadmill incline works great.", rec: rec == "z2" || rec == "office", accent: Theme.coral) { pick("z2", toast: "Zone 2 today. Treadmill incline works") }
                row("Run, bike, swim, row…", "Any cardio. Pick the activity on the next screen.", rec: false, accent: Theme.coral) {
                    model.sheet = nil; model.pickAct = nil; model.navigate(.pickCardio)
                }
            case "walk":
                Text("Walk").title2Style(20).padding(.top, 4)
                Text("Easy movement still counts for your heart.").bodyStyle().padding(.top, 4)
                row("Long walk", "Easy pace outside, 45–90 min.", rec: rec == "walk", accent: Theme.coral) { pick("walk", toast: "Long walk today") }
                row("I already walked", "Log the minutes.", rec: false, accent: Theme.coral) { model.sheet = .walk }
            default:
                Text("What do you feel like?").title2Style(20).padding(.top, 4)
                Text("Your pick replaces today's plan. Nothing is lost: your weekly goals stay as they are.").bodyStyle().padding(.top, 4)
                row("Strength", owed ? "You missed a lift earlier this week." : "Upper and lower body lifts.", rec: cat == "strength", accent: Theme.violet) { step = "strength" }
                row("Cardio", "4×4, Zone 2, run, bike, swim…", rec: cat == "cardio", accent: Theme.coral) { step = "cardio" }
                row("Walk", "Easy walk, or log one you already did.", rec: cat == "walk", accent: Theme.coral) { step = "walk" }
            }
            if step != nil {
                Button("Back") { step = nil }.buttonStyle(LinkButtonStyle()).frame(maxWidth: .infinity).padding(.top, 12)
            }
            if e.db.slotOver?[t] != nil || e.isCatchUp() {
                Button("Keep the plan: \(e.catalog.slotName[plan] ?? plan)") {
                    pick(plan, toast: "Keeping the plan")
                }.buttonStyle(LinkButtonStyle()).frame(maxWidth: .infinity).padding(.top, step == nil ? 12 : 4)
            }
        }
    }
}

/// "Log a walk" sheet
struct WalkSheet: View {
    @EnvironmentObject var model: AppModel
    @State private var minutes = "45"
    var body: some View {
        SheetChrome {
            Text("Log a walk").title2Style(20)
            StepField(title: "Minutes", text: $minutes, keyboard: .numberPad).padding(.top, 12)
            HStack(spacing: 10) {
                Button("Zone 2") { log("z2") }.buttonStyle(StrataButtonStyle())
                Button("Easy walk") { log("walk") }.buttonStyle(StrataButtonStyle(kind: .primary))
            }.padding(.top, 14)
        }
    }
    private func log(_ type: String) {
        let v = Double(minutes) ?? 0
        if v == 0 { return }
        model.mutate { $0.logWalk(type: type, min: v) }
        model.sheet = nil
    }
}

/// `cardioSheet(d, t)`: edit or delete a logged cardio entry
struct EditCardioSheet: View {
    @EnvironmentObject var model: AppModel
    let date: String, type: String
    @State private var value = ""

    private static func field(_ type: String, _ c: CardioEntry?) -> (String, Double) {
        if type == "office" { return ("steps", c?.steps ?? 0.0) }
        if type == "4x4" { return ("intervals", c?.intervals ?? 4.0) }
        return ("minutes", c?.min ?? 0.0)
    }

    var body: some View {
        let e = model.engine!
        let c = e.cardioOn(date, type)
        let names = ["office": "Office day", "4x4": "4×4 intervals", "z2": "Zone 2 walk", "walk": "Walk", "cardio": "Cardio", "home": "Home session"]
        let field = Self.field(type, c)
        SheetChrome {
            Text(Dates.fmtD(date, .init(weekday: .long, month: .short, day: true))).labelStyle()
            Text(names[type] ?? type).title2Style(20).padding(.top, 4)
            StepField(title: field.0, text: Binding(get: { value.isEmpty ? jsMinutes(field.1) : value }, set: { value = $0 }), keyboard: .numberPad)
                .padding(.top, 12)
            HStack(spacing: 10) {
                Button("Delete") {
                    model.confirmDelete = (date, type)
                }.buttonStyle(StrataButtonStyle()).foregroundStyle(Color(hex: "#FF8A70"))
                Button("Save") {
                    let v = Double(value.isEmpty ? jsMinutes(field.1) : value) ?? 0
                    model.mutate { $0.editCardio(date: date, type: type, value: v); return nil }
                    model.sheet = nil
                }.buttonStyle(StrataButtonStyle(kind: .primary))
            }.padding(.top, 14)
        }
    }
}
