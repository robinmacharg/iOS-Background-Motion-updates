//
//  AppDelegate.swift
//  LMBackground3
//
//  Created by Robin Macharg2 on 04/01/2021.
//

import UIKit
import CoreLocation
import CoreMotion
import AVKit

/*

 Proof of Concept iOS app demonstrating persistent background Core Motion updates.
 Runs on a real device, not the simulator.
 
 Uses Cocoapods:
 
     $ pod install
 
 Then open the workspace.
 
 Add "Background Modes" capability with Location Updates (and Background Fetch to see
 local HTTP requests that prove the app is runnning)
 
 Add the following keys to the Info.plist with suitable descriptions:
 
     Privacy - Location Always and When in Use Usage Description
     Privacy - Location When in Use Usage Description
     Privacy - Motion Usage Description

 Start a simple webserver with (Python 2):

    $ python -m SimpleHTTPServer 8000

 Enable requests by toggling REQUESTS_ENABLED, below.  Change the IP to that of your development machine.
 
 The FLEX in-app debugger is available for e.g. untethered log viewing.
 
 Useful background:
 
 - https://stackoverflow.com/questions/20083032/coremotion-updates-in-background-state
 - https://stackoverflow.com/questions/19216169/cmmotionactivitymanager-receiving-motion-activity-updates-while-app-is-suspend?rq=1
 - https://stackoverflow.com/questions/19042894/periodic-ios-background-location-updates/19085518#19085518
 - https://stackoverflow.com/questions/20766139/iphone-collecting-coremotion-data-in-the-background-longer-than-10-mins
 
 Beacon ranging code based on Apple's self-contained beacon demo:
 
 https://developer.apple.com/documentation/corelocation/ranging_for_beacons
 
 Build and run on a separate device, adjust UUIDs appropriately, start running as a beacon  and beacon
 ranging will work.
  
 */

/**
 * CONSTANTS
 */

// Should we enable updates in the background?
let BACKGROUND_UPDATES = true

// Should we send diagnostic HTTP requests?
let REQUESTS_ENABLED = true

// The webserver address
let LOCAL_IP = "192.168.1.123"

// Whether to print diagnostic messages to the console.
let LOGGING_ENABLED = false

// How frequently to update location/motion in seconds
let UPDATE_INTERVAL = 10.0
 
// Should we play a sound when a background motion event is received?
let PLAY_SOUND = true

// UUIDs of iBeacon's to range for
let BEACON_IDS = [
    // This is the default from Apple's demo
    "E2C56DB5-DFFB-48D2-B060-D0F5A71096E0"
]

/**
 * GLOBAL HELPER FUNCTIONS
 */

// Helper function to issue a simple HTTP request.
// Allows validation of functionality when not connected to a debugger.
func requestURL(_ arg: String) {
    if REQUESTS_ENABLED {
        let param = arg.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let url = URL(string: "http://\(LOCAL_IP):8000/?\(param)")!

        let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
            if data != nil {
                log("Got data at \(Date())")
            }
            else {
                print("No data.  Webserver not running?")
                return
            }
        }

        task.resume()
    }
}

func log(_ value: Any) {
    if LOGGING_ENABLED {
        NSLog("BGMOTION: \(value)")
    }
}

// Simple global main/bg thread block execution
// https://www.electrollama.net/blog/2017/1/6/updating-ui-from-background-threads-simple-threading-in-swift-3-for-ios
func BG(_ block: @escaping ()->Void) {
    DispatchQueue.global(qos: .default).async(execute: block)
}

func UI(_ block: @escaping ()->Void) {
    DispatchQueue.main.async(execute: block)
}

// Global access to the app delegate, for convenience.  Could be any root controller.
func appDelegate() -> AppDelegate {
    return UIApplication.shared.delegate as! AppDelegate
}

/**
 * APP DELEGATE
 */

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    let locationManager = CLLocationManager()
    let motionManager = CMMotionManager()
    let motionActivityManager = CMMotionActivityManager()
    let altimeter = CMAltimeter()
    var activityUIDelegate: ActivityUIDelegate?
    var beaconConstraints = [CLBeaconIdentityConstraint: [CLBeacon]]()
    var beaconRegions = [CLBeaconRegion]()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        stopUpdates()
        
        setupLocationManager()
        setupMotionManager(updateInterval: UPDATE_INTERVAL)
        setupBeacons()
        // Other sensor types are not configurable

        // A notification-based alternative to the usual will/did app/scene delegate methods
        setupLifecycleNotifications()
        
        startUpdates()
        
        requestURL("DID_FINISH_LAUNCHING")
        
        return true
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    private func setupLocationManager() {
        locationManager.requestAlwaysAuthorization()

        // Disable this next line to turn off ALL background location/motion updates.
        locationManager.allowsBackgroundLocationUpdates = BACKGROUND_UPDATES
        
        // Crank down the GPS accuracy to prevent (frequent) location updates
        // Disable the next two lines to see location updates.
        // GPS energy usage is visible in the Energy Log Instrument
        // https://stackoverflow.com/a/19085518/2431627
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager.distanceFilter = 99999
        locationManager.delegate = self
    }
    
    private func setupMotionManager(updateInterval: Double) {
        updateMotionInterval(updateInterval)
    }
    
    private func setupBeacons() {
        for beaconID in BEACON_IDS {
            if let uuid = UUID(uuidString: beaconID) {
                let constraint = CLBeaconIdentityConstraint(uuid: uuid)
                self.beaconConstraints[constraint] = []
                let beaconRegion = CLBeaconRegion(
                    beaconIdentityConstraint: constraint,
                    identifier: uuid.uuidString)
                beaconRegions.append(beaconRegion)
            }
        }
    }
    
    func stopUpdates() {
        locationManager.stopUpdatingLocation()
        altimeter.stopRelativeAltitudeUpdates()
        motionManager.stopGyroUpdates()
        motionManager.stopMagnetometerUpdates()
        motionManager.stopAccelerometerUpdates()
        motionManager.stopDeviceMotionUpdates()
        motionActivityManager.stopActivityUpdates()
        
        for region in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }
        
        for constraint in beaconConstraints.keys {
            locationManager.stopRangingBeacons(satisfying: constraint)
        }
        
        requestURL("LOCATION_UPDATES_STOPPED")
    }
    
    func startUpdates() {
        stopUpdates() // Ensure we don't register twice
        startLocationUpdates()
        startAltimeterUpdates()
        startMotionUpdates()
        startActivityUpdates()
        startBeaconUpdates()
    }
    
    private func startLocationUpdates() {
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    }
    
    private func startAltimeterUpdates() {
        if CMAltimeter.isRelativeAltitudeAvailable() {
            altimeter.startRelativeAltitudeUpdates(to: OperationQueue.main) { (data, error) in
                log(data as Any)
                requestURL("altimeter&altitude=\(data?.relativeAltitude ?? 0)&pressure=\(data?.pressure ?? 0)")
                self.playSound()
            }
        }
    }
    
    private func startMotionUpdates() {
        if motionManager.isAccelerometerAvailable {
            requestURL("STARTING_ACCEL")
            motionManager.startAccelerometerUpdates(to: OperationQueue.main) { (data, error) in
                log(data as Any)
                requestURL("accel")
                self.playSound()
            }
        }

        if motionManager.isMagnetometerAvailable {
            requestURL("STARTING_MAG")
            motionManager.startMagnetometerUpdates(to: OperationQueue.main) { (data, error) in
                log(data as Any)
                requestURL("mag")
                self.playSound()
            }
        }
        
        if motionManager.isGyroAvailable {
            requestURL("STARTING_GYRO")
            motionManager.startGyroUpdates(to: OperationQueue.main) { (data, error) in
                log(data as Any)
                requestURL("gyro")
                self.playSound()
            }
        }
        
        if motionManager.isDeviceMotionAvailable {
            requestURL("STARTING_DEVICE")
            motionManager.startDeviceMotionUpdates(to: OperationQueue.main) { (data, error) in
                log(data as Any)
                requestURL("device")
                self.playSound()
            }
        }
    }
    
    private func startActivityUpdates() {
        if  CMMotionActivityManager.isActivityAvailable() {
            self.motionActivityManager.startActivityUpdates(to: OperationQueue.main) { (motion) in
                if motion != nil {
                    // It's possible to have > 1 value, e.g. automotive AND stationary (e.g. at lights)
                    var activities = [
                        motion!.unknown ? "unknown" : nil,
                        motion!.stationary ? "stationary" : nil,
                        motion!.walking ? "walking" : nil,
                        motion!.running ? "running" : nil,
                        motion!.cycling ? "cycling" : nil,
                        motion!.automotive ? "driving" : nil
                    ].compactMap({$0}).joined(separator: ",")
                    
                    // It's also possible that the phone can't determine what you're doing, e.g. maybe
                    // just picking the phone up.
                    if activities == "" {
                        activities = "none"
                    }
                                        
                    let confidence =
                        (motion!.confidence == .low ? "low" :
                        motion!.confidence == .medium ? "medium" :
                        motion!.confidence == .high ? "high" :
                        "unknown")
                    
                    self.activityUIDelegate?.updateActivityUI(msg: activities.capitalized)
                    
                    requestURL("activities=\(activities)&confidence=\(confidence)")
                }
            }
        }
    }
    
    private func startBeaconUpdates() {
        for beaconRegion in beaconRegions {
            self.locationManager.startMonitoring(for: beaconRegion)
            requestURL("MONITORING_BEACON=\(beaconRegion.beaconIdentityConstraint.uuid.uuidString)")
        }
    }
    
    // Add listeners for lifecycle notifications.
    // In a normal app these would typically be in scene or app delegate lifecycle methods, e.g. sceneDidBecomeActive()
    // Doing it like this shows how it could work for a third-party library.
    private func setupLifecycleNotifications() {
        
        let notificationCenter = NotificationCenter.default
        
        notificationCenter.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil)

        notificationCenter.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil)

        notificationCenter.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil)
        
        notificationCenter.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil)
    }
    
    private func playSound() {
        if PLAY_SOUND {
            AudioServicesPlaySystemSound(1103)
        }
    }
    
    // We can change the update intervals on-the-fly
    func updateMotionInterval(_ interval: Double) {
        requestURL("updateInterval=\(interval)")
        motionManager.gyroUpdateInterval = interval
        motionManager.accelerometerUpdateInterval = interval
        motionManager.deviceMotionUpdateInterval = interval
        motionManager.magnetometerUpdateInterval = interval
        activityUIDelegate?.updateIntervalUI(interval: interval)
    }
    
    /**
     * NOTIFICATION HANDLERS
     */
    
    @objc private func appWillEnterForeground() {
        requestURL("WILL_ENTER_FOREGROUND")
    }
    
    @objc private func appDidEnterBackground() {
        requestURL("DID_ENTER_BACKGROUND")
    }
    
    @objc private func appWillResignActive() {
        appDelegate().updateMotionInterval(10)
        requestURL("RESIGN_ACTIVE")
    }
    
    @objc private func appDidBecomeActive() {
        requestURL("DID_BECOME_ACTIVE")
    }
}

// MARK: - Location Lifecycle

extension AppDelegate: CLLocationManagerDelegate {
    func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
        requestURL("DidPauseLocationUpdates")
    }
    
    func locationManagerDidResumeLocationUpdates(_ manager: CLLocationManager) {
        requestURL("DidResumeLocationUpdates")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        requestURL("didUpdateLocations")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        requestURL("didFail: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        requestURL("didUpdateHeading")
    }
    
    // Beacon ranging
    
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        let beaconRegion = region as? CLBeaconRegion
        if state == .inside {
            // Start ranging when inside a region.
            manager.startRangingBeacons(satisfying: beaconRegion!.beaconIdentityConstraint)
        } else {
            // Stop ranging when not inside a region.
            manager.stopRangingBeacons(satisfying: beaconRegion!.beaconIdentityConstraint)
        }
    }
    
    func locationManager(
        _ manager: CLLocationManager,
        didRange beacons: [CLBeacon],
        satisfying beaconConstraint: CLBeaconIdentityConstraint)
    {
        for beacon in beacons {
            let proximity =
                beacon.proximity == CLProximity.unknown ? "unknown" :
                beacon.proximity == CLProximity.immediate ? "immediate" :
                beacon.proximity == CLProximity.near ? "near" :
                beacon.proximity == CLProximity.far ? "far" :
                "none"
            requestURL("didRangeBeacon=\(beacon.uuid.uuidString)&range=\(proximity)")
        }
    }
}
