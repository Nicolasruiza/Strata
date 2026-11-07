import SwiftUI
import StrataCore

/// Jumps warm-up (app.js `jumpsView`), one exercise per screen like the lifts: log set 1, rest, log set 2...
/// The single-leg RDL takes an optional load (a kettlebell), remembered from last time.
struct JumpsView: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.safeTop) private var safeTop

    struct Item {
        var k: String, name: String, img: String?, sets: Int, reps: Int, perLeg: Bool, how: String, yt: String
        var rest: Double
        var weighted: Bool
    }

    var body: some View {
        if let e = model.engine, let A = e.db.active { main(e, A) } else { Color.clear }
    }

    static func items(_ e: Engine, _ A: ActiveWorkout) -> [Item] {
        let ids = e.warmIds(A.day)
        let warm = (e.plan[A.day]?.blocks ?? []).flatMap(\.items).filter { ids.contains($0.id) }
        return [
            Item(k: "pogo", name: "Pogo hops", img: "img/pogo.jpg", sets: 3, reps: 10, perLeg: false,
                 how: "Bounce on the balls of your feet, knees almost straight, quick and light. 30 s rest between sets.",
                 yt: "rc_pogo", rest: Config.Jumps.restSec["pogo"] ?? Config.Jumps.defaultRestSec, weighted: false),
            Item(k: "box", name: "Box jumps", img: "img/box_jump.jpg", sets: 3, reps: 5, perLeg: false,
                 how: "Low box, 30–40 cm. Jump up, land soft, stand tall, then step down. 60 s rest.",
                 yt: "rc_box", rest: Config.Jumps.restSec["box"] ?? Config.Jumps.defaultRestSec, weighted: false),
        ] + warm.map { ex in
            Item(k: ex.id, name: Fmt.cleanN(ex.n).replacingOccurrences(of: ", bodyweight", with: ""),
                 img: e.catalog.imageName(of: ex.id), sets: 2, reps: ex.r ?? 0, perLeg: !Fmt.perLeg(ex).isEmpty,
                 how: e.catalog.cue(of: ex.id), yt: ex.id, rest: Config.Jumps.defaultRestSec, weighted: true)
        }
    }

    private func weight(_ e: Engine, _ it: Item) -> Double { model.jumpWeights[it.k] ?? e.db.active?.entries[it.k]?.w ?? e.lastOf(it.k)?.w ?? 0 }

    @ViewBuilder private func main(_ e: Engine, _ A: ActiveWorkout) -> some View {
        let list = Self.items(e, A)
        let sets = A.jumps ?? [:]
        let step = min(model.jumpStep, list.count - 1)
        let it = list[step]
        let done = sets[it.k] ?? 0
        let last = step == list.count - 1
        let allDone = list.allSatisfy { (sets[$0.k] ?? 0) >= $0.sets }
        ScrollView {
            VStack(spacing: 0) {
                ZStack(alignment: .top) {
                    Color(hex: "#1b1e28")
                    if let img = it.img {
                        Color.clear.frame(height: 330 + safeTop)
                            .overlay(BundleImage(name: ((img as NSString).lastPathComponent as NSString).deletingPathExtension)).clipped()
                    }
                    LinearGradient(stops: [.init(color: Theme.bg.opacity(0.35), location: 0), .init(color: Theme.bg.opacity(0), location: 0.35), .init(color: Theme.bg, location: 1)], startPoint: .top, endPoint: .bottom)
                    HStack {
                        GlassButton(action: back, accessibility: step == 0 ? "Skip the warm-up" : "Previous exercise") {
                            IconView(d: "M15 5l-7 7 7 7", size: 18, color: .white, line: 2.4)
                        }
                        Spacer()
                        HStack(spacing: 8) { LogoMark(); Text("Strata").font(.inter(size: 20, weight: .bold)) }
                        Spacer()
                        Color.clear.frame(width: 44, height: 44)
                    }.padding(.horizontal, 16).padding(.top, 14 + safeTop)
                }.frame(height: 330 + safeTop).clipped()

                VStack(alignment: .leading, spacing: 14) {
                    Text("Warm-up · Bone \(step + 1) of \(list.count)")
                        .font(.inter(size: 14, weight: .bold)).foregroundStyle(Theme.mint)
                        .padding(.horizontal, 12).padding(.vertical, 5)
                        .background(Capsule().fill(Theme.mint.opacity(0.14)))
                        .overlay(Capsule().strokeBorder(Theme.mint.opacity(0.5)))
                    Text(it.name).font(.inter(size: 30, weight: .heavy)).tracking(-0.75).padding(.top, -6)
                    Text("\(it.sets) sets × \(it.reps)\(it.perLeg ? " / leg" : "")").metaStyle().padding(.top, -10)
                    Text(it.how).bodyStyle()
                    if it.weighted { weightCard(e, it) }
                    RestBanner()
                    ForEach(0..<it.sets, id: \.self) { i in setRow(e, it, i, done: done, next: nextLabel(list, step)) }
                    Button { model.openFormVideo(id: it.yt, name: it.yt.hasPrefix("rc_") ? "" : it.name) } label: {
                        HStack(spacing: 6) { SVGPathShape(d: "M8 5v14l11-7z").fill(Color.white).frame(width: 14, height: 14); Text("Form video") }
                    }.buttonStyle(StrataButtonStyle(small: true))
                }
                .padding(.horizontal, Theme.gutter).padding(.top, -56).padding(.bottom, 110)
            }.frame(maxWidth: Theme.maxWidth)
        }
        .ignoresSafeArea(edges: .top)
        .safeAreaInset(edge: .bottom) {
            DockRow {
                Button("Skip") { model.mutate { $0.rest = nil; $0.skipJumps(); return nil } }.buttonStyle(StrataButtonStyle())
            } right: {
                if last {
                    Button(allDone ? "Done · start lifting" : "Start lifting") { finish(e, A, list) }
                        .buttonStyle(StrataButtonStyle(kind: allDone ? .mint : .plain))
                } else {
                    Button("Next exercise") { model.mutate { $0.rest = nil; return nil }; model.jumpStep = step + 1 }
                        .buttonStyle(StrataButtonStyle(kind: done >= it.sets ? .mint : .plain))
                }
            }
        }
    }

    private func back() {
        if model.jumpStep > 0 { model.jumpStep -= 1 }
        else { model.mutate { $0.rest = nil; $0.skipJumps(); return nil } }
    }

    private func finish(_ e: Engine, _ A: ActiveWorkout, _ list: [Item]) {
        let sets = A.jumps ?? [:]
        var weights: [String: Double] = [:]
        for it in list where it.weighted && (sets[it.k] ?? 0) > 0 { weights[it.k] = weight(e, it) }
        model.mutate { $0.rest = nil; return $0.completeJumps(sets: sets, weights: weights) }
        model.jumpStep = 0
    }

    private func nextLabel(_ list: [Item], _ step: Int) -> String? { step + 1 < list.count ? "Next: \(list[step + 1].name)" : nil }

    private func weightCard(_ e: Engine, _ it: Item) -> some View {
        let w = weight(e, it)
        return HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Weight · optional").metaStyle()
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    WeightField(value: w) { input in
                        let v = Double(input.replacingOccurrences(of: ",", with: ".")).map { max(0, min(Engine.maximumTypedWeight, ($0 * 100).rounded() / 100)) } ?? w
                        model.jumpWeights[it.k] = v
                        return v
                    }
                    Text("lb").font(.inter(size: 20, weight: .semibold)).foregroundStyle(Theme.muted)
                }
                Text(w == 0 ? "Bodyweight. Add a kettlebell if you use one." : "In your hand, remembered for next time").metaStyle()
            }
            Spacer(minLength: 0)
            stepButton("M5 12h14", "Less weight") { model.jumpWeights[it.k] = max(0, w - Config.Jumps.weightStep) }
            stepButton("M12 5v14M5 12h14", "More weight") { model.jumpWeights[it.k] = min(Engine.maximumTypedWeight, w + Config.Jumps.weightStep) }
        }.padding(.horizontal, 16).padding(.vertical, 14)
         .background(RoundedRectangle(cornerRadius: 22).fill(Theme.glass))
         .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(Theme.line))
    }

    private func stepButton(_ d: String, _ label: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            IconView(d: d, size: 24, color: .white, line: 1.9).frame(width: 56, height: 60)
                .background(RoundedRectangle(cornerRadius: 18).fill(Theme.mint.opacity(0.14)))
                .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Theme.mint.opacity(0.5)))
        }.buttonStyle(.plain).accessibilityLabel(label)
    }

    private func setLine(_ e: Engine, _ it: Item) -> String {
        let w = it.weighted ? weight(e, it) : 0
        return (w > 0 ? "\(jsMinutes(w)) lb × " : "") + "\(it.reps) reps\(it.perLeg ? " / leg" : "")"
    }

    @ViewBuilder
    private func setRow(_ e: Engine, _ it: Item, _ i: Int, done: Int, next: String?) -> some View {
        if i < done {
            HStack(spacing: 12) {
                Button { undo(it, i) } label: { CheckDot() }
                    .buttonStyle(.plain).allowsHitTesting(i == done - 1).accessibilityLabel("Undo set \(i + 1)")
                VStack(alignment: .leading, spacing: 2) { Text("Set \(i + 1)").nameStyle(); Text(setLine(e, it)).metaStyle() }
                Spacer(minLength: 0)
                Chip(text: "Done")
            }.padding(.horizontal, 14).padding(.vertical, 12)
             .background(RoundedRectangle(cornerRadius: 18).fill(Theme.glass))
             .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Theme.line))
        } else if i == done {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) { Text("Set \(i + 1)").nameStyle(); Text(setLine(e, it)).metaStyle() }
                Spacer(minLength: 0)
                Button("Log") { log(it, i, next: next) }
                    .font(.inter(size: 16, weight: .heavy)).foregroundStyle(Color(hex: "#08210F"))
                    .padding(.horizontal, 20).frame(height: 44).background(RoundedRectangle(cornerRadius: 14).fill(Theme.mint))
            }.padding(.horizontal, 14).padding(.vertical, 12)
             .background(RoundedRectangle(cornerRadius: 18).fill(Theme.mint.opacity(0.08)))
             .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Theme.mint, lineWidth: 1.5))
        } else {
            HStack(spacing: 12) {
                Circle().strokeBorder(Color.white.opacity(0.3), lineWidth: 2).frame(width: 30, height: 30)
                VStack(alignment: .leading, spacing: 2) { Text("Set \(i + 1)").nameStyle(); Text(setLine(e, it)).metaStyle() }
                Spacer(minLength: 0)
            }.padding(.horizontal, 14).padding(.vertical, 12)
             .background(RoundedRectangle(cornerRadius: 18).fill(Theme.glass))
             .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Theme.line))
             .opacity(0.75)
        }
    }

    /// Logging a set starts the rest, like a lift. Nothing to rest for after the very last set of the warm-up.
    private func log(_ it: Item, _ i: Int, next: String?) {
        model.mutate { $0.setJumpSets(it.k, i + 1); return nil }
        let lastOfWarmup = i + 1 >= it.sets && next == nil
        if lastOfWarmup { model.mutate { $0.rest = nil; return nil }; return }
        let upNext = i + 1 < it.sets ? "Set \(i + 2) of \(it.sets)" : next
        model.mutate { $0.startRest(it.rest, next: upNext, lbl: i + 1 < it.sets ? nil : "Logged"); return nil }
    }

    private func undo(_ it: Item, _ i: Int) {
        model.mutate { $0.setJumpSets(it.k, i); $0.rest = nil; return nil }
    }
}
