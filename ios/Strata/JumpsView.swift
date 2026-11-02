import SwiftUI
import StrataCore

/// Jumps warm-up (app.js `jumpsView`).
struct JumpsView: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.safeTop) private var safeTop

    struct Item { var k: String, name: String, img: String?, sets: Int, reps: String, how: String, yt: String }

    var body: some View {
        let e = model.engine!, A = e.db.active!
        let warm = (e.plan[A.day]?.blocks ?? []).filter { $0.t.range(of: "^warm-up", options: [.regularExpression, .caseInsensitive]) != nil }.flatMap(\.items)
        let items: [Item] = [
            Item(k: "pogo", name: "Pogo hops", img: "img/pogo.jpg", sets: 3, reps: "10", how: "Bounce on the balls of your feet, knees almost straight, quick and light. 30 s rest between sets.", yt: "rc_pogo"),
            Item(k: "box", name: "Box jumps", img: "img/box_jump.jpg", sets: 3, reps: "5", how: "Low box, 30–40 cm. Jump up, land soft, stand tall, then step down. 60 s rest.", yt: "rc_box"),
        ] + warm.map { ex in
            Item(k: ex.id, name: Fmt.cleanN(ex.n), img: e.catalog.imageName(of: ex.id), sets: 2, reps: "\(ex.r ?? 0)\(Fmt.perLeg(ex))", how: e.catalog.cue(of: ex.id), yt: ex.id)
        }
        let allDone = items.allSatisfy { (model.jumpSets[$0.k] ?? 0) >= $0.sets }
        ScrollView {
            VStack(spacing: 0) {
                ZStack(alignment: .topLeading) {
                    Hero(eyebrow: "Bone · \(e.plan[A.day]?.name ?? "")", title: "Jumps warm-up",
                         sub: "Impact for bone density. Short, sharp, done before you lift.", short: true)
                    GlassButton(action: { model.mutate { $0.skipJumps(); return nil } }, accessibility: "Back") {
                        IconView(d: "M15 5l-7 7 7 7", size: 18, color: .white, line: 2.4)
                    }.padding(.leading, 16).padding(.top, 14 + safeTop)
                }
                VStack(spacing: 12) {
                    ForEach(items, id: \.k) { it in card(it) }
                }.padding(.horizontal, Theme.gutter).padding(.top, 14).padding(.bottom, 110)
            }.frame(maxWidth: Theme.maxWidth)
        }
        .safeAreaInset(edge: .bottom) {
            DockRow {
                Button("Skip") { model.mutate { $0.skipJumps(); return nil } }.buttonStyle(StrataButtonStyle())
            } right: {
                Button(allDone ? "Done · start lifting" : "Mark done · start lifting") {
                    let sets = model.jumpSets
                    model.mutate { $0.completeJumps(sets: sets) }
                }.buttonStyle(StrataButtonStyle(kind: allDone ? .mint : .plain))
            }
        }
    }

    private func card(_ it: Item) -> some View {
        let done = model.jumpSets[it.k] ?? 0
        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                Thumb(path: it.img)
                VStack(alignment: .leading, spacing: 2) { Text(it.name).nameStyle(); Text("\(it.sets) × \(it.reps)").metaStyle() }
                Spacer(minLength: 0)
                VideoButton(id: it.yt, name: it.yt.hasPrefix("rc_") ? "" : it.name)
            }
            Text(it.how).bodyStyle().padding(.top, 8)
            HStack(spacing: 8) {
                ForEach(0..<it.sets, id: \.self) { i in
                    Button {
                        let cur = model.jumpSets[it.k] ?? 0
                        model.jumpSets[it.k] = cur == i + 1 ? i : i + 1
                    } label: {
                        if i < done { IconView(d: Icon.check, size: 16, color: Color(hex: "#08210F"), line: 3) } else { Text("Set \(i + 1)") }
                    }
                    .buttonStyle(StrataButtonStyle(kind: i < done ? .mint : .plain, small: true))
                    .accessibilityAddTraits(i < done ? .isSelected : [])
                }
            }.padding(.top, 12)
        }.card()
    }
}
