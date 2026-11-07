import SwiftUI
import StrataCore

/// Strength overview (workout.js `overviewView`).
struct OverviewView: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.safeTop) private var safeTop
    @State private var confirmDiscard = false

    var body: some View {
        if let e = model.engine, let A = e.db.active { main(e, A) } else { Color.clear }
    }

    @ViewBuilder private func main(_ e: Engine, _ A: ActiveWorkout) -> some View {        let L = e.liftList(), req = e.requiredItems(A.day)
        let done = req.filter { e.exState($0) == "done" }.count
        let nx = e.nextUp(), legs = e.isLegs(A.day), jumps = e.cardioOn(A.date, "jumps") != nil
        let name = e.plan[A.day]?.name ?? ""
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Color.clear.frame(width: 44, height: 44)
                    Spacer()
                    VStack(spacing: 0) {
                        Text(name).nameStyle()
                        if let s = A.started { ElapsedText(since: s, suffix: " elapsed").smallStyle() }
                    }
                    Spacer()
                    GlassButton(action: { model.menuOpen = true }, accessibility: "Workout options") {
                        Text("···").font(.inter(size: 14, weight: .heavy)).tracking(2)
                    }
                }
                Text("Strength\(legs ? " + Bone" : "")\((A.lowEnergy ?? false) ? " · lighter day" : "")")
                    .font(.inter(size: 17, weight: .bold)).foregroundStyle(Theme.violet).padding(.top, 6)
                Text(name).font(.inter(size: 34, weight: .heavy)).tracking(-0.85).padding(.top, -8)
                ProgressBar(fraction: req.isEmpty ? 0 : Double(done) / Double(req.count))
                Text("\(done) of \(req.count) main lifts done").metaStyle().padding(.top, -6)
                RestBanner()
                if legs { jumpsRow(jumps) }
                ForEach(e.woBlocks(), id: \.t) { b in
                    let d = b.items.filter { id in L.first { $0.id == id }.map { e.exState($0) == "done" } ?? false }.count
                    HStack {
                        Text("\(b.kind)\(b.opt ? " · if time" : "")").font(.inter(size: 20, weight: .heavy)).tracking(-0.2)
                        Spacer(); Text("\(d) of \(b.items.count)").metaStyle().fontWeight(.semibold)
                    }.padding(.top, 8)
                    ForEach(b.items, id: \.self) { id in
                        if let ex = L.first(where: { $0.id == id }), let i = L.firstIndex(where: { $0.id == id }) {
                            row(e, ex: ex, index: i, isNext: nx?.id == ex.id)
                        }
                    }
                }
            }
            .padding(.horizontal, Theme.gutter).padding(.top, 14 + safeTop).padding(.bottom, 110)
            .frame(maxWidth: Theme.maxWidth)
        }
        .safeAreaInset(edge: .bottom) {
            WorkoutDock(discard: { confirmDiscard = true }) {
                Button("Complete") { model.requestEndSession() }.buttonStyle(StrataButtonStyle(kind: .violet))
            }
        }
        .alert(discardMessage, isPresented: $confirmDiscard) {
            Button("Discard", role: .destructive) { model.mutate { $0.discardWorkout(); return nil } }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func jumpsRow(_ done: Bool) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Warm-up · Bone").font(.inter(size: 20, weight: .heavy)).tracking(-0.2).padding(.top, 8)
            Button {
                model.jumpSets = [:]; model.jumpWeights = [:]; model.jumpStep = 0
                model.mutate { $0.db.active?.jumpsSeen = 0; return nil }
            } label: {
                HStack(spacing: 12) {
                    Thumb(path: "img/pogo.jpg")
                    VStack(alignment: .leading, spacing: 2) { Text("Jumps warm-up").nameStyle(); Text("Pogo hops 3 × 10 · Box jumps 3 × 5").metaStyle() }
                    Spacer(minLength: 0)
                    if done { CheckDot(color: Theme.mint) } else { IconView(d: Icon.chev, size: 16, color: Theme.muted, line: 2.4) }
                }
                .padding(.leading, 10).padding(.trailing, 14).padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 20).fill(Theme.glass))
                .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Theme.line))
                .opacity(done ? 0.7 : 1)
            }.buttonStyle(.plain)
        }
    }

    private func row(_ engine: Engine, ex: Ex, index: Int, isNext: Bool) -> some View {
        var e = engine
        let A = e.db.active!, s = e.shownEx(ex), st = e.exState(ex), p = e.progOf(ex), n = e.setsOf(ex)
        let w = p?.w ?? ((A.lowEnergy ?? false) ? e.loEnergyW(e.wOf(s)) : e.wOf(s))
        let busyTs = A.busy?[ex.id] ?? 0
        let busy = busyTs != 0 && AppModel.nowMs() - busyTs < Config.workout.busyMin * 60_000 && st != "done"
        let meta = "\(n) × \(Fmt.repLbl(s, ex.r.map(Double.init)))\(Fmt.perLeg(s)) · \(Fmt.wLbl(s, w))\(s.id != ex.id ? " · swapped" : "")"
        return Button { model.mutate { $0.openEx(index) } } label: {
            HStack(spacing: 12) {
                Thumb(path: e.catalog.imageName(of: s.id))
                VStack(alignment: .leading, spacing: 2) { Text(Fmt.cleanN(s.n)).nameStyle(); Text(meta).metaStyle() }
                Spacer(minLength: 0)
                if st == "done" { CheckDot() }
                else if st == "live" { Chip(text: "\(p?.reps.count ?? 0)/\(n)") }
                else if busy { Chip(text: "Busy", fg: Theme.amber, bg: Theme.amber.opacity(0.14)) }
                else if isNext { Chip(text: "Next", fg: Theme.violet, bg: Theme.violet.opacity(0.18)) }
                else { IconView(d: Icon.chev, size: 16, color: Theme.muted, line: 2.4) }
            }
            .padding(.leading, 10).padding(.trailing, 14).padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 20).fill(isNext && st != "done" ? Theme.violet.opacity(0.08) : Theme.glass))
            .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(isNext && st != "done" ? Theme.violet.opacity(0.6) : Theme.line))
            .opacity(st == "done" ? 0.7 : 1)
        }.buttonStyle(.plain)
    }
}

struct ProgressBar: View {
    let fraction: Double
    var body: some View {
        GeometryReader { g in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.1))
                Capsule().fill(Theme.violet).frame(width: g.size.width * fraction)
            }
        }.frame(height: 8)
    }
}

extension AppModel {
    /// "Complete": ask what the web asks with `confirm()`, then finish.
    func requestEndSession() {
        guard let e = engine else { return }
        if let p = e.endSessionPrompt() { pendingEnd = p } else { finishSession() }
    }
    func finishSession() {
        pendingEnd = nil
        mutate { $0.endSession(); return nil }
    }
}
