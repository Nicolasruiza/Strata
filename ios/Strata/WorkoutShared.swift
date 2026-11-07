import SwiftUI
import StrataCore

/// Rest timer card (`restBanner`).
struct RestBanner: View {
    @EnvironmentObject var model: AppModel
    /// When set, the banner keeps its place (same size) while no rest is running, so the screen doesn't jump
    /// when a set is logged and the rest appears. `big` is the status line, `meta` the small line under it.
    var idle: (big: String, meta: String)? = nil

    var body: some View {
        if let e = model.engine, let r = e.rest, (r.endAt - AppModel.nowMs()) > -1000 {
            TimelineView(.periodic(from: .now, by: 0.5)) { _ in
                let rem = max(0, (r.endAt - AppModel.nowMs()) / 1000)
                card(label: rem > 0 ? "Rest" : "Go", color: rem > 0 ? Theme.violet : Theme.mint,
                     big: Fmt.mmss(rem.rounded(.up)), meta: r.next, border: Theme.violet.opacity(0.45), buttons: true)
            }
        } else if let i = idle {
            card(label: "Ready", color: Theme.mint, big: i.big, meta: i.meta, border: Theme.line, buttons: false)
        }
    }

    private func card(label: String, color: Color, big: String, meta: String?, border: Color, buttons: Bool) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label).labelStyle(color)
                Text(big).font(.inter(size: 30, weight: .bold)).monospacedDigit()
                Text(meta ?? " ").metaStyle()
            }
            Spacer(minLength: 0)
            Group {
                Button("+30 s") { model.extendRest() }.buttonStyle(StrataButtonStyle(small: true, hPad: 14)).fixedSize()
                Button("Skip") { model.skipRest() }.buttonStyle(StrataButtonStyle(small: true, hPad: 14)).fixedSize()
            }.opacity(buttons ? 1 : 0).allowsHitTesting(buttons)
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 22).fill(Theme.glass))
        .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(border))
    }
}

/// Elapsed clock text, ticking each second from a start timestamp.
struct ElapsedText: View {
    let since: Double
    var suffix = ""
    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { _ in
            Text(Fmt.mmss(max(0, ((AppModel.nowMs() - since) / 1000).rounded(.down))) + suffix)
        }
    }
}

/// The 3-2-1 overlay (`.cd`).
struct CountdownOverlay: View {
    let state: CountdownState
    var body: some View {
        VStack(spacing: 12) {
            Text(state.label).font(.inter(size: 18, weight: .bold)).foregroundStyle(Theme.muted)
            Text("\(state.n)").font(.inter(size: 160, weight: .heavy)).foregroundStyle(.white).id(state.n)
                .transition(.scale(scale: 1.5).combined(with: .opacity))
            Text("Get ready").font(.inter(size: 18, weight: .bold)).foregroundStyle(Theme.muted.opacity(0.6))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "#0A0B10").opacity(0.94).ignoresSafeArea())
        .animation(.easeOut(duration: 0.5), value: state.n)
    }
}

/// Two dock buttons side by side, 1 : 1.5 (`.dock>*{flex:1}` and `.w2{flex:1.5}`).
struct DockRow<Left: View, Right: View>: View {
    @ViewBuilder var left: () -> Left
    @ViewBuilder var right: () -> Right
    var body: some View {
        GeometryReader { g in
            let w = g.size.width - 10
            HStack(spacing: 10) {
                left().frame(width: w * 0.4)
                right().frame(width: w * 0.6)
            }
        }
        .frame(height: Theme.Size.buttonHeight)
        .padding(.horizontal, 16).padding(.top, 14).padding(.bottom, 8)
        .background(LinearGradient(colors: [Theme.bg.opacity(0), Theme.bg.opacity(0.94)], startPoint: .top, endPoint: .init(x: 0.5, y: 0.35)))
    }
}

/// Bottom dock with Discard + a main button
struct WorkoutDock<Trailing: View>: View {
    let discard: () -> Void
    @ViewBuilder var trailing: () -> Trailing
    var body: some View {
        DockRow {
            Button("Discard", action: discard).buttonStyle(StrataButtonStyle())
        } right: { trailing() }
    }
}

/// `.wck` check circle
struct CheckDot: View {
    var filled = true
    var color: Color = Theme.violet
    var body: some View {
        ZStack {
            if filled { Circle().fill(color); IconView(d: Icon.check, size: 16, color: Color(hex: "#0E1018"), line: 3) }
            else { Circle().strokeBorder(Color.white.opacity(0.3), lineWidth: 2) }
        }.frame(width: 30, height: 30)
    }
}

let discardMessage = "Discard this workout? Nothing will be saved."
