//
//  TabBarController.swift
//  CloudStore
//
//  Created by Усман Туркаев on 21.05.2024.
//

import UIKit

final class TabBarController: UITabBarController {

    let sessionData: SessionData
    
    init(sessionData: SessionData) {
        self.sessionData = sessionData
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var cloudItem: UITabBarItem = {
        let item = UITabBarItem(title: "Cloud", image: UIImage(systemName: "cloud"), tag: 0)
        return item
    }()
    
    lazy var sharedItem: UITabBarItem = {
        let item = UITabBarItem(title: "Shared", image: UIImage(systemName: "link.icloud"), tag: 1)
        return item
    }()
    
    lazy var cloudController: UINavigationController = {
        let vc = CloudViewController(sessionData: self.sessionData, ownerID: self.sessionData.uid)
        let navController = UINavigationController(rootViewController: vc)
        navController.tabBarItem = self.cloudItem
        return navController
    }()
    lazy var sharedController: UINavigationController = {
        let vc = CloudViewController(sessionData: self.sessionData, ownerID: self.sessionData.uid, kind: .shared)
        let navController = UINavigationController(rootViewController: vc)
        navController.tabBarItem = self.sharedItem
        return navController
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.viewControllers = [self.cloudController, self.sharedController]
    }

}
