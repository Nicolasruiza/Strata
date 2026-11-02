import SwiftUI
import StrataCore

/// The 4×4 info screen (app.js `vo2View`).
struct Vo2InfoView: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.safeTop) private var safeTop

    var body: some View {
        let e = model.engine!
        let n = model.vo2N ?? e.rcDefaultIntervals(), hr = e.rcHR()
        ScrollView {
            VStack(spacing: 0) {
                ZStack(alignment: .topLeading) {
                    Hero(eyebrow: "Heart · VO2 max", title: "4×4 intervals", sub: e.vo2Ramp(), image: "treadmill", brand: false)
                    GlassButton(action: { model.go(.today) }, accessibility: "Back") { IconView(d: Icon.back, size: 18, color: .white, line: 2.4) }
                        .padding(.leading, 16).padding(.top, 14 + safeTop)
                }
                VStack(spacing: 12) {
                    VStack(spacing: 0) {
                        step("10 min", "Warm-up", "Treadmill 5 km/h at 5% incline.", first: true)
                        step("4 min", "Hard", "Fast walk at 10–12% incline, or jog 9–10 km/h. By minute 2 you can only say a few words.", first: false)
                        step("3 min", "Easy", "Drop to 5 km/h, 0–3% incline. Breathe.", first: false)
                        step("\(n) ×", "Repeat hard + easy", "The timer beeps at every change.", first: false)
                        step("5 min", "Cool-down", "Slow walk.", first: false)
                    }.card()
                    Group {
                        if let hr = hr {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack { Text("Hard target").nameStyle(); Spacer(); Text("\(hr.hard[0])–\(hr.hard[1]) bpm").nameStyle(color: Theme.coral) }
                                Text("Check it on your watch. Easy phases: under \(hr.z2[1]) bpm.").font(.inter(size: 13)).foregroundStyle(Theme.muted)
                            }.padding(.horizontal, 4)
                        } else {
                            Text("Set your age in Settings to see heart-rate targets.").font(.inter(size: 13)).foregroundStyle(Theme.muted).padding(4)
                        }
                    }.card(tight: true)
                    Seg(items: [(3, "3 intervals · \(e.rcMinutes(3)) min"), (4, "4 intervals · \(e.rcMinutes(4)) min")], selected: n) { model.vo2N = $0 }
                    Button("Already did it? Log without the timer") { model.logVo2Block() }.buttonStyle(LinkButtonStyle()).frame(maxWidth: .infinity)
                }.padding(.horizontal, Theme.gutter).padding(.top, 14).padding(.bottom, 110)
            }.frame(maxWidth: Theme.maxWidth)
        }
        .safeAreaInset(edge: .bottom) {
            Button("Start 4×4") { model.pickAct = nil; model.go(.pick) }.buttonStyle(StrataButtonStyle(kind: .coral))
                .padding(.horizontal, 16).padding(.top, 14).padding(.bottom, 8)
                .background(LinearGradient(colors: [Theme.bg.opacity(0), Theme.bg.opacity(0.94)], startPoint: .top, endPoint: .init(x: 0.5, y: 0.35)))
        }
    }

    private func step(_ t: String, _ a: String, _ b: String, first: Bool) -> some View {
        HStack(spacing: 12) {
            Chip(text: t).frame(minWidth: 64)
            VStack(alignment: .leading, spacing: 2) { Text(a).nameStyle(); Text(b).metaStyle() }
            Spacer(minLength: 0)
        }.padding(.vertical, 10).overlay(alignment: .top) { if !first { Rectangle().fill(Theme.line).frame(height: 1) } }
    }
}

/// 4×4 logged without the timer (`vo2DoneView`).
struct Vo2DoneView: View {
    @EnvironmentObject var model: AppModel
    var body: some View {
        let e = model.engine!, r = e.vo2DoneView(e.vo2Done)
        ScrollView {
            VStack(spacing: 0) {
                ZStack(alignment: .bottomTrailing) {
                    Hero(eyebrow: "4×4 intervals · \(Dates.fmtD(r.v.date))", title: "Session complete", sub: r.sub, tall: true)
                    ZStack {
                        Circle().fill(LinearGradient(colors: [Color(hex: "#FF9A80"), Color(hex: "#F0583A")], startPoint: .topLeading, endPoint: .bottomTrailing))
                        IconView(d: Icon.check, size: 30, color: .white, line: 3)
                    }.frame(width: 64, height: 64).padding(.trailing, 20).padding(.bottom, 14)
                }
                VStack(spacing: 12) {
                    HStack(spacing: 0) {
                        cell("\(r.v.min)", "Minutes"); Divider().overlay(Theme.line)
                        cell("\(r.v.intervals)", "Hard intervals"); Divider().overlay(Theme.line)
                        cell("\(r.v.intervals * Config.Intervals.hardSec / 60)", "Hard minutes")
                    }.card(inset: EdgeInsets(top: 14, leading: 6, bottom: 14, trailing: 6))
                    RingsCard(st: r.st, headline: r.ringsLine)
                    Text(r.note).bodyStyle().card()
                    if let n = e.nextCard(from: r.v.date) { NextCardView(card: n) }
                }.padding(.horizontal, Theme.gutter).padding(.top, 14).padding(.bottom, 110)
            }.frame(maxWidth: Theme.maxWidth)
        }
        .safeAreaInset(edge: .bottom) {
            Button("Done") { model.mutate { $0.vo2Done = nil; return nil }; model.selDay = nil; model.go(.today) }.buttonStyle(StrataButtonStyle(kind: .primary))
                .padding(.horizontal, 16).padding(.top, 14).padding(.bottom, 8)
                .background(LinearGradient(colors: [Theme.bg.opacity(0), Theme.bg.opacity(0.94)], startPoint: .top, endPoint: .init(x: 0.5, y: 0.35)))
        }
    }
    private func cell(_ big: String, _ small: String) -> some View {
        VStack(spacing: 3) { Text(big).font(.inter(size: 24, weight: .heavy)).monospacedDigit(); Text(small).smallStyle() }.frame(maxWidth: .infinity)
    }
}
