import SwiftUI
import StrataCore

/// Rest timer card (`restBanner`).
struct RestBanner: View {
    @EnvironmentObject var model: AppModel
    var body: some View {
        if let e = model.engine, let r = e.rest, (r.endAt - AppModel.nowMs()) > -1000 {
            TimelineView(.periodic(from: .now, by: 0.5)) { _ in
                let rem = max(0, (r.endAt - AppModel.nowMs()) / 1000)
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(rem > 0 ? "Rest" : "Go").labelStyle(rem > 0 ? Theme.violet : Theme.mint)
                        Text(Fmt.mmss(rem.rounded(.up))).font(.system(size: 30, weight: .bold)).monospacedDigit()
                        if let n = r.next { Text(n).metaStyle() }
                    }
                    Spacer(minLength: 0)
                    Button("+30 s") { model.extendRest() }.buttonStyle(StrataButtonStyle(small: true)).fixedSize()
                    Button("Skip") { model.skipRest() }.buttonStyle(StrataButtonStyle(small: true)).fixedSize()
                }
                .padding(.horizontal, 16).padding(.vertical, 14)
                .background(RoundedRectangle(cornerRadius: 22).fill(Theme.glass))
                .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(Theme.violet.opacity(0.45)))
            }
        }
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
            Text(state.label).font(.system(size: 18, weight: .bold)).foregroundStyle(Theme.muted)
            Text("\(state.n)").font(.system(size: 160, weight: .heavy)).foregroundStyle(.white).id(state.n)
                .transition(.scale(scale: 1.5).combined(with: .opacity))
            Text("Get ready").font(.system(size: 18, weight: .bold)).foregroundStyle(Theme.muted.opacity(0.6))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "#0A0B10").opacity(0.94).ignoresSafeArea())
        .animation(.easeOut(duration: 0.5), value: state.n)
    }
}

/// Bottom dock with two buttons (Discard + Complete)
struct WorkoutDock<Trailing: View>: View {
    let discard: () -> Void
    @ViewBuilder var trailing: () -> Trailing
    var body: some View {
        HStack(spacing: 10) {
            Button("Discard", action: discard).buttonStyle(StrataButtonStyle())
            trailing().frame(maxWidth: .infinity).layoutPriority(1)
        }
        .padding(.horizontal, 16).padding(.top, 14).padding(.bottom, 8)
        .background(LinearGradient(colors: [Theme.bg.opacity(0), Theme.bg.opacity(0.94)], startPoint: .top, endPoint: .init(x: 0.5, y: 0.35)))
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
