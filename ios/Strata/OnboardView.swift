import SwiftUI
import StrataCore

/// First launch (app.js `onboardView`).
struct OnboardView: View {
    @EnvironmentObject var model: AppModel
    @State private var importing = false

    var body: some View {
        let o = model.onboard ?? OnboardState()
        let ready = !o.name.trimmingCharacters(in: .whitespaces).isEmpty && o.gender != nil
        ScrollView {
            VStack(spacing: 0) {
                Hero(eyebrow: nil, title: "", titleAttr: headline, titleSize: 36,
                     sub: "4 lifts, 2–3 heart sessions and 2 jump warm-ups a week. Each one closes a ring.", tall: true)
                VStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("About you").labelStyle()
                        StepField(title: "Name", placeholder: "Your name", text: nameBinding, keyboard: .default, width: nil)
                            .padding(.top, 10)
                        Seg(items: [("male", "Male"), ("female", "Female")], selected: o.gender) { model.chooseGender($0) }
                            .padding(.top, 10)
                        Text("Sets your plan template and starting loads.").font(.system(size: 13)).foregroundStyle(Theme.muted).padding(.top, 8)
                    }.card()

                    if o.gender != nil {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Bring your history").labelStyle()
                            if o.imported > 0 {
                                Text("\(o.imported) sessions imported").nameStyle(color: Theme.mint).padding(.top, 10)
                            } else {
                                Button("Import a Lift Log export file") { importing = true }
                                    .buttonStyle(StrataButtonStyle(small: true)).padding(.top, 10)
                                Text("Optional. In Lift Log: More → Export data, then pick that file here. Weights carry over, so nothing restarts.")
                                    .font(.system(size: 13)).foregroundStyle(Theme.muted).padding(.top, 8)
                            }
                        }.card()
                    }

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Age").nameStyle()
                            Text("For heart-rate targets").metaStyle()
                        }
                        Spacer()
                        StepField(title: nil, placeholder: "—", text: ageBinding, keyboard: .numberPad, width: 70, big: false, alignRight: false)
                            .font(.system(size: 22))
                    }.card()

                    VStack(alignment: .leading, spacing: 0) {
                        Text("Office days").labelStyle()
                        Text("Days you walk to work. Optional.").font(.system(size: 13)).foregroundStyle(Theme.muted).padding(.top, 6).padding(.bottom, 10)
                        DayChips(selected: o.off) { d in
                            var off = o.off
                            if let i = off.firstIndex(of: d) { off.remove(at: i) } else { off.append(d) }
                            model.onboard?.off = off.sorted()
                        }
                    }.card()
                }
                .padding(.horizontal, Theme.gutter).padding(.top, 14).padding(.bottom, 130)
            }
            .frame(maxWidth: Theme.maxWidth)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) {
            Button(ready ? "Get started" : "Add your name and gender") { model.finishOnboarding() }
                .buttonStyle(StrataButtonStyle(kind: .primary)).disabled(!ready).opacity(ready ? 1 : 0.45)
                .padding(.horizontal, 16).padding(.top, 14).padding(.bottom, 8)
                .background(LinearGradient(colors: [Theme.bg.opacity(0), Theme.bg.opacity(0.94)], startPoint: .top, endPoint: .init(x: 0.5, y: 0.35)))
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { r in
            if case .success(let url) = r { model.importFile(url) }
        }
    }

    private var headline: AttributedString {
        var a = AttributedString("Build it in layers:\n")
        var m = AttributedString("muscle"); m.foregroundColor = Theme.violet
        var h = AttributedString("heart"); h.foregroundColor = Theme.coral
        var b = AttributedString("bone"); b.foregroundColor = Theme.mint
        a.append(m); a.append(AttributedString(", ")); a.append(h); a.append(AttributedString(", ")); a.append(b)
        return a
    }
    private var nameBinding: Binding<String> {
        Binding(get: { model.onboard?.name ?? "" }, set: { model.onboard?.name = $0 })
    }
    private var ageBinding: Binding<String> {
        Binding(get: { model.onboard?.age ?? "" }, set: { model.onboard?.age = $0.filter(\.isNumber) })
    }
}

/// `.daychips` M T W T F (Monday = 1 … Friday = 5)
struct DayChips: View {
    let selected: [Int]
    let onToggle: (Int) -> Void
    var body: some View {
        HStack(spacing: 6) {
            ForEach(1...5, id: \.self) { d in
                let on = selected.contains(d)
                Button { onToggle(d) } label: {
                    Text(String(Catalog.shared.wdShort[String(d)]!.first!))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(on ? Color(hex: "#0E1018") : Theme.muted)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(on ? Color(hex: "#F4F5F8") : .clear))
                        .overlay(Circle().strokeBorder(on ? Color(hex: "#F4F5F8") : Theme.line))
                }
                .accessibilityLabel(Catalog.shared.wdLong[String(d)]!)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
    }
}
