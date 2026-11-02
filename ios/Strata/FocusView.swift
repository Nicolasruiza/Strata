import SwiftUI
import StrataCore

/// One exercise in focus (workout.js `focusView`).
struct FocusView: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.safeTop) private var safeTop
    @State private var confirmDiscard = false
    @State private var partialPrompt: String?

    var body: some View {
        let e = model.engine!, A = e.db.active!
        let L = e.liftList(), idx = e.curIdx(), orig = L[idx], ex = e.shownEx(orig)
        let blk = e.woBlocks().first { $0.items.contains(orig.id) }
        let pos = (blk?.items.firstIndex(of: orig.id) ?? 0) + 1
        let n = e.setsOf(orig), p = e.progOf(orig)
        let low = A.lowEnergy ?? false
        var m = e
        let baseW = low ? m.loEnergyW(m.wOf(ex)) : m.wOf(ex)
        let w = p?.w ?? baseW, reps = p?.reps ?? []
        let last = e.lastOf(ex.id), tr = e.trendOf(ex.id)
        let exT = A.exT?[ex.id] ?? AppModel.nowMs()
        let plate = ex.bar != nil ? Fmt.plateTxt(ex, w) : ex.isEach ? "\(jsMinutes(w)) lb in each hand" : ex.hasPlates ? "Load evenly on both sides" : (ex.isBodyweight && w == 0) ? "Bodyweight" : ""
        let warm = A.warm?[ex.id] ?? []
        ScrollView {
            VStack(spacing: 0) {
                ZStack(alignment: .top) {
                    Color(hex: "#1b1e28")
                    if let img = e.catalog.imageName(of: ex.id) {
                        Color.clear.frame(height: 330 + safeTop)
                            .overlay(BundleImage(name: ((img as NSString).lastPathComponent as NSString).deletingPathExtension)).clipped()
                    }
                    LinearGradient(stops: [.init(color: Theme.bg.opacity(0.35), location: 0), .init(color: Theme.bg.opacity(0), location: 0.35), .init(color: Theme.bg, location: 1)], startPoint: .top, endPoint: .bottom)
                    HStack {
                        GlassButton(action: { model.mutate { $0.backToList(); return nil } }, accessibility: "Back to the list") {
                            IconView(d: "M15 5l-7 7 7 7", size: 18, color: .white, line: 2.4)
                        }
                        Spacer()
                        HStack(spacing: 8) { LogoMark(); Text("Strata").font(.system(size: 20, weight: .bold)) }
                        Spacer()
                        HStack(spacing: 6) {
                            IconView(d: Icon.timer, size: 18, color: .white, line: 1.9)
                            ElapsedText(since: exT).font(.system(size: 15, weight: .bold)).monospacedDigit()
                        }
                        .padding(.horizontal, 14).frame(height: 44)
                        .background(Capsule().fill(Color(hex: "#141620").opacity(0.55)))
                        .overlay(Capsule().strokeBorder(Color.white.opacity(0.18)))
                    }.padding(.horizontal, 16).padding(.top, 14 + safeTop)
                }.frame(height: 330 + safeTop).clipped()

                VStack(alignment: .leading, spacing: 14) {
                    Text("\(blk?.kind ?? "Exercise") \(pos) of \(blk?.items.count ?? 1)")
                        .font(.system(size: 14, weight: .bold)).foregroundStyle(Color(hex: "#D9D2FF"))
                        .padding(.horizontal, 12).padding(.vertical, 5)
                        .background(Capsule().fill(Theme.violet.opacity(0.18)))
                        .overlay(Capsule().strokeBorder(Theme.violet.opacity(0.6)))
                    Text(Fmt.cleanN(ex.n)).font(.system(size: 30, weight: .heavy)).tracking(-0.75).padding(.top, -6)
                    Text("\(n) sets × \(Fmt.repLbl(ex, orig.r.map(Double.init)))\(Fmt.perLeg(ex))\(ex.id != orig.id ? " · swapped" : "")").metaStyle().padding(.top, -10)
                    if orig.isInjured { WarnBox(markdown: "On hold for your injury flag. Go light or swap it.") }
                    lastCard(last: last, trend: tr)
                    RestBanner()
                    weightCard(w: w, plate: plate, ex: ex)
                    ForEach(Array(warm.enumerated()), id: \.offset) { i, s in warmRow(i, s, ex) }
                    ForEach(0..<n, id: \.self) { i in setRow(i, cur: reps.count, reps: reps, w: w, ex: ex, orig: orig, low: low) }
                    HStack(spacing: 10) {
                        Button { model.mutate { $0.addExtraSet() } } label: { plusLabel("Set") }.buttonStyle(StrataButtonStyle(small: true))
                        Button { model.warmOpen = true } label: { plusLabel("Warm-up") }.buttonStyle(StrataButtonStyle(small: true))
                    }
                    HStack(spacing: 10) {
                        Button { model.openFormVideo(id: ex.id, name: ex.n) } label: {
                            HStack(spacing: 6) { SVGPathShape(d: "M8 5v14l11-7z").fill(Color.white).frame(width: 14, height: 14); Text("Form video") }
                        }.buttonStyle(StrataButtonStyle(small: true))
                        if !(e.ap.altOf[orig.id] ?? []).isEmpty {
                            Button { model.swapOpen = true } label: {
                                HStack(spacing: 6) { IconView(d: "M7 4L3 8l4 4M3 8h14M17 20l4-4-4-4M21 16H7", size: 16, color: .white, line: 2.2); Text("Swap") }
                            }.buttonStyle(StrataButtonStyle(small: true))
                        } else { Color.clear.frame(maxWidth: .infinity) }
                    }
                    Button { busy() } label: {
                        HStack(spacing: 8) { IconView(d: "M4 7v10M20 7v10M4 12h16M7 9v6M17 9v6", size: 18, color: .white, line: 1.9); Text("Machine busy") }
                    }.buttonStyle(StrataButtonStyle(kind: .violetFlat))
                }
                .padding(.horizontal, Theme.gutter).padding(.top, -56).padding(.bottom, 110)
            }.frame(maxWidth: Theme.maxWidth)
        }
        .ignoresSafeArea(edges: .top)
        .safeAreaInset(edge: .bottom) {
            WorkoutDock(discard: { confirmDiscard = true }) {
                Button("Complete") { complete() }.buttonStyle(StrataButtonStyle(kind: .violet))
            }
        }
        .alert(discardMessage, isPresented: $confirmDiscard) {
            Button("Discard", role: .destructive) { model.mutate { $0.discardWorkout(); return nil } }
            Button("Cancel", role: .cancel) {}
        }
        .alert(partialPrompt ?? "", isPresented: Binding(get: { partialPrompt != nil }, set: { if !$0 { partialPrompt = nil } })) {
            Button("Mark done") { partialPrompt = nil; model.mutate { $0.completeExercise(confirmedPartial: true); return nil } }
            Button("Cancel", role: .cancel) { partialPrompt = nil }
        }
    }

    private func plusLabel(_ t: String) -> some View {
        HStack(spacing: 6) { IconView(d: "M12 5v14M5 12h14", size: 18, color: .white, line: 1.9); Text(t) }
    }

    private func complete() {
        if let p = model.engine!.completeExercisePrompt() { partialPrompt = p }
        else { model.mutate { $0.completeExercise(confirmedPartial: false); return nil } }
    }
    private func busy() {
        model.mutate { e in
            let r = e.markBusy()
            if r.offerSwap { model.swapOpen = true }
            return r.toasts.last      // the web's second toast replaces the first
        }
    }

    private func lastCard(last: LastEntry?, trend: Trend) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Last time").metaStyle()
                Text(last.map { "\(jsMinutes($0.w)) × " + $0.reps.map { $0.map(jsMinutes) ?? "–" }.joined(separator: "/") } ?? "No history yet")
                    .font(.system(size: 20, weight: .bold))
            }
            Spacer(minLength: 0)
            trendChip(trend)
        }.padding(.horizontal, 16).padding(.vertical, 14)
         .background(RoundedRectangle(cornerRadius: 22).fill(Theme.glass))
         .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(Theme.line))
    }

    private func trendChip(_ t: Trend) -> some View {
        let (fg, bg, br): (Color, Color, Color) = {
            switch t.c {
            case "up": return (Theme.mint, Theme.mint.opacity(0.14), Theme.mint.opacity(0.35))
            case "hold": return (Theme.amber, Theme.amber.opacity(0.14), Theme.amber.opacity(0.35))
            case "bad": return (Color(hex: "#FF8A70"), Theme.coral.opacity(0.14), Theme.coral.opacity(0.35))
            default: return (.white, Theme.glass2, .clear)
            }
        }()
        let icon = (t.t == "Progressing" || t.t == "On track") ? "M3 17l6-6 4 4 8-8M15 7h6v6" : "M3 12h18M15 6l6 6-6 6"
        return HStack(spacing: 6) { IconView(d: icon, size: 16, color: fg, line: 1.9); Text(t.t) }
            .font(.system(size: 14, weight: .bold)).foregroundStyle(fg).fixedSize()
            .padding(.horizontal, 12).padding(.vertical, 7)
            .background(Capsule().fill(bg)).overlay(Capsule().strokeBorder(br))
    }

    private func weightCard(w: Double, plate: String, ex: Ex) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Today's weight").metaStyle()
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(jsMinutes(w)).font(.system(size: 64, weight: .heavy)).tracking(-1.9).monospacedDigit()
                    Text("lb").font(.system(size: 20, weight: .semibold)).foregroundStyle(Theme.muted)
                }
                if !plate.isEmpty { Text(plate).metaStyle() }
            }
            Spacer(minLength: 0)
            stepButton("M5 12h14", "Less weight", violet: false) { model.mutate { $0.adjustWeight(-1); return nil } }
            stepButton("M12 5v14M5 12h14", "More weight", violet: true) { model.mutate { $0.adjustWeight(1); return nil } }
        }.padding(.horizontal, 16).padding(.vertical, 14)
         .background(RoundedRectangle(cornerRadius: 22).fill(Theme.glass))
         .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(Theme.line))
    }

    private func stepButton(_ d: String, _ label: String, violet: Bool, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            IconView(d: d, size: 24, color: .white, line: 1.9).frame(width: 56, height: 60)
                .background(RoundedRectangle(cornerRadius: 18).fill(violet ? Theme.violet.opacity(0.18) : Color.white.opacity(0.08)))
                .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(violet ? Theme.violet.opacity(0.6) : Theme.line))
        }.buttonStyle(.plain).accessibilityLabel(label)
    }

    private func warmRow(_ i: Int, _ s: WarmSet, _ ex: Ex) -> some View {
        HStack(spacing: 12) {
            Button { model.mutate { $0.toggleWarmup(i); return nil } } label: { CheckDot(filled: s.done) }
                .buttonStyle(.plain).accessibilityLabel("Warm-up set done")
            VStack(alignment: .leading, spacing: 2) {
                Text("Warm-up \(i + 1)").nameStyle()
                Text("\(jsMinutes(s.w)) lb × \(jsMinutes(s.r))" + (ex.bar != nil ? " · " + Fmt.plateTxt(ex, s.w) : "")).metaStyle()
            }
            Spacer(minLength: 0)
            Button("Remove") { model.mutate { $0.removeWarmup(i); return nil } }.buttonStyle(LinkButtonStyle())
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 18).fill(Theme.glass))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Theme.line, style: StrokeStyle(lineWidth: 1, dash: [4, 3])))
        .opacity(s.done ? 1 : 0.75)
    }

    @ViewBuilder
    private func setRow(_ i: Int, cur: Int, reps: [Double?], w: Double, ex: Ex, orig: Ex, low: Bool) -> some View {
        let wl = jsMinutes(w)
        if i < cur {
            HStack(spacing: 12) {
                Button { model.mutate { $0.undoSet(); return nil } } label: { CheckDot() }
                    .buttonStyle(.plain).allowsHitTesting(i == cur - 1).accessibilityLabel("Undo set \(i + 1)")
                VStack(alignment: .leading, spacing: 2) {
                    Text("Set \(i + 1)").nameStyle()
                    Text("\(wl) lb × \(Fmt.repLbl(ex, reps[i]))").metaStyle()
                }
                Spacer(minLength: 0)
                Chip(text: "Done")
            }.padding(.horizontal, 14).padding(.vertical, 12)
             .background(RoundedRectangle(cornerRadius: 18).fill(Theme.glass))
             .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Theme.line))
        } else if i == cur {
            let rv: Double = Self.currentReps(woReps: model.engine!.woReps, reps: reps, target: orig.r)
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Set \(i + 1)\(i >= (low ? Config.lighterDaySets : orig.setCount) ? " · extra" : "")").nameStyle()
                    Text("\(wl) lb × \(Fmt.repLbl(ex, orig.r.map(Double.init))) target").metaStyle()
                }
                Spacer(minLength: 0)
                HStack(spacing: 6) {
                    repButton("−", "Fewer") { model.mutate { $0.adjustReps(-1); return nil } }
                    Text(jsMinutes(rv)).font(.system(size: 22, weight: .bold)).monospacedDigit().frame(minWidth: 32)
                    repButton("+", "More") { model.mutate { $0.adjustReps(1); return nil } }
                }
                Button("Log") { model.mutate { $0.logWoSet() } }
                    .font(.system(size: 16, weight: .heavy)).foregroundStyle(Color(hex: "#0E1018"))
                    .padding(.horizontal, 16).frame(height: 44).background(RoundedRectangle(cornerRadius: 14).fill(Theme.violet))
            }.padding(.horizontal, 14).padding(.vertical, 12)
             .background(RoundedRectangle(cornerRadius: 18).fill(Theme.violet.opacity(0.08)))
             .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Theme.violet, lineWidth: 1.5))
        } else {
            HStack(spacing: 12) {
                Circle().strokeBorder(Color.white.opacity(0.3), lineWidth: 2).frame(width: 30, height: 30)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Set \(i + 1)").nameStyle()
                    Text("\(wl) lb × \(Fmt.repLbl(ex, orig.r.map(Double.init)))").metaStyle()
                }
                Spacer(minLength: 0)
            }.padding(.horizontal, 14).padding(.vertical, 12)
             .background(RoundedRectangle(cornerRadius: 18).fill(Theme.glass))
             .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Theme.line))
             .opacity(0.75)
        }
    }

    /// `rv`: the stepper value: what was typed, else the last logged rep, else the target.
    private static func currentReps(woReps: Double?, reps: [Double?], target: Int?) -> Double {
        if let w = woReps { return w }
        if let last = reps.last, let l = last { return l }
        return Double(target ?? 0)
    }

    private func repButton(_ t: String, _ label: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(t).font(.system(size: 22)).frame(width: 38, height: 44)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.08)))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.line))
        }.buttonStyle(.plain).accessibilityLabel(label)
    }
}
