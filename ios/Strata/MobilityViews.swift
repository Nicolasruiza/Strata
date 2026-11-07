import SwiftUI
import StrataCore

private let mobTint = Theme.mint

/// Compact card on Move: Morning and Evening, each 0/3 to 3/3. Optional: no "missed" state anywhere.
struct MobilityCard: View {
    @EnvironmentObject var model: AppModel
    let e: Engine

    var body: some View {
        let total = Config.Mobility.exercises.count
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                ZStack { Circle().fill(mobTint.opacity(0.18)); IconView(d: Icon.walk, size: 20, color: mobTint, line: 2.2) }.frame(width: 40, height: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Daily mobility").nameStyle()
                    Text("Back and legs · optional, a bonus").metaStyle()
                }
                Spacer(minLength: 0)
            }
            ForEach(Config.Mobility.sessions) { s in
                let n = e.mobilityCount(date: e.today, session: s.id)
                Button { model.go(.mobility(session: s.id)) } label: {
                    HStack(spacing: 10) {
                        Text(s.label).font(.inter(size: 15, weight: .semibold))
                        Spacer(minLength: 0)
                        HStack(spacing: 4) {
                            ForEach(0..<total, id: \.self) { i in
                                Circle().fill(i < n ? mobTint : Color.white.opacity(0.14)).frame(width: 9, height: 9)
                            }
                        }
                        Text("\(n)/\(total)").font(.inter(size: 15, weight: .semibold)).monospacedDigit()
                            .foregroundStyle(n == total ? mobTint : Theme.text).frame(minWidth: 30, alignment: .trailing)
                        IconView(d: Icon.chev, size: 18, color: Color(hex: "#A9AEBD"), line: 2.4)
                    }
                    .padding(.vertical, 12)
                    .overlay(alignment: .top) { Rectangle().fill(Theme.line).frame(height: 1) }
                    .contentShape(Rectangle())
                }.buttonStyle(.plain).padding(.top, s.id == "morning" ? 10 : 0)
                .accessibilityLabel("\(s.label), \(n) of \(total) done")
            }
        }.card()
    }
}

/// Full screen for one session: tick off what you did, like the lifting screen.
struct MobilityView: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.safeTop) private var safeTop
    let session: String
    @State private var guide: Config.Mobility.Exercise?

    var body: some View {
        if let e = model.engine { main(e) } else { Color.clear }
    }

    private func main(_ e: Engine) -> some View {
        let label = Config.Mobility.sessions.first { $0.id == session }?.label ?? ""
        let checked = e.mobilityChecked(date: e.today, session: session)
        let total = Config.Mobility.exercises.count
        return ScrollView {
            VStack(spacing: 0) {
                ZStack(alignment: .topLeading) {
                    Hero(eyebrow: "Mobility · \(checked.count) of \(total)", title: "\(label) routine",
                         sub: "Tick each set as you finish it.", short: true, brand: false)
                    GlassButton(action: { model.go(.today) }, accessibility: "Back") {
                        IconView(d: "M15 5l-7 7 7 7", size: 18, color: .white, line: 2.4)
                    }.padding(.leading, 16).padding(.top, 14 + safeTop)
                }
                VStack(spacing: 12) {
                    ForEach(Config.Mobility.exercises) { ex in
                        card(ex, done: checked.contains(ex.id), sets: e.mobilitySets(date: e.today, session: session, ex: ex.id))
                    }
                    Text(Config.Mobility.safetyNote).font(.inter(size: 12)).foregroundStyle(Theme.muted)
                        .multilineTextAlignment(.center).padding(.horizontal, 12).padding(.top, 4)
                }.padding(.horizontal, Theme.gutter).padding(.top, 14).padding(.bottom, 110)
            }.frame(maxWidth: Theme.maxWidth)
        }
        .safeAreaInset(edge: .bottom) {
            DockRow {
                Button("Back") { model.go(.today) }.buttonStyle(StrataButtonStyle())
            } right: {
                Button(checked.count == total ? "All done" : "\(checked.count) of \(total) done") { model.go(.today) }
                    .buttonStyle(StrataButtonStyle(kind: checked.count == total ? .mint : .plain))
            }
        }
        .sheet(item: $guide) { ex in MobilityGuide(ex: ex) }
    }

    private func card(_ ex: Config.Mobility.Exercise, done: Bool, sets: Int) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                Thumb(path: "img/\(ex.finishImage).jpg")
                VStack(alignment: .leading, spacing: 2) { Text(ex.name).nameStyle(); Text(ex.prescription).metaStyle() }
                Spacer(minLength: 0)
            }
            Text(ex.cue).bodyStyle().padding(.top, 8)
            HStack(spacing: 8) {
                ForEach(0..<ex.sets, id: \.self) { i in
                    Button {
                        model.mutate { $0.tapMobilitySet(session: session, ex: ex.id, index: i); return nil }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        if i < sets { IconView(d: Icon.check, size: 16, color: Color(hex: "#08210F"), line: 3) } else { Text("Set \(i + 1)") }
                    }
                    .buttonStyle(StrataButtonStyle(kind: i < sets ? .mint : .plain, small: true))
                    .accessibilityAddTraits(i < sets ? .isSelected : [])
                }
            }.padding(.top, 12)
            HStack(spacing: 8) {
                Button("View guide") { guide = ex }.buttonStyle(StrataButtonStyle(small: true))
                Button {
                    model.mutate { $0.toggleMobility(session: session, ex: ex.id); return nil }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    if done { HStack(spacing: 6) { IconView(d: Icon.check, size: 16, color: Color(hex: "#08210F"), line: 3); Text("Done") } }
                    else { Text("All sets done") }
                }
                .buttonStyle(StrataButtonStyle(kind: done ? .mint : .plain, small: true))
                .accessibilityAddTraits(done ? .isSelected : [])
                .accessibilityHint(done ? "Tap to undo" : "")
            }.padding(.top, 8)
        }.card()
    }
}

/// Start and Finish photos, purpose, prescription, cue and, when the handout asks for a hold, the timer.
struct MobilityGuide: View {
    @Environment(\.dismiss) private var dismiss
    let ex: Config.Mobility.Exercise

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(ex.category).labelStyle(mobTint)
                        Text(ex.name).title2Style().fixedSize(horizontal: false, vertical: true)
                    }.frame(maxWidth: .infinity, alignment: .leading)
                    GlassButton(action: { dismiss() }, accessibility: "Close") {
                        IconView(d: "M6 6l12 12M18 6L6 18", size: 16, color: .white, line: 2.4)
                    }
                }
                photo("Start", ex.startImage)
                photo("Finish", ex.finishImage)
                VStack(alignment: .leading, spacing: 6) {
                    Text("What it does").labelStyle(Theme.muted)
                    Text(ex.purpose).bodyStyle()
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Prescription").labelStyle(Theme.muted)
                    Text(ex.prescription + ", twice daily").bodyStyle()
                    if let q = ex.equipment { Text("You need: \(q)").metaStyle() }
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("How to do it").labelStyle(Theme.muted)
                    ForEach(ex.steps.indices, id: \.self) { i in
                        HStack(alignment: .top, spacing: 10) {
                            Text("\(i + 1)").font(.inter(size: 12, weight: .bold)).frame(width: 22, height: 22)
                                .background(Circle().fill(Color.white.opacity(0.12)))
                            Text(ex.steps[i]).bodyStyle()
                        }
                    }
                }
                HStack(alignment: .top, spacing: 10) {
                    IconView(d: Icon.check, size: 16, color: mobTint, line: 2.6).padding(.top, 2)
                    Text(ex.cue).font(.inter(size: 14, weight: .semibold))
                }.card(border: mobTint.opacity(0.4))
                if let s = ex.holdSeconds { HoldTimer(seconds: s) }
                Text(Config.Mobility.safetyNote).font(.inter(size: 12)).foregroundStyle(Theme.muted)
            }
            .padding(.horizontal, Theme.gutter).padding(.vertical, 20)
            .frame(maxWidth: Theme.maxWidth)
        }
        .background(Theme.bg.ignoresSafeArea())
        .foregroundStyle(Theme.text)
        .preferredColorScheme(.dark)
    }

    private func photo(_ title: String, _ name: String) -> some View {
        ZStack(alignment: .topLeading) {
            BundleImage(name: name).aspectRatio(1000.0 / 800.0, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
            Text(title).font(.inter(size: 12, weight: .bold)).padding(.horizontal, 10).padding(.vertical, 5)
                .background(Capsule().fill(.black.opacity(0.6))).padding(10)
        }
    }
}

/// Reusable hold timer. Finishing it only buzzes: it never marks anything done.
struct HoldTimer: View {
    @EnvironmentObject var model: AppModel
    let seconds: Int
    @State private var left: Int?
    @State private var task: Task<Void, Never>?

    var body: some View {
        let running = left != nil
        VStack(spacing: 12) {
            ZStack {
                Circle().stroke(Color.white.opacity(0.12), lineWidth: 8)
                Circle().trim(from: 0, to: CGFloat(left ?? 0) / CGFloat(seconds))
                    .stroke(mobTint, style: StrokeStyle(lineWidth: 8, lineCap: .round)).rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: left)
                Text("\(left ?? seconds)").font(.inter(size: 44, weight: .heavy)).monospacedDigit()
            }.frame(width: 140, height: 140)
            Button(running ? "Reset" : "Start \(seconds)-second hold") { running ? stop() : start() }
                .buttonStyle(StrataButtonStyle(kind: running ? .plain : .mint))
        }
        .frame(maxWidth: .infinity).card()
        .onDisappear { stop() }
    }

    private func start() {
        left = seconds
        task = Task { @MainActor in
            while let l = left, l > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if Task.isCancelled { return }
                left = l - 1
            }
            model.cue()
            try? await Task.sleep(nanoseconds: 800_000_000)
            if !Task.isCancelled { left = nil }
        }
    }
    private func stop() { task?.cancel(); task = nil; left = nil }
}
