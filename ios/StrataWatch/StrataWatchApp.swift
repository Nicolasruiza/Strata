import SwiftUI
import StrataCore

/// Phase 1 shell: the watch target exists and links StrataCore, with no screens yet.
/// The workout session and heart-rate stream arrive in phase 4.
@main
struct StrataWatchApp: App {
    var body: some Scene {
        WindowGroup { EmptyView() }
    }
}
