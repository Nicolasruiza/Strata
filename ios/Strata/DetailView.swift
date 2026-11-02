import SwiftUI
import StrataCore

/// A number the user can edit in place (`.ein`). It only writes back when the user changes it:
/// opening a session must never rewrite the stored volume.
struct NumField: View {
    let value: Double?
    var width: CGFloat = 52
    let commit: (Double?) -> Void
    @State private var text: String

    init(value: Double?, width: CGFloat = 52, commit: @escaping (Double?) -> Void) {
        self.value = value; self.width = width; self.commit = commit
        _text = State(initialValue: value.map(jsMinutes) ?? "")
    }

    var body: some View {
        TextField("", text: $text)
            .keyboardType(.decimalPad).multilineTextAlignment(.center)
            .font(.inter(size: 15, weight: .bold)).frame(width: width, height: 40)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.25)))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.line))
            .onChange(of: text) { _, new in
                let parsed: Double? = new.isEmpty ? nil : Double(new)
                if new.isEmpty || parsed != nil, parsed != value { commit(parsed) }
            }
    }
}

/// One logged session (app.js `detailView`).
struct DetailView: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.safeTop) private var safeTop
    let index: Int
    @State private var confirmDelete = false

    var body: some View {
        let e = model.engine!
        if index >= 0 && index < e.db.history.count {
            let s = e.db.history[index]
            let nm = e.plan[s.day]?.name ?? "Workout"
            let j = e.cardioOn(s.date, "jumps") != nil
            let req = Set(e.requiredItems(s.day).map(\.id)), hasPlan = e.plan[s.day] != nil
            let sw = s.swaps ?? [:]
            let wi = e.warmIds(s.day)
            let ids = s.entries.keys.filter { !wi.contains($0) }
            let origOf: (String) -> String = { id in sw.keys.sorted().first { sw[$0] == id } ?? id }
            let main = ids.filter { req.contains(origOf($0)) || !hasPlan }
            let extra = ids.filter { !main.contains($0) }
            let bonusPlan = (e.plan[s.day]?.blocks ?? []).filter { $0.t.range(of: "^bonus", options: [.regularExpression, .caseInsensitive]) != nil }.flatMap(\.items)
            ScrollView {
                VStack(spacing: 0) {
                    ZStack(alignment: .topLeading) {
                        Hero(eyebrow: Dates.fmtD(s.date, .init(weekday: .long, month: .short, day: true, year: true)), title: nm,
                             sub: ((s.min ?? 0) != 0 ? "\(jsMinutes(s.min!)) min · " : "") + "\(Fmt.nf(s.vol ?? 0)) lb moved" + ((s.lowEnergy ?? false) ? " · lighter day" : ""),
                             short: true, brand: false)
                        GlassButton(action: { model.go(.history) }, accessibility: "Back") { IconView(d: Icon.back, size: 18, color: .white, line: 2.4) }
                            .padding(.leading, 16).padding(.top, 14 + safeTop)
                    }
                    VStack(spacing: 12) {
                        if e.isLegs(s.day) || j {
                            HStack(spacing: 12) {
                                ZStack { Circle().fill(Theme.mint.opacity(0.16)); IconView(d: Icon.bone, size: 20, color: Theme.mint) }.frame(width: 40, height: 40)
                                VStack(alignment: .leading, spacing: 2) { Text("Jumps warm-up").nameStyle(); Text("Pogo hops 3 × 10 · Box jumps 3 × 5").metaStyle() }
                                Spacer(minLength: 0)
                                WebSwitch(isOn: Binding(get: { j }, set: { _ in model.mutate { $0.toggleSessionJumps(index); return nil } }), label: "Jumps done")
                            }.padding(4).card(tight: true)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            HStack { Text("Main lifts").labelStyle(); Spacer(); Text("Tap a number to edit").smallStyle() }
                            if main.isEmpty { Text("None").font(.inter(size: 14)).foregroundStyle(Theme.muted).padding(26).frame(maxWidth: .infinity) }
                            else { ForEach(main.indices, id: \.self) { i in lineRow(e, s, main[i], first: i == 0) } }
                        }.card()
                        if !extra.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Bonus & extras").labelStyle()
                                ForEach(extra.indices, id: \.self) { i in lineRow(e, s, extra[i], first: i == 0) }
                            }.card()
                        } else if !bonusPlan.isEmpty {
                            HStack(spacing: 12) {
                                ZStack { Circle().fill(Color.white.opacity(0.1)); SVGPathShape(d: Icon.star).fill(Theme.soft).frame(width: 20, height: 20) }.frame(width: 40, height: 40)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Bonus").nameStyle()
                                    Text(bonusPlan.map { Fmt.cleanN($0.n) }.joined(separator: " · ")).metaStyle()
                                }
                                Spacer(minLength: 0)
                                Chip(text: "Skipped")
                            }.padding(4).card(tight: true, dashed: true)
                        }
                        Button("Delete this session") { confirmDelete = true }.buttonStyle(LinkButtonStyle(color: Color(hex: "#FF8A70"))).frame(maxWidth: .infinity)
                    }.padding(.horizontal, Theme.gutter).padding(.top, 14).padding(.bottom, 40)
                }.frame(maxWidth: Theme.maxWidth)
            }
            .alert(e.deleteSessionPrompt, isPresented: $confirmDelete) {
                Button("Delete", role: .destructive) { model.mutate { $0.deleteSession(index) }; model.go(.history) }
                Button("Cancel", role: .cancel) {}
            }
        } else { Color.clear.onAppear { model.go(.history) } }
    }

    private func lineRow(_ e: Engine, _ s: Session, _ id: String, first: Bool) -> some View {
        let ex = e.exById(id) ?? Ex(id: id, n: id), en = s.entries[id]!
        return VStack(spacing: 6) {
            HStack(spacing: 12) {
                ZStack { Circle().fill(Theme.violet); IconView(d: Icon.check, size: 14, color: Color(hex: "#0E1018"), line: 3) }.frame(width: 26, height: 26)
                VStack(alignment: .leading, spacing: 2) {
                    Text(Fmt.cleanN(ex.n)).nameStyle()
                    Text("\(Fmt.isSec(ex) ? "seconds" : "reps")\(Fmt.perLeg(ex))").metaStyle()
                }
                Spacer(minLength: 0)
                if ex.isBodyweight && en.w == 0 { Text("bodyweight").smallStyle() }
                else {
                    HStack(spacing: 4) {
                        NumField(value: en.w, width: 72) { v in model.mutate { $0.editSessionWeight(model.historyIndexForDetail, id: id, w: v ?? 0); return nil } }
                        Text("lb").smallStyle()
                    }
                }
            }
            HStack(spacing: 6) {
                ForEach(en.reps.indices, id: \.self) { k in
                    NumField(value: en.reps[k]) { v in model.mutate { $0.editSessionRep(model.historyIndexForDetail, id: id, set: k, value: v); return nil } }
                }
                Text(Fmt.isSec(ex) ? "s" : "").smallStyle()
                Spacer(minLength: 0)
            }.padding(.leading, 38)
        }
        .padding(.vertical, 10)
        .overlay(alignment: .top) { if !first { Rectangle().fill(Theme.line).frame(height: 1) } }
    }
}

extension AppModel {
    var historyIndexForDetail: Int { if case .detail(let i) = screen { return i } else { return 0 } }
}
