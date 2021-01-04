//
//  ViewController.swift
//  LMBackground3
//
//  Created by Robin Macharg2 on 04/01/2021.
//

import UIKit
import CoreMotion
import AVKit

class ViewController: UIViewController {

    @IBOutlet weak var label: UILabel!
    
    let motionManager = CMMotionManager()
    let motionActivityManager = CMMotionActivityManager()
    
     
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // That warm feeling
        label.text = "Running"
        
        motionManager.gyroUpdateInterval = 1.0
        motionManager.accelerometerUpdateInterval = 1.0
        motionManager.deviceMotionUpdateInterval = 1.0
        motionManager.magnetometerUpdateInterval = 1.0
        
        // Basic CoreMotion
        
        if motionManager.isAccelerometerAvailable {
            requestURL("STARTING_ACCEL")
            motionManager.startAccelerometerUpdates(to: OperationQueue.main) { (data, error) in
                print(data)
                requestURL("accel")
                AudioServicesPlaySystemSound(1103)
            }
        }

        if motionManager.isMagnetometerAvailable {
            requestURL("STARTING_MAG")
            motionManager.startMagnetometerUpdates(to: OperationQueue.main) { (data, error) in
                print(data)
                requestURL("mag")
                AudioServicesPlaySystemSound(1103)
            }
        }
        
        if motionManager.isGyroAvailable {
            requestURL("STARTING_GYRO")
            motionManager.startGyroUpdates(to: OperationQueue.main) { (data, error) in
                print(data)
                requestURL("gyro")
                AudioServicesPlaySystemSound(1103)
            }
        }
        
        if motionManager.isDeviceMotionAvailable {
            requestURL("STARTING_DEVICE")
            motionManager.startDeviceMotionUpdates(to: OperationQueue.main) { (data, error) in
                print(data)
                requestURL("device")
                AudioServicesPlaySystemSound(1103)
            }
        }
        
        // Activity
        
        if CMMotionActivityManager.isActivityAvailable() {
            self.motionActivityManager.startActivityUpdates(to: OperationQueue.main) { (motion) in
                if motion != nil {
                    var activities = [
                        motion!.unknown ? "unknown" : nil,
                        motion!.stationary ? "stationary" : nil,
                        motion!.walking ? "walking" : nil,
                        motion!.running ? "running" : nil,
                        motion!.cycling ? "cycling" : nil,
                        motion!.automotive ? "driving" : nil
                    ].compactMap({$0}).joined(separator: ",")
                    
                    if activities == "" {
                        activities = "none"
                    }
                                        
                    var confidence =
                        (motion!.confidence == .low ? "low" :
                        motion!.confidence == .medium ? "medium" :
                        motion!.confidence == .high ? "high" :
                        "unknown")
                    
                    
                    UI() {
                        self.label.text = activities.capitalized
                    }
                    
                    requestURL("activities=\(activities)&confidence=\(confidence)")
                }
            }
        }
        
    }
}

