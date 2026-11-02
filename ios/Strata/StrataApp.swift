import SwiftUI
import StrataCore

@main
struct StrataApp: App {
    @StateObject private var model = AppModel()
    var body: some Scene {
        WindowGroup {
            RootView().environmentObject(model)
        }
    }
}
