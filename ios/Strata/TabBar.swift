import SwiftUI
import StrataCore

/// The floating tab bar (`#tabs`): Today, Progress, History, Settings. Only on those four screens.
struct TabBar: View {
    @EnvironmentObject var model: AppModel
    let current: Screen

    private let tabs: [(Screen, String, String)] = [
        (.today, "Today", Icon.home), (.progress, "Progress", Icon.chart), (.history, "History", Icon.cal), (.settings, "Settings", Icon.gear)]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs.indices, id: \.self) { i in
                let (s, label, icon) = tabs[i]
                let on = current == s || (s == .history && isDetail)
                Button {
                    model.selDay = nil
                    model.go(s)
                } label: {
                    VStack(spacing: 3) {
                        IconView(d: icon, size: 22, color: on ? .white : Theme.muted, line: s == .today || s == .history || s == .settings ? 2 : 2.2)
                        Text(label).font(.inter(size: 11, weight: .semibold)).foregroundStyle(on ? .white : Theme.muted)
                    }
                    .frame(maxWidth: .infinity).frame(height: 56)
                    .background(Capsule().fill(on ? Color.white.opacity(0.12) : .clear))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .padding(6).frame(height: 68).frame(maxWidth: Theme.maxWidth - 24)
        .background(Capsule().fill(Color(hex: "#161924").opacity(0.82)).background(.ultraThinMaterial, in: Capsule()))
        .overlay(Capsule().strokeBorder(Theme.line))
        .padding(.horizontal, 12).padding(.bottom, 10)
    }
    private var isDetail: Bool { if case .detail = current { return true } else { return false } }
}
