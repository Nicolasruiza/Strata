import Foundation
import StrataCore

/// The web's `localStorage` as files in the app container, written atomically:
/// `me.json` (the profile, `strata:me`) and `data.json` (`DB`, `strata:v1:me`).
/// Same JSON schema as the web, so a web export imports unchanged.
struct LocalStore {
    let directory: URL

    init(directory: URL? = nil) {
        let base = directory ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Strata", isDirectory: true)
        self.directory = base
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
    }

    private var profileURL: URL { directory.appendingPathComponent("me.json") }
    private var dataURL: URL { directory.appendingPathComponent("data.json") }

    func loadProfile() -> Profile? {
        guard let d = try? Data(contentsOf: profileURL) else { return nil }
        return try? JSONDecoder().decode(Profile.self, from: d)
    }

    func loadData() -> AppData {
        guard let d = try? Data(contentsOf: dataURL), let db = try? AppData.load(from: d) else { return AppData.fresh() }
        return db
    }

    /// Returns false when the write failed, so the UI can say so (the web's "NOT SAVING").
    @discardableResult
    func save(profile: Profile, data: AppData) -> Bool {
        do {
            try JSONEncoder().encode(profile).write(to: profileURL, options: .atomic)
            try data.jsonData().write(to: dataURL, options: .atomic)
            return true
        } catch { return false }
    }
}
