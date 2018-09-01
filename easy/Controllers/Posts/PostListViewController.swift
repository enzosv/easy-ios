//
//  PostListViewController.swift
//  easy
//
//  Created by Lorenzo Rey Vergara on Jul 13, 2018.
//  Copyright © 2018 enzosv. All rights reserved.
//

import UIKit
import RealmSwift

class PostListViewController: UIViewController {

	private let table: UITableView = {
		let table = UITableView()
		table.tableFooterView = UIView()
		table.backgroundColor = .black
		table.separatorColor = Constants.Colors.DARK
		table.separatorInset = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
		return table
	}()

	private let searchFieldContainer: UIView = {
		let view = UIView()
		view.backgroundColor = Constants.Colors.DARK
		return view
	}()

	private let searchField: UITextField = {
		let field = UITextField()
		field.borderStyle = .roundedRect
		field.tintColor = Constants.Colors.Text.TITLE
		field.attributedPlaceholder = NSAttributedString(
			string: "Search Medium",
			attributes: [.foregroundColor: Constants.Colors.Text.SUBTITLE])
		field.textColor = field.tintColor
		field.backgroundColor = .black

		field.autocorrectionType = .no
		field.autocapitalizationType = .sentences
		field.clearButtonMode = .always

		return field
	}()

	let logicController: PostListLogicController

	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
		logicController = PostListLogicController(with: table, searchField: searchField)
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
		logicController.onPresentRequest = { [unowned self] controller in
			self.present(controller, animated: true, completion: nil)
		}
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		logicController.setupPosts()
		setup()
	}

	override func viewSafeAreaInsetsDidChange() {
		remakeLayout()
	}

	private func setup() {
		searchFieldContainer.addSubview(searchField)

		view.backgroundColor = .black
		view.addSubview(searchFieldContainer)
		view.addSubview(table)
	}

	private func remakeLayout() {
		searchField.snp.remakeConstraints { (make) in
			make.top.equalToSuperview().inset(view.safeAreaInsets.top+4)
			make.bottom.equalToSuperview().inset(8)
			make.left.right.equalToSuperview().inset(8)
			make.height.equalTo(44)
		}
		searchFieldContainer.snp.remakeConstraints { make in
			make.top.left.right.equalToSuperview()
		}
		table.snp.remakeConstraints { (make) in
			make.top.equalTo(searchFieldContainer.snp.bottom)
			make.left.right.bottom.equalToSuperview().inset(view.safeAreaInsets)
		}
	}
}
