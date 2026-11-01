import SwiftUI
import StrataCore

/// Phase 1 shell: the app target exists and links StrataCore, with no screens yet.
/// The screens arrive in phase 2, ported 1:1 from the web app.
@main
struct StrataApp: App {
    var body: some Scene {
        WindowGroup { EmptyView() }
    }
}
