import SwiftUI
import StrataCore

struct RootView: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.scenePhase) private var phase

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                Theme.bg.ignoresSafeArea()
                Group {
                    if model.onboard != nil { OnboardView() } else if model.engine != nil { TodayView() }
                }
                .environment(\.safeTop, geo.safeAreaInsets.top)
                .ignoresSafeArea(edges: .top)
                .frame(maxWidth: .infinity)
                if let t = model.toast {
                    ToastView(text: t).padding(.top, geo.safeAreaInsets.top + 14)
                        .transition(.move(edge: .top).combined(with: .opacity)).zIndex(10)
                }
            }
            .animation(.easeOut(duration: 0.25), value: model.toast)
        }
        .foregroundStyle(Theme.text)
        .preferredColorScheme(.dark)
        .onChange(of: phase) { _, p in if p == .active { model.tick() } }
        .alert("Delete this entry?", isPresented: Binding(get: { model.confirmDelete != nil }, set: { if !$0 { model.confirmDelete = nil } })) {
            Button("Delete", role: .destructive) {
                if let c = model.confirmDelete { model.mutate { $0.deleteCardio(date: c.date, type: c.type); return nil } }
                model.confirmDelete = nil; model.sheet = nil
            }
            Button("Cancel", role: .cancel) { model.confirmDelete = nil }
        }
    }
}
