//
//  ViewController.swift
//  LMBackground3
//
//  Created by Robin Macharg2 on 04/01/2021.
//

import UIKit
import CoreMotion
import FLEX

class ViewController: UIViewController {

    @IBOutlet weak var label: UILabel!

    let motionActivityManager = CMMotionActivityManager()
     
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // That warm feeling
        label.text = "App Running"
        
        // Activity
        
        if  CMMotionActivityManager.isActivityAvailable() {
            appDelegate().motionActivityManager.startActivityUpdates(to: OperationQueue.main) { (motion) in
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
                    
                    if activities == "" {
                        activities = "none"
                    }
                                        
                    let confidence =
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
    
    // Start the FLEX in-app debugger
    // Note: Disable os_log in FLEX's System Log Settings and filter on BGMOTION for a saner experience
    @IBAction func startFLEX(_ sender: Any) {
        FLEXManager.shared.showExplorer()
    }
    
    // Lazy UI
    @IBAction func changeInterval1s(_ sender: Any) {
        appDelegate().updateMotionInterval(1)
    }
    
    @IBAction func changeInterval5s(_ sender: Any) {
        appDelegate().updateMotionInterval(5)
    }
    
    @IBAction func changeInterval10s(_ sender: Any) {
        appDelegate().updateMotionInterval(10)
    }
}

