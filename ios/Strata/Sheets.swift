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

/// "I want something else" (web `elseSheet()`): today's own pick replaces the weekday's plan.
struct SomethingElseSheet: View {
    @EnvironmentObject var model: AppModel
    var body: some View {
        if let e = model.engine { content(e) } else { Color.clear }
    }
    @ViewBuilder private func content(_ e: Engine) -> some View {
        let t = e.today, mon = Dates.mondayOf(t), cur = e.weekPlan(mon)[Dates.weekday(t)] ?? "rest"
        let nd = e.nextDay(), owed = e.liftOwed(mon)
        var opts: [(String, String, String)] = []
        let _ = {
            if cur != "lift" && e.liftedOn(t) == nil {
                opts.append(("lift", "Lift: \(e.plan[nd]?.name ?? "")",
                             "\(owed ? "Missed earlier this week · " : "")\(e.requiredItems(nd).count) main lifts · ~\(jsMinutes(e.minutesFor(nd))) min\(e.isLegs(nd) ? " · jumps first" : "")"))
            }
            if cur != "z2" { opts.append(("z2", "Zone 2 walk", "45–60 min, conversational. Treadmill at incline works great.")) }
            if cur != "vo2" && !e.slotDone("vo2", t, mon) { opts.append(("vo2", "4×4 intervals", "4 minutes hard, 3 easy, repeated.")) }
            if cur != "walk" { opts.append(("walk", "Long walk", "Easy pace outside, 45–90 min.")) }
        }()
        SheetChrome {
            Text("Today").labelStyle()
            Text("What do you feel like?").title2Style(20).padding(.top, 4)
            Text("Your pick replaces today's plan. Nothing is lost: the rotation and your weekly goals stay as they are.").bodyStyle().padding(.top, 4)
            ForEach(opts, id: \.0) { o in
                Button {
                    model.mutate { $0.setSlotOver(t, o.0); return ["lift": "Today is a lift day", "z2": "Zone 2 today. Treadmill incline works", "vo2": "4×4 today", "walk": "Long walk today"][o.0] }
                    model.selDay = nil; model.sheet = nil
                } label: {
                    OptRow(title: o.1, meta: o.2) { IconView(d: Icon.chev, size: 18, color: Color(hex: "#A9AEBD"), line: 2.4) }
                }.buttonStyle(.plain).padding(.top, 8)
            }
            if e.db.slotOver?[t] != nil {
                Button {
                    model.mutate { $0.clearSlotOver(t); return "Back to the plan" }
                    model.selDay = nil; model.sheet = nil
                } label: {
                    OptRow(title: "Back to the plan", meta: e.catalog.slotName[e.basePlan()[Dates.weekday(t)] ?? "rest"]) { IconView(d: Icon.chev, size: 18, color: Color(hex: "#A9AEBD"), line: 2.4) }
                }.buttonStyle(.plain).padding(.top, 8)
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
