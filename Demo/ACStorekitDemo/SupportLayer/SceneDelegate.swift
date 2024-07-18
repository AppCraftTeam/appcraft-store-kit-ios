//
//  SceneDelegate.swift
//  ACStorekitDemo
//
//  Created by Pavel Moslienko on 18.07.2024.
//

import UIKit

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    // MARK: - Props
    var window: UIWindow?
    
    // MARK: - Methods
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        self.window = UIWindow(windowScene: windowScene)

        let vc = SubscriptionsViewController()
        window?.rootViewController = UINavigationController(rootViewController: vc)
        window?.makeKeyAndVisible()
    }
}
