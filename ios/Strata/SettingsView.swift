import SwiftUI
import StrataCore
import UniformTypeIdentifiers

/// The export file (`exportBtn`): the same JSON a web export holds.
struct ExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data: Data
    init(data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws { data = configuration.file.regularFileContents ?? Data() }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: data) }
}

/// Settings (app.js `settingsView`).
struct SettingsView: View {
    @EnvironmentObject var model: AppModel
    @State private var name = ""
    @State private var seeded = false
    @State private var genderPrompt: String?
    @State private var pendingGender: String?
    @State private var injPrompt: String?
    @State private var pendingInj: String?
    @State private var resetPrompt = false
    @State private var exporting = false
    @State private var exportDoc = ExportDocument(data: Data())
    @State private var importing = false
    @FocusState private var nameFocus: Bool

    var body: some View {
        let e = model.engine!
        let hr = e.rcHR(), off = e.officeDays()
        ScrollView {
            VStack(spacing: 0) {
                Hero(eyebrow: nil, title: "Settings", sub: "Profile, injuries, schedule and data.")
                VStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("You").labelStyle()
                        HStack {
                            Text("Name").nameStyle()
                            TextField("", text: $name).focused($nameFocus).multilineTextAlignment(.trailing)
                                .font(.system(size: 17, weight: .semibold)).textContentType(.givenName)
                                .onSubmit { commitName() }
                        }
                        .padding(.horizontal, 14).padding(.vertical, 6).frame(minHeight: 46)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color.black.opacity(0.25))).padding(.top, 10)
                        Seg(items: [("male", "Male"), ("female", "Female")], selected: e.profile.gender) { g in
                            if g != e.profile.gender { pendingGender = g; genderPrompt = e.genderPrompt(g) }
                        }.padding(.top, 10)
                        Text("Gender sets the plan template and starting loads. Your history and weights stay when you change it.")
                            .font(.system(size: 13)).foregroundStyle(Theme.muted).padding(.top, 10)
                    }.card()

                    VStack(alignment: .leading, spacing: 0) {
                        Text("Injury flags").labelStyle()
                        Text("Flagging one holds every lift that loads it and adds safer substitutes.").font(.system(size: 13)).foregroundStyle(Theme.muted).padding(.top, 6).padding(.bottom, 4)
                        ForEach(e.catalog.injShow.indices, id: \.self) { i in
                            let k = e.catalog.injShow[i][0], l = e.catalog.injShow[i][1]
                            let rec = e.db.injuries.first { $0.key == k }
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(l).nameStyle(15)
                                    if let r = rec { Text("Since \(Dates.fmtD(r.since, .init(month: .short, day: true))) · \(r.ids.count) lifts on hold").metaStyle() }
                                }
                                Spacer()
                                WebSwitch(isOn: Binding(get: { rec != nil }, set: { _ in toggleInjury(k) }), label: l)
                            }.padding(.vertical, 12).overlay(alignment: .top) { if i > 0 { Rectangle().fill(Theme.line).frame(height: 1) } }
                        }
                    }.card()

                    VStack(alignment: .leading, spacing: 0) {
                        Text("Office days").labelStyle()
                        Text("Walking to work is your easy cardio on these days. With 2 office days the 4×4 moves to Sunday.")
                            .font(.system(size: 13)).foregroundStyle(Theme.muted).padding(.top, 6).padding(.bottom, 10)
                        DayChips(selected: off) { d in model.mutate { $0.toggleOfficeDay(d); return nil } }
                        Text("Lift days are Mon, Wed, Fri, Sat. An office day on a lift day keeps the lift.").font(.system(size: 13)).foregroundStyle(Theme.muted).padding(.top, 10)
                    }.card()

                    VStack(alignment: .leading, spacing: 0) {
                        Text("Heart zones").labelStyle()
                        HStack {
                            Text("Age").nameStyle(15); Spacer()
                            HStack(spacing: 10) {
                                ageButton("−", "Younger", -1)
                                Text(e.db.age.map { jsMinutes($0) } ?? "—").font(.system(size: 22, weight: .heavy)).monospacedDigit().frame(minWidth: 36)
                                ageButton("+", "Older", 1)
                            }.padding(4).background(RoundedRectangle(cornerRadius: 16).fill(Color.black.opacity(0.25)))
                        }.padding(.vertical, 12)
                        if let hr = hr {
                            line("Zone 2 (easy)", "\(hr.z2[0])–\(hr.z2[1]) bpm", Color.white)
                            line("4×4 hard", "\(hr.hard[0])–\(hr.hard[1]) bpm", Theme.coral)
                            Text("Estimated max \(hr.max) bpm.").font(.system(size: 13)).foregroundStyle(Theme.muted).padding(.top, 6)
                        }
                    }.card()

                    VStack(alignment: .leading, spacing: 0) {
                        Text("Data").labelStyle()
                        dataRow(Icon.dl, "Export data", .white) { export() }
                        dataRow(Icon.ul, "Import (Strata or Lift Log file)", .white) { importing = true }
                        dataRow(Icon.close, "Reset \(e.profile.name)", Color(hex: "#FF8A70")) { resetPrompt = true }
                    }.card()
                    Text("Strata · data stays on this phone. Export it now and then as a backup.")
                        .font(.system(size: 13)).foregroundStyle(Theme.muted).multilineTextAlignment(.center).frame(maxWidth: .infinity)
                }.padding(.horizontal, Theme.gutter).padding(.top, 14).padding(.bottom, 110)
            }.frame(maxWidth: Theme.maxWidth)
        }
        .onAppear { if !seeded { name = e.profile.name; seeded = true } }
        .onChange(of: nameFocus) { _, f in if !f { commitName() } }
        .alert(genderPrompt ?? "", isPresented: Binding(get: { genderPrompt != nil }, set: { if !$0 { genderPrompt = nil } })) {
            Button("Switch") { if let g = pendingGender { model.mutate { $0.setGender(g) } }; genderPrompt = nil }
            Button("Cancel", role: .cancel) { genderPrompt = nil }
        }
        .alert(injPrompt ?? "", isPresented: Binding(get: { injPrompt != nil }, set: { if !$0 { injPrompt = nil } })) {
            Button("Flag") { if let k = pendingInj { model.mutate { $0.applyInjury(k) } }; injPrompt = nil }
            Button("Cancel", role: .cancel) { injPrompt = nil }
        }
        .alert(e.resetPrompt, isPresented: $resetPrompt) {
            Button("Reset", role: .destructive) { model.mutate { $0.reset() } }
            Button("Cancel", role: .cancel) {}
        }
        .alert(model.importPrompt ?? "", isPresented: Binding(get: { model.importPrompt != nil }, set: { if !$0 { model.importPrompt = nil; model.importPending = nil } })) {
            Button("Import", role: .destructive) { model.confirmImport() }
            Button("Cancel", role: .cancel) { model.importPrompt = nil; model.importPending = nil }
        }
        .fileExporter(isPresented: $exporting, document: exportDoc, contentType: .json, defaultFilename: e.exportFileName().replacingOccurrences(of: ".json", with: "")) { _ in }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { r in if case .success(let u) = r { model.beginImport(u) } }
    }

    private func commitName() {
        let n = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if n.isEmpty { name = model.engine?.profile.name ?? ""; return }
        if n != model.engine?.profile.name { model.mutate { $0.rename(n) } }
    }
    private func toggleInjury(_ k: String) {
        let e = model.engine!
        if e.db.injuries.contains(where: { $0.key == k }) { model.mutate { $0.releaseInjury(k) } }
        else { pendingInj = k; injPrompt = e.injuryPrompt(k) }
    }
    private func export() {
        if let d = try? model.engine!.exportData() { exportDoc = ExportDocument(data: d); exporting = true }
    }
    private func ageButton(_ t: String, _ label: String, _ dir: Int) -> some View {
        Button { model.mutate { $0.adjustAge(dir); return nil } } label: {
            Text(t).font(.system(size: 22, weight: .semibold)).frame(width: 40, height: 40)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.1)))
        }.buttonStyle(.plain).accessibilityLabel(label)
    }
    private func line(_ l: String, _ v: String, _ c: Color) -> some View {
        HStack { Text(l).font(.system(size: 15)); Spacer(); Text(v).font(.system(size: 15, weight: .bold)).foregroundStyle(c) }
            .padding(.vertical, 12).overlay(alignment: .top) { Rectangle().fill(Theme.line).frame(height: 1) }
    }
    private func dataRow(_ icon: String, _ title: String, _ color: Color, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                IconView(d: icon, size: 20, color: color == .white ? Theme.soft : color).frame(width: 40, height: 40)
                    .background(Circle().fill(Color.white.opacity(0.1)))
                Text(title).nameStyle(15, color: color)
                Spacer(minLength: 0)
                if color == .white { IconView(d: Icon.chev, size: 18, color: Color(hex: "#A9AEBD"), line: 2.4) }
            }.padding(.vertical, 10).overlay(alignment: .top) { Rectangle().fill(Theme.line).frame(height: 1) }
        }.buttonStyle(.plain)
    }
}

extension AppModel {
    /// Pick a file: read it, then ask what the web asks before replacing the data.
    func beginImport(_ url: URL) {
        guard let e = engine else { return }
        let ok = url.startAccessingSecurityScopedResource()
        defer { if ok { url.stopAccessingSecurityScopedResource() } }
        guard let data = try? Data(contentsOf: url), let p = try? AppData.load(from: data),
              (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["history"] is [Any] else {
            show("That file is not a valid export"); return
        }
        importPending = p
        let header = (try? JSONDecoder().decode(ExportHeader.self, from: data)) ?? ExportHeader()
        if let msg = e.importPrompt(header, quiet: false) { importPrompt = msg } else { confirmImport() }
    }
    func confirmImport() {
        guard let p = importPending else { return }
        importPrompt = nil; importPending = nil
        mutate { $0.applyImport(p); return "Imported \($0.db.history.count) sessions" }
    }
}
