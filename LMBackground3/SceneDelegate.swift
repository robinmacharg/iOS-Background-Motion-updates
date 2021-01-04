//
//  SceneDelegate.swift
//  LMBackground3
//
//  Created by Robin Macharg2 on 04/01/2021.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let _ = (scene as? UIWindowScene) else { return }
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        requestURL("DID_BECOME_ACTIVE")
    }

    func sceneWillResignActive(_ scene: UIScene) {
        requestURL("RESIGN_ACTIVE")
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        requestURL("WILL_ENTER_FOREGROUND")
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        requestURL("DID_ENTER_BACKGROUND")
    }
}

