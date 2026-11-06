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

/// The short card under the rings on Move: the most useful observation right now.
/// Tap to see the next one when there are several.
struct InsightCard: View {
    let insights: [Insight]
    @State private var index = 0

    var body: some View {
        if let it = insights.isEmpty ? nil : insights[min(index, insights.count - 1)] {
            let tint = Self.tint(it.kind)
            Button {
                withAnimation(.easeOut(duration: 0.15)) { index = (index + 1) % insights.count }
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle().fill(tint.opacity(0.18))
                        IconView(d: Self.icon(it.kind), size: 20, color: tint, line: 2.2)
                    }.frame(width: 40, height: 40)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(it.title).nameStyle(15)
                        Text(it.body).font(.inter(size: 13)).foregroundStyle(Theme.muted)
                            .lineLimit(2).fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                    if insights.count > 1 {
                        VStack(spacing: 4) {
                            ForEach(insights.indices, id: \.self) { i in
                                Circle().fill(i == min(index, insights.count - 1) ? Color.white : Color.white.opacity(0.25))
                                    .frame(width: 5, height: 5)
                            }
                        }
                    }
                }
                .padding(.horizontal, 14).padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: Theme.Radius.card).fill(Theme.glass))
                .overlay(RoundedRectangle(cornerRadius: Theme.Radius.card).strokeBorder(tint.opacity(0.35)))
            }
            .buttonStyle(.plain)
            .accessibilityHint(insights.count > 1 ? "Shows the next insight" : "")
        }
    }

    private static func tint(_ k: Insight.Kind) -> Color {
        switch k {
        case .muscle: return Theme.ring("m")
        case .heart, .steps: return Theme.ring("h")
        case .bone: return Theme.ring("b")
        case .sleep: return Theme.amber
        case .onTrack: return Theme.mint
        case .remaining: return Theme.soft
        }
    }

    private static func icon(_ k: Insight.Kind) -> String {
        switch k {
        case .muscle: return Icon.dumbbell
        case .heart: return Icon.heart
        case .bone: return Icon.bone
        case .steps: return Icon.walk
        case .sleep: return Icon.timer
        case .onTrack: return Icon.check
        case .remaining: return Icon.cal
        }
    }
}
