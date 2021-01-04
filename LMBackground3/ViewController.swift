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
     
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // That warm feeling
        label.text = "Running"
        
        motionManager.gyroUpdateInterval = 1.0
        motionManager.accelerometerUpdateInterval = 1.0
        motionManager.deviceMotionUpdateInterval = 1.0
        motionManager.magnetometerUpdateInterval = 1.0
        
        motionManager.startAccelerometerUpdates(to: OperationQueue.main) { (data, error) in
            print(data)
            requestURL("accel")
            AudioServicesPlaySystemSound(1103)
        }
        
        motionManager.startMagnetometerUpdates(to: OperationQueue.main) { (data, error) in
            print(data)
            requestURL("mag")
            AudioServicesPlaySystemSound(1103)
        }
        
        motionManager.startGyroUpdates(to: OperationQueue.main) { (data, error) in
            print(data)
            requestURL("gyro")
            AudioServicesPlaySystemSound(1103)
        }
        
        motionManager.startDeviceMotionUpdates(to: OperationQueue.main) { (data, error) in
            print(data)
            requestURL("device")
            AudioServicesPlaySystemSound(1103)
        }
    }
}

