//
//  LocationManager.swift
//  Chat
//

import Foundation
import CoreLocation

@MainActor
final class LocationManager: NSObject, ObservableObject {
    @Published var currentLocation: CLLocationCoordinate2D?
    @Published var authorizationStatus: CLAuthorizationStatus

    private let manager = CLLocationManager()
    private var wantsContinuousUpdates = false

    private enum Mode {
        case idle
        case oneShot
        case continuous
    }
    private var mode: Mode = .idle

    override init() {
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestLocation() {
        mode = .oneShot
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            break
        }
    }

    /// Keeps publishing `currentLocation` updates as the device moves, until `stopContinuousUpdates()` is called.
    func startContinuousUpdates() {
        mode = .continuous
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.allowsBackgroundLocationUpdates = manager.authorizationStatus == .authorizedAlways && Self.supportsBackgroundLocationUpdates
            manager.startUpdatingLocation()
        default:
            break
        }
    }

    func stopContinuousUpdates() {
        mode = .idle
        if Self.supportsBackgroundLocationUpdates {
            manager.allowsBackgroundLocationUpdates = false
        }
        manager.stopUpdatingLocation()
    }

    /// Background live-location updates only work if the host app opted into the "location" UIBackgroundMode;
    /// otherwise setting `allowsBackgroundLocationUpdates` throws an assertion. Without it, updates still work
    /// while the app is foregrounded/backgrounded briefly, just not indefinitely in the background.
    private static let supportsBackgroundLocationUpdates: Bool = {
        (Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? [String])?.contains("location") ?? false
    }()
}

extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorizationStatus = status
            guard status == .authorizedWhenInUse || status == .authorizedAlways else { return }
            switch mode {
            case .continuous:
                manager.allowsBackgroundLocationUpdates = status == .authorizedAlways && Self.supportsBackgroundLocationUpdates
                manager.startUpdatingLocation()
            case .oneShot:
                manager.requestLocation()
                mode = .idle
            case .idle:
                // locationManagerDidChangeAuthorization is called *both* when the location
                // manager is created, and when the authorization changes
                // Don't do anything if it got called due to the creation of the location manager
                break
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinate = locations.last?.coordinate else { return }
        Task { @MainActor in
            self.currentLocation = coordinate
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) { }
}
