import SwiftUI
import StrataCore

/// Workout options (`liftMenu`)
struct WorkoutMenuSheet: View {
    @EnvironmentObject var model: AppModel
    @State private var confirmDiscard = false
    var body: some View {
        let e = model.engine!, A = e.db.active
        SheetChrome {
            Text(A.flatMap { e.plan[$0.day]?.name } ?? "").title2Style(20)
            Button { model.menuOpen = false; model.requestEndSession() } label: {
                OptRow(title: "Finish workout") { IconView(d: Icon.chev, size: 18, color: Theme.muted, line: 2.4) }
            }.buttonStyle(.plain).padding(.top, 8)
            Button { model.mutate { $0.toggleLighterDay() }; model.menuOpen = false } label: {
                VStack(alignment: .leading) {
                    OptRow(title: "Lighter day\((A?.lowEnergy ?? false) ? " · on" : "")", meta: "85% weight, 2 sets, weights don't go up") {
                        IconView(d: Icon.chev, size: 18, color: Theme.muted, line: 2.4)
                    }
                }
            }.buttonStyle(.plain).padding(.top, 8)
            Button { confirmDiscard = true } label: {
                OptRow(title: "Discard workout") { EmptyView() }.foregroundStyle(Color(hex: "#FF8A70"))
            }.buttonStyle(.plain).padding(.top, 8)
        }
        .alert(discardMessage, isPresented: $confirmDiscard) {
            Button("Discard", role: .destructive) { model.menuOpen = false; model.mutate { $0.discardWorkout(); return nil } }
            Button("Cancel", role: .cancel) {}
        }
    }
}

/// "Machine busy?" swap sheet (`swapSheet`)
struct SwapSheet: View {
    @EnvironmentObject var model: AppModel
    var body: some View {
        let e = model.engine!, A = e.db.active!
        let L = e.liftList(), orig = L[e.curIdx()]
        let reqIds = e.requiredItems(A.day).map(\.id)
        let pos = reqIds.firstIndex(of: orig.id)
        let opts = [orig] + (e.ap.altOf[orig.id] ?? [])
        let cur = A.swaps[orig.id] ?? orig.id
        SheetChrome {
            Text("\(pos.map { "Lift \($0 + 1) of \(reqIds.count)" } ?? "Bonus") · Swap").labelStyle()
            Text("Machine busy?").title2Style(20).padding(.top, 4)
            Text("Same movement, different equipment. Each option keeps its own weight history.").font(.system(size: 13)).foregroundStyle(Theme.muted).padding(.top, 4)
            ForEach(opts, id: \.id) { o in
                let w: Double = {
                    var m = e
                    return (A.lowEnergy ?? false) ? m.loEnergyW(m.wOf(o)) : m.wOf(o)
                }()
                Button {
                    model.mutate { $0.applySwap(to: o.id == orig.id ? nil : o.id) }
                    model.swapOpen = false
                } label: {
                    HStack(spacing: 12) {
                        Thumb(path: e.catalog.imageName(of: o.id))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(Fmt.cleanN(o.n)).nameStyle()
                            Text("\(o.id == orig.id ? "Planned · " : "")\(Fmt.wLbl(o, w))").metaStyle()
                        }
                        Spacer(minLength: 0)
                        if cur == o.id { IconView(d: Icon.check, size: 22, color: Theme.violet, line: 3) }
                    }
                    .padding(10).frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 18).fill(cur == o.id ? Theme.violet.opacity(0.1) : Theme.glass))
                    .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(cur == o.id ? Theme.violet : Theme.line))
                }.buttonStyle(.plain).padding(.top, 8)
            }
        }
    }
}

/// "Add a warm-up set" (`warmSheet`)
struct WarmSheet: View {
    @EnvironmentObject var model: AppModel
    var body: some View {
        var m = model.engine!
        let ex = m.shownEx(m.liftList()[m.curIdx()])
        let opts = m.warmupOptions()
        SheetChrome {
            Text(Fmt.cleanN(ex.n)).labelStyle()
            Text("Add a warm-up set").title2Style(20).padding(.top, 4)
            Text("Warm-up sets don't count toward progression.").font(.system(size: 13)).foregroundStyle(Theme.muted).padding(.top, 4)
            if opts.isEmpty {
                Text("Bodyweight lift: do a slow first set of 5 instead.").bodyStyle().padding(.top, 8)
            } else {
                ForEach(opts, id: \.w) { o in
                    Button {
                        model.mutate { $0.addWarmup(w: o.w, r: o.r); return nil }
                        model.warmOpen = false
                    } label: {
                        OptRow(title: "\(jsMinutes(o.w)) lb × \(jsMinutes(o.r))", meta: o.label + (ex.bar != nil ? " · " + Fmt.plateTxt(ex, o.w) : "")) {
                            IconView(d: "M12 5v14M5 12h14", size: 18, color: .white, line: 1.9)
                        }
                    }.buttonStyle(.plain).padding(.top, 8)
                }
            }
        }
    }
}
