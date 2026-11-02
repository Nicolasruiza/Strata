import SwiftUI
import StrataCore

/// The locked workout (`render` wrapper: while `DB.active` exists nothing else is reachable).
/// Presented as a full-screen cover that can't be dismissed; Complete or Discard are the exits.
struct WorkoutRoot: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        GeometryReader { geo in
            let e = model.engine
            ZStack {
                Theme.bg.ignoresSafeArea()
                Group {
                    if let e = e, e.db.live != nil { CardioLiveView() }
                    else if let e = e, e.db.active != nil {
                        if e.needsJumps { JumpsView() }
                        else if e.db.active?.view == "focus" { FocusView() }
                        else { OverviewView() }
                    }
                }
                .environment(\.safeTop, geo.safeAreaInsets.top)
                if let c = model.countdown { CountdownOverlay(state: c).transition(.opacity) }
                if let t = model.toast { ToastView(text: t).frame(maxHeight: .infinity, alignment: .top).padding(.top, geo.safeAreaInsets.top + 14).allowsHitTesting(false) }
            }
        }
        .foregroundStyle(Theme.text)
        .preferredColorScheme(.dark)
        .interactiveDismissDisabled(true)
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true      // `lockScreen(true)`
            if model.engine?.db.live != nil { return }
            if let a = model.engine?.db.active, a.cd == nil, let name = model.engine?.plan[a.day]?.name {
                model.mutate { $0.markCountdownShown(); return nil }
                model.runCountdown(label: "Strength · \(name)")
            }
        }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
        .sheet(isPresented: $model.menuOpen) { WorkoutMenuSheet() }
        .sheet(isPresented: $model.swapOpen) { SwapSheet() }
        .sheet(isPresented: $model.warmOpen) { WarmSheet() }
        .alert(model.pendingEnd?.message ?? "", isPresented: Binding(get: { model.pendingEnd != nil }, set: { if !$0 { model.pendingEnd = nil } })) {
            Button(model.pendingEnd?.kind == .discard ? "Discard" : "Finish", role: model.pendingEnd?.kind == .discard ? .destructive : nil) { model.finishSession() }
            Button("Cancel", role: .cancel) { model.pendingEnd = nil }
        }
    }
}
