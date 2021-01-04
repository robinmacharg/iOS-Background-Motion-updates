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
        
        if motionManager.isAccelerometerActive {
            requestURL("STARTING_ACCEL")
            motionManager.startAccelerometerUpdates(to: OperationQueue.main) { (data, error) in
                print(data)
                requestURL("accel")
                AudioServicesPlaySystemSound(1103)
            }
        }

        if motionManager.isMagnetometerActive {
            motionManager.startMagnetometerUpdates(to: OperationQueue.main) { (data, error) in
                print(data)
                requestURL("mag")
                AudioServicesPlaySystemSound(1103)
            }
        }
        
        if motionManager.isGyroAvailable {
            motionManager.startGyroUpdates(to: OperationQueue.main) { (data, error) in
                print(data)
                requestURL("gyro")
                AudioServicesPlaySystemSound(1103)
            }
        }
        
        if motionManager.isDeviceMotionAvailable {
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
                    var activities = "motion=" + [
                        motion!.unknown ? "unknown" : nil,
                        motion!.stationary ? "stationary" : nil,
                        motion!.walking ? "walking" : nil,
                        motion!.running ? "running" : nil,
                        motion!.cycling ? "cycling" : nil,
                        motion!.automotive ? "driving" : nil
                    ].compactMap({$0}).joined(separator: ",")
                    
                    var confidence = "confidence=" +
                        (motion!.confidence == .low ? "low" :
                        motion!.confidence == .medium ? "medium" :
                        motion!.confidence == .high ? "high" :
                        "unknown")
                    
                    requestURL("\(activities)&\(confidence)")
                }
            }
        }
        
    }
}

