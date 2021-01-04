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
 
 */

/**
 * CONSTANTS
 */

// Should we send diagnostic HTTP requests?
let REQUESTS_ENABLED = true

// The webserver address
let LOCAL_IP = "192.168.1.123"

// Whether to print diagnostic messages to the console.
let LOGGING_ENABLED = true

// How frequently to update location/motion in seconds
let UPDATE_INTERVAL = 10.0
 
// Should we play a sound when a background motion event is received?
let PLAY_SOUND = true

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

// https://www.electrollama.net/blog/2017/1/6/updating-ui-from-background-threads-simple-threading-in-swift-3-for-ios
func BG(_ block: @escaping ()->Void) {
    DispatchQueue.global(qos: .default).async(execute: block)
}

func UI(_ block: @escaping ()->Void) {
    DispatchQueue.main.async(execute: block)
}

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
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        setupLocationManager()
        setupMotionManager(updateInterval: UPDATE_INTERVAL)
        
        requestURL("DID_FINISH_LAUNCHING")
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    private func setupLocationManager() {
        locationManager.requestAlwaysAuthorization()

        // Disable this next line to turn off ALL background location/motion updates.
        locationManager.allowsBackgroundLocationUpdates = true

        // Crank down the GPS accuracy to prevent (frequent) location updates
        // Disable the next two lines to see location updates.
        // GPS energy usage is visible in the Energy Log instrument
        // https://stackoverflow.com/a/19085518/2431627
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager.distanceFilter = 99999
        
        locationManager.startUpdatingLocation()
        locationManager.delegate = self
    }
    
    private func setupMotionManager(updateInterval: Double) {
        motionManager.stopGyroUpdates()
        motionManager.stopMagnetometerUpdates()
        motionManager.stopAccelerometerUpdates()
        motionManager.stopDeviceMotionUpdates()
        
        updateMotionInterval(updateInterval)
        
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
    
    private func playSound() {
        if PLAY_SOUND {
            AudioServicesPlaySystemSound(1103)
        }
    }
    
    func updateMotionInterval(_ interval: Double) {
        requestURL("updateInterval=\(interval)")
        motionManager.gyroUpdateInterval = interval
        motionManager.accelerometerUpdateInterval = interval
        motionManager.deviceMotionUpdateInterval = interval
        motionManager.magnetometerUpdateInterval = interval
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
}
