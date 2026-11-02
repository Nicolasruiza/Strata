import SwiftUI
import StrataCore

/// Pick a cardio activity (workout.js `pickView`).
struct PickCardioView: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.safeTop) private var safeTop

    var body: some View {
        let e = model.engine!, P = e.cardioPlan(), sel = model.pickAct ?? P.act, cat = e.catalog
        let recent = e.recentCardio()
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    GlassButton(action: { model.pickAct = nil; model.go(.today) }, accessibility: "Back") {
                        IconView(d: Icon.back, size: 18, color: .white, line: 2.4)
                    }
                    Spacer()
                    HStack(spacing: 8) { LogoMark(); Text("Strata").font(.system(size: 20, weight: .bold)) }
                    Spacer()
                    Color.clear.frame(width: 44, height: 44)
                }
                Text("Cardio").font(.system(size: 17, weight: .bold)).foregroundStyle(Theme.coral).padding(.top, 6)
                Text("Choose your workout").font(.system(size: 34, weight: .heavy)).tracking(-0.85).padding(.top, -8)
                Button { model.pickAct = nil } label: {
                    HStack(spacing: 16) {
                        CardioIcon(act: P.act, big: true)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Recommended today:\n\(P.title)").font(.system(size: 22, weight: .heavy)).tracking(-0.2).multilineTextAlignment(.leading)
                            Text(P.sub).font(.system(size: 14)).foregroundStyle(Theme.muted).multilineTextAlignment(.leading)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(18).frame(maxWidth: .infinity, alignment: .leading)
                    .glowPanel(Theme.coral, ring: sel == P.act && model.pickAct == nil)
                }.buttonStyle(.plain)

                if !recent.isEmpty {
                    Text("Recent").font(.system(size: 20, weight: .heavy)).padding(.top, 8)
                    ForEach(recent, id: \.act) { c in
                        let act = c.act!
                        Button { model.pickAct = act } label: {
                            HStack(spacing: 12) {
                                CardioIcon(act: act)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text((cat.cardioActs[act]?.n ?? act) + (c.type == "4x4" ? " · 4×4" : c.type == "z2" ? " · Zone 2" : "")).nameStyle()
                                    Text("\(e.agoLabel(c.date)) · \(jsMinutes(c.min ?? 0)) min").metaStyle()
                                }
                                Spacer(minLength: 0)
                                IconView(d: Icon.chev, size: 16, color: Theme.muted, line: 2.4)
                            }
                            .padding(.leading, 10).padding(.trailing, 14).padding(.vertical, 10)
                            .background(RoundedRectangle(cornerRadius: 20).fill(Theme.glass))
                            .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(sel == act ? Theme.coral : Theme.line))
                        }.buttonStyle(.plain)
                    }
                }
                Text("All").font(.system(size: 20, weight: .heavy)).padding(.top, 8)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                    ForEach(cat.gridActs, id: \.self) { k in
                        let on = sel == k && model.pickAct != nil
                        Button { model.pickAct = k } label: {
                            VStack(spacing: 8) {
                                IconView(d: Icon.cardio(k), size: 32, color: Theme.coral, line: 1.9)
                                Text(cat.cardioActs[k]?.n ?? k).font(.system(size: 14, weight: .bold))
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, 16).padding(.horizontal, 6)
                            .background(RoundedRectangle(cornerRadius: 20).fill(on ? Theme.coral.opacity(0.1) : Theme.glass))
                            .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(on ? Theme.coral : Theme.line, lineWidth: on ? 1.5 : 1))
                        }.buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, Theme.gutter).padding(.top, 14 + safeTop).padding(.bottom, 110)
            .frame(maxWidth: Theme.maxWidth)
        }
        .safeAreaInset(edge: .bottom) {
            Button("Start · \(cat.cardioActs[sel]?.n ?? sel)\(P.mode != "free" ? " · \(Engine.modeLbl(P.mode))" : "")") { model.startCardio() }
                .buttonStyle(StrataButtonStyle(kind: .coral))
                .padding(.horizontal, 16).padding(.top, 14).padding(.bottom, 8)
                .background(LinearGradient(colors: [Theme.bg.opacity(0), Theme.bg.opacity(0.94)], startPoint: .top, endPoint: .init(x: 0.5, y: 0.35)))
        }
    }
}

/// `.wic.c` / `.wic.c.lg`: an activity icon in a coral tile
struct CardioIcon: View {
    let act: String
    var big = false
    var body: some View {
        let s: CGFloat = big ? 60 : 44
        IconView(d: Icon.cardio(act), size: big ? 30 : 24, color: Theme.coral, line: 1.9)
            .frame(width: s, height: s)
            .background(RoundedRectangle(cornerRadius: big ? 18 : 14).fill(Theme.coral.opacity(0.16)))
    }
}
