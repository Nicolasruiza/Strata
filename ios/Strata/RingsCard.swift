import SwiftUI
import StrataCore

/// One activity ring (`ringSVG`).
struct RingView: View {
    let kind: String              // m, h, b
    let done: Int, target: Int
    var size: CGFloat = 84
    var body: some View {
        let r = size / 2 - 7, f = min(1, target > 0 ? Double(done) / Double(target) : 0), col = Theme.ring(kind), closed = f >= 1
        ZStack {
            Circle().stroke(col.opacity(0.2), lineWidth: 9).frame(width: r * 2, height: r * 2)
            if f > 0 {
                Circle().trim(from: 0, to: f).stroke(col, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                    .rotationEffect(.degrees(-90)).frame(width: r * 2, height: r * 2)
            }
            IconView(d: kind == "m" ? Icon.dumbbell : kind == "h" ? Icon.heart : Icon.bone, size: size * 0.34, color: col)
        }
        .frame(width: size, height: size)
        .shadow(color: closed ? col.opacity(0.53) : .clear, radius: 10)
    }
}

/// `ringsCard(st, headline)`
struct RingsCard: View {
    let st: WeekStats
    let headline: String?
    var body: some View {
        let n = st.closed.filter { $0 }.count
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text("This week").labelStyle()
                Spacer()
                Text(n == 3 ? "All 3 rings closed" : "\(n) of 3 rings closed")
                    .font(.inter(size: 13, weight: .semibold)).foregroundStyle(n == 3 ? Theme.mint : Theme.muted)
            }
            HStack {
                cell("m", "Muscle", st.m, st.mt); Spacer(minLength: 0)
                cell("h", "Heart", st.h, st.ht); Spacer(minLength: 0)
                cell("b", "Bone", st.b, st.bt)
            }
            .padding(.top, 14).padding(.bottom, 10).padding(.horizontal, 8)
            if let h = headline { Text(h).bodyStyle() }
        }
        .card()
    }

    private func cell(_ k: String, _ label: String, _ d: Int, _ t: Int) -> some View {
        VStack(spacing: 4) {
            RingView(kind: k, done: d, target: t)
            Text(label).font(.inter(size: 13, weight: .semibold))
            Text("\(d)/\(t)").font(.inter(size: 14, weight: .bold)).monospacedDigit()
        }
        .frame(minWidth: 84)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label) \(d) of \(t)")
    }
}

/// Slim version for the top of Today: just the three rings with "Muscle 2/4" under each.
struct CompactRings: View {
    let st: WeekStats
    var body: some View {
        HStack {
            cell("m", "Muscle", st.m, st.mt); Spacer(minLength: 0)
            cell("h", "Heart", st.h, st.ht); Spacer(minLength: 0)
            cell("b", "Bone", st.b, st.bt)
        }
        .padding(.horizontal, 18).padding(.vertical, 12)
        .card(tight: true)
    }

    private func cell(_ k: String, _ label: String, _ d: Int, _ t: Int) -> some View {
        VStack(spacing: 2) {
            RingView(kind: k, done: d, target: t, size: 64)
            Text("\(label) \(d)/\(t)").font(.inter(size: 13, weight: .semibold)).monospacedDigit()
        }
        .frame(minWidth: 84)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label) \(d) of \(t)")
    }
}
