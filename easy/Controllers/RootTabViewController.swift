//
//  RootTabViewController.swift
//  easy
//
//  Created by Lorenzo Rey Vergara on Jul 13, 2018.
//  Copyright © 2018 enzosv. All rights reserved.
//

import UIKit
import SnapKit

class RootTabViewController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

		let postsTab: PostListViewController = {
			let controller = PostListViewController()
			controller.tabBarItem = UITabBarItem(title: "Posts", image: nil, selectedImage: nil)
			return controller
		}()

		let filterTab: UIViewController = {
			let controller = FilterRootViewController(postListInputs: postsTab.logicController)
			controller.tabBarItem = UITabBarItem(title: "Filters", image: nil, selectedImage: nil)
			return controller
		}()

		viewControllers = [postsTab, filterTab]
		tabBar.barTintColor = Constants.Colors.DARK
		tabBar.tintColor = Constants.Colors.Text.TITLE
    }

}
