import SwiftUI
import StrataCore

/// Cardio session complete (workout.js `cDoneView`) and the between-blocks sheet (`blockSheet`).
struct CardioDoneView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        if let e = model.engine, let v = e.wLast {
            let st = e.weekStats(Dates.mondayOf(v.date))
            let zonesTotal = max(1, (v.zones ?? []).reduce(0, +))
            let name = (e.catalog.cardioActs[v.act]?.n ?? v.act) + (v.type == "4x4" ? " · 4×4" : v.type == "z2" ? " · Zone 2" : "")
            ScrollView {
                VStack(spacing: 0) {
                    ZStack(alignment: .bottomTrailing) {
                        Hero(eyebrow: "\(name) · \(Dates.fmtD(v.date))", title: "Session complete", sub: e.cardioDoneSub(st), tall: true)
                        ZStack {
                            Circle().fill(LinearGradient(colors: [Color(hex: "#FF9A80"), Color(hex: "#F0583A")], startPoint: .topLeading, endPoint: .bottomTrailing))
                            IconView(d: Icon.check, size: 30, color: .white, line: 3)
                        }.frame(width: 64, height: 64).padding(.trailing, 20).padding(.bottom, 14)
                    }
                    VStack(spacing: 12) {
                        HStack(spacing: 0) {
                            cell(jsMinutes(v.min), "Minutes")
                            Divider().overlay(Theme.line)
                            cell(v.avgHR.map(jsMinutes) ?? "—", "Avg bpm")
                            Divider().overlay(Theme.line)
                            cell(third(v).0, third(v).1)
                        }.padding(.vertical, 14).padding(.horizontal, 6).card(tight: true)
                        if let z = v.zones {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Time in zones").labelStyle()
                                ZoneBar(z: [0] + z, tot: zonesTotal)
                                ZoneLabels(z: [0] + z)
                            }.card()
                        }
                        HStack(spacing: 8) {
                            IconView(d: Icon.heart, size: 18, color: .white, line: 2.2)
                            Text(v.health ? Config.Copy.footerSavedToHealth : Config.Copy.footerSavedInStrata).font(.system(size: 14, weight: .semibold))
                        }.padding(.horizontal, 16).padding(.vertical, 9).overlay(Capsule().strokeBorder(Theme.line))
                        RingsCard(st: st, headline: e.ringsLine(st))
                    }.padding(.horizontal, Theme.gutter).padding(.top, 14).padding(.bottom, 110)
                }.frame(maxWidth: Theme.maxWidth)
            }
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 10) {
                    Button("Add block") { model.blockSheetOpen = true }.buttonStyle(StrataButtonStyle())
                    Button("Done") { model.finishCardioScreen() }.buttonStyle(StrataButtonStyle(kind: .primary)).frame(maxWidth: .infinity).layoutPriority(1)
                }
                .padding(.horizontal, 16).padding(.top, 14).padding(.bottom, 8)
                .background(LinearGradient(colors: [Theme.bg.opacity(0), Theme.bg.opacity(0.94)], startPoint: .top, endPoint: .init(x: 0.5, y: 0.35)))
            }
            .sheet(isPresented: $model.blockSheetOpen) { BlockSheet(v: v) }
        } else { Color.clear.onAppear { model.finishCardioScreen() } }
    }

    private func cell(_ big: String, _ small: String) -> some View {
        VStack(spacing: 3) { Text(big).font(.system(size: 24, weight: .heavy)).monospacedDigit(); Text(small).smallStyle() }.frame(maxWidth: .infinity)
    }
    private func third(_ v: WLast) -> (String, String) {
        if v.type == "4x4" { return (jsMinutes(v.intervals ?? 0), "Hard intervals") }
        if let el = v.elev { return ("+\(jsMinutes(el))", "m climbed") }
        return (v.maxHR.map(jsMinutes) ?? "—", "Max bpm")
    }
}

struct BlockSheet: View {
    @EnvironmentObject var model: AppModel
    let v: WLast
    var body: some View {
        let e = model.engine!
        let lifted = e.liftedOn(e.today) != nil, nd = e.nextDay()
        SheetChrome {
            HStack(spacing: 14) {
                CardioIcon(act: v.act, big: true)
                Text("\(e.catalog.cardioActs[v.act]?.n ?? v.act) · \(jsMinutes(v.min)) min done").title2Style(24)
            }.padding(.top, 4).padding(.bottom, 6)
            if !lifted {
                Button {
                    model.blockSheetOpen = false
                    model.jumpSets = [:]
                    model.mutate { $0.begin(day: nd); return nil }
                    model.screen = .today
                } label: {
                    HStack(spacing: 14) {
                        IconView(d: Icon.dumbbell, size: 30, color: Theme.violet, line: 2.2).frame(width: 60, height: 60)
                            .background(RoundedRectangle(cornerRadius: 18).fill(Theme.violet.opacity(0.18)))
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Recommended").font(.system(size: 12, weight: .bold)).foregroundStyle(Color(hex: "#D9D2FF"))
                                .padding(.horizontal, 10).padding(.vertical, 4).background(Capsule().fill(Theme.violet.opacity(0.25)))
                            Text("Add block:\nStrength · \(e.plan[nd]?.name ?? "")").font(.system(size: 22, weight: .heavy)).multilineTextAlignment(.leading)
                        }
                        Spacer(minLength: 0)
                        IconView(d: Icon.chev, size: 18, color: Theme.muted, line: 2.4)
                    }
                    .padding(16).frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 22).fill(LinearGradient(colors: [Theme.violet.opacity(0.18), Theme.violet.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)))
                    .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(Theme.violet.opacity(0.5)))
                }.buttonStyle(.plain).padding(.top, 10)
            }
            Button {
                model.blockSheetOpen = false
                model.show("Session saved")
            } label: {
                HStack(spacing: 12) {
                    IconView(d: Icon.flag, size: 24, color: .white, line: 1.9).frame(width: 44, height: 44)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.07)))
                    Text("End session").nameStyle()
                    Spacer(minLength: 0)
                    IconView(d: Icon.chev, size: 18, color: Theme.muted, line: 2.4)
                }
                .padding(14).frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 18).fill(Theme.glass))
                .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Theme.line))
            }.buttonStyle(.plain).padding(.top, 8)
        }
    }
}

extension AppModel {
    func finishCardioScreen() {
        selDay = nil
        mutate { $0.wLast = nil; return nil }
        screen = .today
    }
}
