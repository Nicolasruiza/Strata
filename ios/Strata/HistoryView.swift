import SwiftUI
import StrataCore

/// History (app.js `historyView`, `histRow`).
struct HistoryView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        let e = model.engine!
        let items = e.historyItems()
        ScrollView {
            VStack(spacing: 0) {
                Hero(eyebrow: nil, title: "History", sub: "Your sessions, week by week.")
                VStack(spacing: 12) {
                    if items.isEmpty {
                        Text("Nothing logged yet. Your first workout will show up here.")
                            .font(.inter(size: 14)).foregroundStyle(Theme.muted).multilineTextAlignment(.center)
                            .padding(.vertical, 26).padding(.horizontal, 10).frame(maxWidth: .infinity).card()
                    } else {
                        let weeks = Dictionary(grouping: items, by: { Dates.mondayOf($0.date) })
                        let curMon = Dates.mondayOf(e.today)
                        let wp = e.weekPlan(), planned = Engine.wdOrder.filter { wp[$0] != "rest" }.count
                        ForEach(weeks.keys.sorted().reversed(), id: \.self) { m in
                            weekCard(e, m: m, list: weeks[m]!, curMon: curMon, planned: planned)
                        }
                    }
                }.padding(.horizontal, Theme.gutter).padding(.top, 14).padding(.bottom, 110)
            }.frame(maxWidth: Theme.maxWidth)
        }
    }

    private func weekCard(_ e: Engine, m: String, list: [HistoryItem], curMon: String, planned: Int) -> some View {
        let st = e.weekStats(m)
        let opts = Dates.FmtOpts(month: .short, day: true)
        return VStack(spacing: 0) {
            HStack {
                Text("\(Dates.fmtD(m, opts)) – \(Dates.fmtD(Dates.addDays(m, 6), opts))").nameStyle()
                Spacer()
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        ForEach(0..<3, id: \.self) { i in
                            Circle().fill(st.closed[i] ? Theme.ring(["m", "h", "b"][i]) : Color.white.opacity(0.14)).frame(width: 9, height: 9)
                        }
                    }
                    Text(m == curMon ? "\(list.count) of \(planned)" : "\(list.count) session\(list.count > 1 ? "s" : "")").smallStyle()
                }
            }.padding(.horizontal, 4).padding(.top, 4).padding(.bottom, 8)
            ForEach(list.indices, id: \.self) { i in row(e, list[i], first: i == 0) }
        }.card(tight: true)
    }

    private func row(_ e: Engine, _ it: HistoryItem, first: Bool) -> some View {
        let t = e.historyRow(it)
        let wk = Dates.fmtD(it.date, .init(weekday: .short)), md = Dates.fmtD(it.date, .init(month: .short, day: true))
        return Button {
            if it.kind == "lift" { model.go(.detail(index: it.index)) }
            else { model.sheet = .editCardio(date: it.date, type: it.kind) }
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 0) { Text(wk); Text(md) }
                    .font(.inter(size: 12)).foregroundStyle(Theme.muted).lineSpacing(2).frame(width: 46, alignment: .leading)
                ZStack {
                    Circle().fill((t.icon == "lift" || t.icon == "home") ? Theme.violet.opacity(0.18) : Theme.coral.opacity(0.18))
                    IconView(d: t.icon == "lift" ? Icon.dumbbell : t.icon == "home" ? Icon.home : t.icon == "heart" ? Icon.heart : Icon.walk,
                             size: 20, color: (t.icon == "lift" || t.icon == "home") ? Theme.violet : Theme.coral, line: t.icon == "home" ? 2 : 2.2)
                }.frame(width: 40, height: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text(t.name).nameStyle()
                    meta(t)
                }
                Spacer(minLength: 0)
                Text(t.right).font(.inter(size: 15, weight: .semibold))
                IconView(d: Icon.chev, size: 18, color: Color(hex: "#A9AEBD"), line: 2.4)
            }
            .padding(.vertical, 10).padding(.horizontal, 4)
            .overlay(alignment: .top) { if !first { Rectangle().fill(Theme.line).frame(height: 1) } }
            .contentShape(Rectangle())
        }.buttonStyle(.plain)
    }

    @ViewBuilder
    private func meta(_ t: HistoryRowText) -> some View {
        if t.jumps, let r = t.meta.range(of: "jumps") {
            (Text(String(t.meta[..<r.lowerBound])).foregroundColor(Theme.muted) + Text("jumps").foregroundColor(Theme.mint)
                + Text(String(t.meta[r.upperBound...])).foregroundColor(Theme.muted)).font(.inter(size: 13))
        } else { Text(t.meta).metaStyle() }
    }
}
