//
//  AppDelegate.swift
//  LMBackground3
//
//  Created by Robin Macharg2 on 04/01/2021.
//

import UIKit
import CoreLocation

/*

 Usage:
 
 Add "Background Modes" capability with Location Updates (and Background Fetch to see
 local HTTP requests that prove the app is runnning)
 
 Add the following keys to the Info.plist with suitable descriptions:
 
     Privacy - Location Always and When in Use Usage Description
     Privacy - Location When in Use Usage Description
     Privacy - Motion Usage Description

 Start a simple webserver with (Python 2):

    $ python -m SimpleHTTPServer 8000

 Enable requests by toggling REQUESTS_ENABLED, below.  Change the IP to your development machine's.
 
 */

let REQUESTS_ENABLED = true
let LOCAL_IP = "192.168.1.123"
 
// Helper function to issue a simple HTTP request.
// Allows validation of functionality when not connected to a debugger.
func requestURL(_ arg: String) {
    if REQUESTS_ENABLED {
        let param = arg.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let url = URL(string: "http://\(LOCAL_IP):8000/?\(param)")!

        let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
            if data != nil {
                print("Got data at \(Date())")
            }
            else {
                print("No data.  Webserver not running?")
                return
            }
        }

        task.resume()
    }
}

// https://www.electrollama.net/blog/2017/1/6/updating-ui-from-background-threads-simple-threading-in-swift-3-for-ios
func BG(_ block: @escaping ()->Void) {
    DispatchQueue.global(qos: .default).async(execute: block)
}

func UI(_ block: @escaping ()->Void) {
    DispatchQueue.main.async(execute: block)
}

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    let locationManager = CLLocationManager()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        locationManager.requestAlwaysAuthorization()
        // Disable this next line to turn off ALL background location/motion updates.
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.startUpdatingLocation()
        
        requestURL("DID_FINISH_LAUNCHING")
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}
