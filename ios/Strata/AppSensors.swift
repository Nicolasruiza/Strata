import CoreLocation
import StrataCore

/// What the elevation stat says while there is no altitude yet (Config.Copy): Q4's mapping.
enum LocationState: Equatable { case waiting, noGPS, preciseOff }

/// workout.js `Sensors`, real sources only. Altitude comes from Core Location on outdoor
/// activities (readings less accurate than `elevMaxAccuracyM` are dropped). Heart rate has no
/// source until the watch app exists (phase 4), so `read` returns nil heart rate and the screen
/// shows "—". There is no demo source anywhere.
final class AppSensors: NSObject, Sensors, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var altitude: Double?
    var onStateChange: ((LocationState) -> Void)?
    weak var bridge: WatchBridge?
    private(set) var state: LocationState = .waiting { didSet { if state != oldValue { onStateChange?(state) } } }

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func start(_ live: LiveCardio) {
        stop()
        guard Catalog.shared.cardioActs[live.act]?.out == true else { return }     // indoor never asks for location
        update()
        if manager.authorizationStatus == .notDetermined { manager.requestWhenInUseAuthorization() }
        manager.startUpdatingLocation()
    }

    func stop() {
        manager.stopUpdatingLocation()
        altitude = nil
        state = .waiting
    }

    func read(_ t: Double) -> SensorReading { SensorReading(hr: bridge?.reading(), alt: altitude) }
    func hrSource() -> String? { bridge?.isConnected == true ? "watch" : nil }

    private func update() {
        if !CLLocationManager.locationServicesEnabled() { state = .noGPS; return }
        switch manager.authorizationStatus {
        case .denied, .restricted: state = .noGPS
        default: state = manager.accuracyAuthorization == .reducedAccuracy && manager.authorizationStatus != .notDetermined ? .preciseOff : .waiting
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) { update() }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let l = locations.last else { return }
        // verticalAccuracy < 0 means no valid altitude
        if l.verticalAccuracy >= 0 && l.verticalAccuracy <= Config.workout.elevMaxAccuracyM { altitude = l.altitude }
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}
}
