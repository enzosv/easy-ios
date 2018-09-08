//
//  FilterRootViewController.swift
//  easy
//
//  Created by Lorenzo Rey Vergara on Jul 14, 2018.
//  Copyright © 2018 enzosv. All rights reserved.
//

import UIKit

class FilterRootViewController: UINavigationController {

	private let postListInputs: PostListLogicController
	init(postListInputs: PostListLogicController) {
		self.postListInputs = postListInputs
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

    override func viewDidLoad() {
        super.viewDidLoad()
		navigationBar.titleTextAttributes = [.foregroundColor: Constants.Colors.Text.TITLE]
		navigationBar.tintColor = Constants.Colors.Text.SUBTITLE
		navigationBar.barTintColor = Constants.Colors.DARK
		navigationBar.isTranslucent = false
        viewControllers = [FilterListViewController(postListInputs: postListInputs)]
    }

}
