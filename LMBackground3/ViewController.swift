//
//  ViewController.swift
//  LMBackground3
//
//  Created by Robin Macharg2 on 04/01/2021.
//

import UIKit
import CoreMotion
import FLEX

// Functions to let the user know what's going on.
protocol ActivityUIDelegate {
    func updateActivityUI(msg: String)
    func updateIntervalUI(interval: Double)
}

class ViewController: UIViewController {

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var updateIntervalLabel: UILabel!
    
    let motionActivityManager = CMMotionActivityManager()
     
    override func viewDidLoad() {
        super.viewDidLoad()
        appDelegate().activityUIDelegate = self
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
    
    @IBAction func startLocationUpdates(_ sender: Any) {
        appDelegate().startUpdates()
    }
    
    @IBAction func stopLocationUpdates(_ sender: Any) {
        appDelegate().stopUpdates()
    }
}

// MARK: - <ActivityUIDelegate>

extension ViewController: ActivityUIDelegate {
    func updateActivityUI(msg: String) {
        UI() {
            self.label.text = msg.capitalized
        }
    }
    
    func updateIntervalUI(interval: Double) {
        UI() {
            self.updateIntervalLabel.text = "Update Interval: \(interval)"
        }
    }
}

