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

/// "Change activity" (web `elseSheet()`): Strength / Cardio / Mobility tabs, pick one, then "Use … today".
struct SomethingElseSheet: View {
    @EnvironmentObject var model: AppModel
    /// "Add activity": today's plan is done (or a rest day). Same picker, but it starts something extra instead of replacing the plan.
    var add = false
    @State private var tab: String?
    @State private var sel: String?

    private struct Opt { let key: String, name: String, meta: String, img: String?, icon: String, badge: String? }

    var body: some View {
        if let e = model.engine { content(e) } else { Color.clear }
    }

    private func thumbName(_ path: String?) -> String? { path.map { (($0 as NSString).lastPathComponent as NSString).deletingPathExtension } }

    private func options(_ e: Engine, tab: String, rotation: Int, plan: String) -> [Opt] {
        let t = e.today, mon = Dates.mondayOf(t)
        switch tab {
        case "strength":
            return e.days.map { d in
                Opt(key: "lift:\(d)", name: e.plan[d]?.name ?? "",
                    meta: "\(e.requiredItems(d).count) exercises · ~\(jsMinutes(e.minutesFor(d))) min",
                    img: thumbName(e.requiredItems(d).lazy.compactMap { e.catalog.imageName(of: $0.id) }.first),
                    icon: Icon.dumbbell, badge: d == rotation ? "Next in rotation" : nil)
            }
        case "mobility":
            return Config.Mobility.sessions.map { s in
                Opt(key: "mob:\(s.id)", name: s.label, meta: "\(Config.Mobility.exercises.count) moves · a bonus, any day",
                    img: "mob_glide_start", icon: Icon.walk, badge: nil)
            }
        default:
            var o: [Opt] = []
            if !e.slotDone("vo2", t, mon) {
                o.append(Opt(key: "vo2", name: "4×4 intervals", meta: "4 min hard, 3 easy · ~40 min", img: "treadmill", icon: Icon.heart, badge: plan == "vo2" ? "Planned today" : nil))
            }
            o.append(Opt(key: "z2", name: "Zone 2 walk", meta: "Conversational · 45–60 min", img: "treadmill", icon: Icon.heart, badge: plan == "z2" || plan == "office" ? "Planned today" : nil))
            o.append(Opt(key: "walk", name: "Long walk", meta: "Easy pace outside · 45–90 min", img: nil, icon: Icon.walk, badge: plan == "walk" ? "Planned today" : nil))
            o.append(Opt(key: "other", name: "Run, bike, swim, row…", meta: "Pick the activity next", img: nil, icon: Icon.heart, badge: nil))
            return o
        }
    }

    @ViewBuilder private func content(_ e: Engine) -> some View {
        let t = e.today, mon = Dates.mondayOf(t)
        let n = e.days.count
        let rotation = e.db.active.map { ($0.day % n) + 1 } ?? e.nextDay()
        let plan = e.planSlot(t)
        let cur = e.weekPlan(mon)[Dates.weekday(t)] ?? "rest"
        let curDay = e.liftSlots(mon)[Dates.weekday(t)]?.day
        let defTab = add ? (e.liftedOn(t) == nil ? "strength" : "cardio") : (cur == "lift" || (e.liftOwed(mon) && e.liftedOn(t) == nil) ? "strength" : "cardio")
        let tb = tab ?? defTab
        let opts = options(e, tab: tb, rotation: rotation, plan: plan)
        let defSel = tb == "strength" ? "lift:\(cur == "lift" && !add ? (curDay ?? rotation) : rotation)"
            : tb == "cardio" ? (opts.first { $0.key == cur }?.key ?? opts.first { $0.badge != nil }?.key ?? opts.first?.key ?? "")
            : opts.first?.key ?? ""
        let s = sel ?? defSel
        let accent = tb == "strength" ? Theme.violet : tb == "mobility" ? Theme.mint : Theme.coral
        let chosen = opts.first { $0.key == s }
        SheetChrome {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(add ? "Add activity" : "Change activity").title2Style(24)
                    Text(add ? "Something extra today. Your plan stays as it is." : "Choose what you want to do today.").bodyStyle()
                }
                Spacer(minLength: 0)
                Button { model.sheet = nil } label: { IconView(d: Icon.close, size: 20, color: .white, line: 2.2).frame(width: 36, height: 36) }
                    .accessibilityLabel("Close")
            }
            HStack(spacing: 8) {
                ForEach([("strength", "Strength"), ("cardio", "Cardio"), ("mobility", "Mobility")], id: \.0) { k, l in
                    Button { tab = k; sel = nil } label: {
                        Text(l).font(.inter(size: 14, weight: .bold)).foregroundStyle(.white)
                            .frame(maxWidth: .infinity, minHeight: 40)
                            .background(Capsule().fill(tb == k ? AnyShapeStyle(LinearGradient(colors: [Color(hex: "#AC9EFF"), Color(hex: "#7C6CF0")], startPoint: .topLeading, endPoint: .bottomTrailing)) : AnyShapeStyle(Color.clear)))
                            .overlay(Capsule().strokeBorder(tb == k ? Color.clear : Color.white.opacity(0.22)))
                    }.buttonStyle(.plain)
                }
            }.padding(.top, 16)
            VStack(spacing: 8) {
                ForEach(opts, id: \.key) { o in
                    let on = o.key == s
                    Button { sel = o.key } label: {
                        HStack(spacing: 12) {
                            Group {
                                if let img = o.img { BundleImage(name: img) }
                                else { ZStack { accent.opacity(0.14); IconView(d: o.icon, size: 24, color: accent, line: 1.9) } }
                            }.frame(width: 64, height: 56).clipShape(RoundedRectangle(cornerRadius: 12))
                            VStack(alignment: .leading, spacing: 3) {
                                Text(o.name).nameStyle()
                                Text(o.meta).metaStyle()
                                if let b = o.badge {
                                    Text(b.uppercased()).font(.inter(size: 10, weight: .bold)).tracking(0.8).foregroundStyle(accent)
                                        .padding(.horizontal, 6).padding(.vertical, 2)
                                        .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(accent.opacity(0.7)))
                                        .padding(.top, 2)
                                }
                            }
                            Spacer(minLength: 0)
                            ZStack {
                                Circle().strokeBorder(on ? accent : Color.white.opacity(0.4), lineWidth: 1.5)
                                if on { Circle().fill(accent).padding(5) }
                            }.frame(width: 22, height: 22)
                        }
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 18).fill(on ? accent.opacity(0.12) : Theme.glass))
                        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(on ? accent : Theme.line, lineWidth: on ? 1.5 : 1))
                        .contentShape(Rectangle())
                    }.buttonStyle(.plain)
                }
            }.padding(.top, 14)
            if tb == "cardio" {
                Button("Already did it? Log a walk") { model.sheet = .walk }
                    .buttonStyle(LinkButtonStyle(underline: false)).frame(maxWidth: .infinity).padding(.top, 2)
            }
            Button(useLabel(s, chosen)) { use(e, s, rotation: rotation, name: chosen?.name ?? "") }
                .buttonStyle(StrataButtonStyle(kind: tb == "strength" ? .violet : tb == "mobility" ? .mint : .coral))
                .padding(.top, tb == "cardio" ? 6 : 16)
        }
    }

    private func useLabel(_ key: String, _ o: Opt?) -> String {
        if key == "other" { return "Choose the activity" }
        if key.hasPrefix("mob:") { return "Start mobility" }
        return add ? "Start \(o?.name ?? "")" : "Use \(o?.name ?? "this") today"
    }

    private func use(_ e: Engine, _ key: String, rotation: Int, name: String) {
        let t = e.today
        if add && !key.hasPrefix("mob:") {
            model.sheet = nil; model.selDay = nil
            if key.hasPrefix("lift:"), let d = Int(key.dropFirst(5)) { model.go(.preview(day: d)) }
            else { model.pickAct = nil; model.navigate(.pickCardio) }
            return
        }
        if key.hasPrefix("lift:"), let d = Int(key.dropFirst(5)) {
            model.mutate { $0.setLiftDay(t, d == rotation ? nil : d); return "\(name) today" }
        } else if key.hasPrefix("mob:") {
            model.sheet = nil; model.go(.mobility(session: String(key.dropFirst(4)))); return
        } else if key == "other" {
            model.sheet = nil; model.pickAct = nil; model.navigate(.pickCardio); return
        } else {
            model.mutate { $0.setSlotOver(t, key); return "\(name) today" }
        }
        model.selDay = nil; model.sheet = nil
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
