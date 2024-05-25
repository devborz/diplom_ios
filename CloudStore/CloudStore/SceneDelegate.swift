//
//  SceneDelegate.swift
//  CloudStore
//
//  Created by Усман Туркаев on 31.03.2023.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let scene = (scene as? UIWindowScene) else { return }
        let window = UIWindow(windowScene: scene)
        let vc: UIViewController
        if let sessionData = AuthService.getSessionData() {
            vc = TabBarController(sessionData: sessionData)
            window.rootViewController = vc
        } else {
            vc = AuthViewController()
            let nav = UINavigationController(rootViewController: vc)
            window.rootViewController = nav
        }
        self.window = window
        window.makeKeyAndVisible()
    }

}

