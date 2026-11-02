import SwiftUI
import StrataCore

/// "Next · Tomorrow" card (`nextCard`)
struct NextCardView: View {
    let card: NextCard
    var body: some View {
        let C = Theme.ring(card.col)
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16).fill(C.opacity(0.2))
                IconView(d: card.col == "m" ? Icon.dumbbell : Icon.heart, size: 24, color: C)
            }.frame(width: 52, height: 52)
            VStack(alignment: .leading, spacing: 3) {
                Text(card.label).labelStyle(C)
                Text(card.name).nameStyle()
                Text(card.sub).metaStyle()
            }
            Spacer(minLength: 0)
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.card).fill(LinearGradient(colors: [C.opacity(0.15), C.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.card).strokeBorder(C.opacity(0.33)))
    }
}

/// Workout complete (app.js `doneView`).
struct CompleteView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        if let e = model.engine, let c = e.celebration, let sum = e.sessionSummary(c) {
            let s = e.db.history[c.idx]
            let st = e.weekStats(Dates.mondayOf(s.date))
            let lifts = c.ups.count
            let name = e.profile.name
            let sub = c.low ? "Lighter day logged. Weights stay put."
                : lifts > 0 ? "Nice work, \(name). \(lifts) lift\(lifts > 1 ? "s" : "") go up next time."
                : "Logged, \(name). Same weights next time."
            ScrollView {
                VStack(spacing: 0) {
                    ZStack(alignment: .bottomTrailing) {
                        Hero(eyebrow: "\(e.plan[s.day]?.name ?? "") · \(Dates.fmtD(s.date))", title: "Workout complete", sub: sub, tall: true)
                        ZStack {
                            Circle().fill(LinearGradient(colors: [Color(hex: "#B3A6FF"), Color(hex: "#7C6CF0")], startPoint: .topLeading, endPoint: .bottomTrailing))
                            IconView(d: Icon.check, size: 30, color: .white, line: 3)
                        }
                        .frame(width: 64, height: 64)
                        .shadow(color: Color(hex: "#7C6CF0").opacity(0.55), radius: 15, y: 10)
                        .overlay(Circle().stroke(Theme.violet.opacity(0.18), lineWidth: 6))
                        .padding(.trailing, 20).padding(.bottom, 14)
                    }
                    VStack(spacing: 12) {
                        stats(s: s, sum: sum)
                        RingsCard(st: st, headline: e.ringsLine(st))
                        if !sum.rows.isEmpty { nextTime(e, sum: sum, s: s) }
                        if let cmp = sum.compare { compare(e, cmp: cmp, s: s) }
                        if e.cardioOn(s.date, "jumps") != nil { bone(st) }
                        if let n = e.nextCard(from: s.date) { NextCardView(card: n) }
                    }.padding(.horizontal, Theme.gutter).padding(.top, 14).padding(.bottom, 110)
                }.frame(maxWidth: Theme.maxWidth)
            }
            .safeAreaInset(edge: .bottom) {
                DockRow {
                    Button("Add cardio") { model.navigate(.pickCardio) }.buttonStyle(StrataButtonStyle())
                } right: {
                    Button("Done") { model.finishCelebration() }.buttonStyle(StrataButtonStyle(kind: .primary))
                }
            }
        } else {
            Color.clear.onAppear { model.finishCelebration() }
        }
    }

    private func stats(s: Session, sum: SessionSummary) -> some View {
        HStack(spacing: 0) {
            statCell(big: (s.min ?? 0) != 0 ? jsMinutes(s.min!) : "—", small: "Minutes")
            Divider().overlay(Theme.line)
            VStack(spacing: 3) {
                (Text("\(sum.mainN)/\(sum.reqCount)") + (sum.bonusN > 0 ? Text(" +\(sum.bonusN)").font(.system(size: 15)).foregroundColor(Theme.violet) : Text("")))
                    .font(.system(size: 24, weight: .heavy)).monospacedDigit()
                Text("Lifts\(sum.bonusN > 0 ? " · bonus" : "")").smallStyle()
            }.frame(maxWidth: .infinity)
            Divider().overlay(Theme.line)
            statCell(big: Fmt.nf(s.vol ?? 0), small: "lb moved")
        }.padding(.vertical, 14).padding(.horizontal, 6)
         .background(RoundedRectangle(cornerRadius: Theme.Radius.card).fill(Theme.glass))
         .overlay(RoundedRectangle(cornerRadius: Theme.Radius.card).strokeBorder(Theme.line))
    }
    private func statCell(big: String, small: String) -> some View {
        VStack(spacing: 3) { Text(big).font(.system(size: 24, weight: .heavy)).monospacedDigit(); Text(small).smallStyle() }.frame(maxWidth: .infinity)
    }

    private func nextTime(_ e: Engine, sum: SessionSummary, s: Session) -> some View {
        let rows: [SummaryRow] = sum.rows
        return VStack(alignment: .leading, spacing: 6) {
            Text("Next time").labelStyle()
            ForEach(0..<rows.count, id: \.self) { i in
                nextRow(e, rows[i], s, first: i == 0)
            }
        }.card()
    }

    private func nextRow(_ e: Engine, _ r: SummaryRow, _ s: Session, first: Bool) -> some View {
        let ex: Ex = e.exById(r.id) ?? Ex(id: r.id, n: r.id)
        let en: Entry = s.entries[r.id]!
        let reps: String = en.reps.map { Fmt.repLbl(ex, $0) }.joined(separator: " · ")
        return HStack(spacing: 12) {
            Thumb(path: e.catalog.imageName(of: r.id))
            VStack(alignment: .leading, spacing: 2) {
                Text(Fmt.cleanN(ex.n)).nameStyle()
                Text("\(reps) at \(jsMinutes(en.w)) lb").metaStyle()
                if let u = r.unlocks {
                    Text("\(jsMinutes(r.need)) more rep\(r.need > 1 ? "s" : "") unlocks \(jsMinutes(u))")
                        .font(.system(size: 13)).foregroundStyle(Theme.amber).padding(.top, 1)
                }
            }
            Spacer(minLength: 0)
            if r.up { upChip(r.next ?? 0) } else { Chip(text: "Hold \(jsMinutes(en.w))", fg: Theme.amber, bg: Theme.amber.opacity(0.14)) }
        }
        .padding(.vertical, 10)
        .overlay(alignment: .top) { if !first { Rectangle().fill(Theme.line).frame(height: 1) } }
    }

    private func upChip(_ w: Double) -> some View {
        HStack(spacing: 5) {
            IconView(d: "M12 19V5M6 11l6-6 6 6", size: 13, color: Theme.mint, line: 3.2)
            Text("\(jsMinutes(w)) lb")
        }
        .font(.system(size: 13, weight: .bold)).foregroundStyle(Theme.mint)
        .padding(.horizontal, 11).padding(.vertical, 7).background(Capsule().fill(Theme.mint.opacity(0.14)))
    }

    private func compare(_ e: Engine, cmp: SummaryCompare, s: Session) -> some View {
        let mx = max(cmp.items.map { max($0.a, $0.b) }.max() ?? 1, 1)
        return VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("vs last \(e.plan[s.day]?.name ?? "") · \(Dates.fmtD(cmp.prevDate, .init(month: .short, day: true)))").labelStyle()
                Spacer()
                Text("\(cmp.pct >= 0 ? "+" : "")\(jsMinutes(cmp.pct))%").font(.system(size: 22, weight: .heavy)).foregroundStyle(cmp.pct >= 0 ? Theme.mint : Theme.amber)
            }
            VStack(spacing: 12) {
                ForEach(cmp.items, id: \.id) { it in
                    VStack(spacing: 6) {
                        HStack {
                            Text(Fmt.cleanN(e.exById(it.id)?.n ?? it.id)).font(.system(size: 14))
                            Spacer()
                            Text("\(Fmt.nf(it.a)) lb · \(it.p >= 0 ? "+" : "")\(jsMinutes(it.p))%").font(.system(size: 14)).foregroundStyle(Theme.muted)
                        }
                        GeometryReader { g in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.white.opacity(0.08))
                                Capsule().fill(Theme.violet).frame(width: g.size.width * it.a / mx)
                                Capsule().fill(Color.white.opacity(0.28)).frame(width: g.size.width * it.b / mx)
                            }.clipShape(Capsule())
                        }.frame(height: 10)
                    }
                }
            }.padding(.top, 12)
            HStack(spacing: 14) {
                legend(Color.white.opacity(0.28), "Last time"); legend(Theme.violet, "Today"); Spacer()
            }.padding(.top, 12)
        }.card()
    }
    private func legend(_ c: Color, _ t: String) -> some View {
        HStack(spacing: 6) { RoundedRectangle(cornerRadius: 3).fill(c).frame(width: 10, height: 10); Text(t).smallStyle() }
    }

    private func bone(_ st: WeekStats) -> some View {
        HStack(spacing: 14) {
            ZStack(alignment: .leading) {
                Thumb(path: "img/pogo.jpg", size: 48).overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.bg, lineWidth: 2))
                Thumb(path: "img/box_jump.jpg", size: 48).overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.bg, lineWidth: 2)).offset(x: 34)
            }.frame(width: 82, alignment: .leading)
            VStack(alignment: .leading, spacing: 3) {
                Text("Bone · impact").labelStyle(Theme.mint)
                Text("\(st.b * Config.landingsPerJumpDay) landings this week").nameStyle()
                Text(st.b >= st.bt ? "Both jump days done. Full weekly dose." : "\(st.bt - st.b) more jump day to go.").metaStyle()
            }
            Spacer(minLength: 0)
        }.card()
    }
}

extension AppModel {
    /// "Done" on the complete screen.
    func finishCelebration() {
        mutate { $0.celebration = nil; return nil }
        selDay = nil
        screen = .today
    }
}
