import SwiftUI
import StrataCore

/// The back button used on heroes and workout tops (`backBtn` / `.gbtn`).
struct GlassButton<Label: View>: View {
    let action: () -> Void
    var accessibility: String
    @ViewBuilder var label: () -> Label
    var body: some View {
        Button(action: action) {
            label().frame(minWidth: 44, minHeight: 44).padding(.horizontal, 14)
                .background(Capsule().fill(Color(hex: "#141620").opacity(0.45)))
                .overlay(Capsule().strokeBorder(Color.white.opacity(0.18)))
        }.buttonStyle(.plain).accessibilityLabel(accessibility)
    }
}

/// `.chip`
struct Chip: View {
    let text: String
    var fg: Color = .white
    var bg: Color = Theme.glass2
    var leading: AnyView?
    var body: some View {
        HStack(spacing: 5) { if let l = leading { l }; Text(text) }
            .font(.system(size: 13, weight: .bold)).foregroundStyle(fg)
            .padding(.horizontal, 11).padding(.vertical, 7)
            .background(Capsule().fill(bg))
    }
}

/// `.pill`
struct Pill: View {
    let text: String
    var fg: Color = Color(hex: "#E6E8EE")
    var bg: Color = Theme.glass2
    var body: some View {
        Text(text).font(.system(size: 12, weight: .semibold)).foregroundStyle(fg)
            .padding(.horizontal, 11).padding(.vertical, 7).background(Capsule().fill(bg))
    }
}

/// A play button that opens the form video (`.gbtn` with the play glyph).
struct VideoButton: View {
    @EnvironmentObject var model: AppModel
    let id: String, name: String
    var body: some View {
        Button { model.openFormVideo(id: id, name: name) } label: {
            SVGPathShape(d: "M8 5v14l11-7z").fill(Color.white).frame(width: 14, height: 14)
                .frame(width: 40, height: 40)
                .background(Circle().fill(Color(hex: "#141620").opacity(0.45)))
                .overlay(Circle().strokeBorder(Color.white.opacity(0.18)))
        }.buttonStyle(.plain).accessibilityLabel("Watch \(name.isEmpty ? "form" : name) form")
    }
}

/// Workout preview (app.js `previewView`).
struct PreviewView: View {
    @EnvironmentObject var model: AppModel
    let day: Int
    @State private var gateMessage: String?

    var body: some View {
        let e = model.engine!
        let d = day, legs = e.isLegs(d), low = e.preLow
        let blocks = e.plan[d]?.blocks ?? []
        let warm = blocks.filter { $0.t.range(of: "^warm-up", options: [.regularExpression, .caseInsensitive]) != nil }.flatMap(\.items)
        let req = e.requiredItems(d)
        let bonus = blocks.filter { $0.t.range(of: "^bonus", options: [.regularExpression, .caseInsensitive]) != nil }.flatMap(\.items)
        let g = e.gate(view: d)
        let minutes = low ? jsRoundFive(e.minutesFor(d) * 0.75) : e.minutesFor(d)
        let landings = legs ? (3 * 10 + 3 * 5) : 0
        ScrollView {
            VStack(spacing: 0) {
                ZStack(alignment: .topLeading) {
                    Hero(eyebrow: Dates.fmtD(e.today, .init(weekday: .short, month: .short, day: true)), title: e.plan[d]?.name ?? "",
                         sub: legs ? "Glutes, legs and bone" : "Chest, back, shoulders, arms", short: true, brand: false)
                    GlassButton(action: { model.go(.today) }, accessibility: "Back") {
                        IconView(d: "M15 5l-7 7 7 7", size: 18, color: .white, line: 2.4)
                    }.padding(.leading, 16).padding(.top, 14 + safeTopValue)
                }
                VStack(spacing: 12) {
                    HStack(spacing: 6) {
                        Pill(text: "~\(jsMinutes(minutes)) min"); Pill(text: "\(req.count) main lifts")
                        if legs { Pill(text: "\(landings) landings", fg: Theme.mint, bg: Theme.mint.opacity(0.14)) }
                        Spacer(minLength: 0)
                    }.frame(maxWidth: .infinity, alignment: .leading)
                    if !g.ok && e.db.active == nil { WarnBox(markdown: g.msg) }
                    if legs || !warm.isEmpty { warmCard(e, warm: warm, legs: legs) }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Main lifts").labelStyle()
                        VStack(spacing: 0) {
                            ForEach(Array(req.enumerated()), id: \.element.id) { i, ex in
                                mainRow(e, ex: ex, index: i, low: low)
                                    .overlay(alignment: .top) { if i > 0 { Rectangle().fill(Theme.line).frame(height: 1) } }
                            }
                        }
                    }.card()
                    if !bonus.isEmpty && !low {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack { Text("Bonus · if time").labelStyle(); Spacer(); Text("+\(bonus.count * 6) min").smallStyle() }
                            Text(bonus.map { Fmt.cleanN($0.n) }.joined(separator: " · ")).metaStyle()
                        }.card(dashed: true)
                    }
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Feeling flat?").nameStyle()
                            Text("Lighter version: 85% weight, 2 sets, no bonus. Weights don't go up.").metaStyle()
                        }
                        Spacer(minLength: 0)
                        WebSwitch(isOn: Binding(get: { model.engine?.preLow ?? false }, set: { _ in model.mutate { $0.togglePreviewLighter(); return nil } }), label: "Lighter version")
                    }.card(tight: true)
                }.padding(.horizontal, Theme.gutter).padding(.top, 14).padding(.bottom, 110)
            }.frame(maxWidth: Theme.maxWidth)
        }
        .safeAreaInset(edge: .bottom) {
            Button(legs ? "Start with jumps" : "Start workout") { start() }
                .buttonStyle(StrataButtonStyle(kind: .violet))
                .padding(.horizontal, 16).padding(.top, 14).padding(.bottom, 8)
                .background(LinearGradient(colors: [Theme.bg.opacity(0), Theme.bg.opacity(0.94)], startPoint: .top, endPoint: .init(x: 0.5, y: 0.35)))
        }
        .alert("Start anyway?", isPresented: Binding(get: { gateMessage != nil }, set: { if !$0 { gateMessage = nil } })) {
            Button("Start") { gateMessage = nil; begin() }
            Button("Cancel", role: .cancel) { gateMessage = nil }
        } message: { Text(gateMessage ?? "") }
    }

    @Environment(\.safeTop) private var safeTopValue

    private func jsRoundFive(_ v: Double) -> Double { jsRound(v / 5) * 5 }

    private func start() {
        switch model.engine!.beginCheck(day: day) {
        case .alreadyOpen(let t): model.show(t)
        case .confirm(let m): gateMessage = m
        case .ok: begin()
        }
    }
    private func begin() {
        model.jumpSets = [:]
        model.mutate { $0.begin(day: day); return nil }
    }

    private func warmCard(_ e: Engine, warm: [Ex], legs: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack { Text("Warm-up · Bone · 5 min").labelStyle(Theme.mint); Spacer(); Text("Do first").smallStyle() }
            if legs {
                warmRow(img: "img/pogo.jpg", name: "Pogo hops", meta: "3 × 10", yt: "rc_pogo", first: true)
                warmRow(img: "img/box_jump.jpg", name: "Box jumps", meta: "3 × 5 · step down", yt: "rc_box", first: false)
            }
            ForEach(Array(warm.enumerated()), id: \.element.id) { i, ex in
                warmRow(img: e.catalog.imageName(of: ex.id), name: Fmt.cleanN(ex.n), meta: "2 × \(ex.r ?? 0)\(Fmt.perLeg(ex)) · balance", yt: ex.id, first: !legs && i == 0)
            }
        }.card(border: Theme.mint.opacity(0.35))
    }

    private func warmRow(img: String?, name: String, meta: String, yt: String, first: Bool) -> some View {
        HStack(spacing: 12) {
            Thumb(path: img, size: 44, radius: 12)
            VStack(alignment: .leading, spacing: 2) { Text(name).nameStyle(); Text(meta).metaStyle() }
            Spacer(minLength: 0)
            VideoButton(id: yt, name: yt.hasPrefix("rc_") ? "" : name)
        }.padding(.vertical, 10).overlay(alignment: .top) { if !first { Rectangle().fill(Theme.line).frame(height: 1) } }
    }

    private func mainRow(_ engine: Engine, ex: Ex, index i: Int, low: Bool) -> some View {
        var e = engine
        let w = low ? e.loEnergyW(e.wOf(ex)) : e.wOf(ex)
        let sets = low ? Config.lighterDaySets : ex.setCount
        let last = e.lastOf(ex.id)
        let plate = (ex.bar != nil && w != 0) ? Fmt.plateTxt(ex, w) : ""
        var extra: [String] = []
        if let l = last { extra.append("Last: \(jsMinutes(l.w)) × " + l.reps.map { $0.map(jsMinutes) ?? "–" }.joined(separator: "/")) }
        if !plate.isEmpty { extra.append(plate) }
        let head = "\(sets) × \(Fmt.repLbl(ex, ex.r.map(Double.init)))\(Fmt.perLeg(ex)) · "
        let meta = Text(head).foregroundColor(Theme.muted) + Text(Fmt.wLbl(ex, w)).bold().foregroundColor(.white)
            + Text(i == 0 ? " · heavy" : "").foregroundColor(Theme.muted)
            + Text(ex.isInjured ? " · on hold" : "").foregroundColor(Theme.amber)
        return HStack(spacing: 12) {
            Thumb(path: e.catalog.imageName(of: ex.id))
            VStack(alignment: .leading, spacing: 2) {
                Text(Fmt.cleanN(ex.n)).nameStyle()
                meta.font(.system(size: 13))
                if !extra.isEmpty { Text(extra.joined(separator: " · ")).font(.system(size: 12)).foregroundStyle(Theme.muted) }
            }
            Spacer(minLength: 0)
            VideoButton(id: ex.id, name: Fmt.cleanN(ex.n))
        }.padding(.vertical, 10)
    }
}
