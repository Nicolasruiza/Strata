import SwiftUI
import StrataCore
import HealthKit
import WatchKit

/// The Strata watch app: it runs the workout session the phone starts, streams heart rate to the
/// phone and saves the workout to Apple Health. It has no screens of its own beyond what the
/// session shows (heart rate and time), because the web app has none either.
@main
struct StrataWatchApp: App {
    @WKApplicationDelegateAdaptor(WatchDelegate.self) var delegate
    var body: some Scene {
        WindowGroup { WatchRootView().environmentObject(WatchWorkout.shared) }
    }
}

final class WatchDelegate: NSObject, WKApplicationDelegate {
    /// `HKHealthStore.startWatchApp(toHandle:)` from the phone lands here.
    func handle(_ workoutConfiguration: HKWorkoutConfiguration) {
        Task { @MainActor in await WatchWorkout.shared.start(workoutConfiguration) }
    }
}
