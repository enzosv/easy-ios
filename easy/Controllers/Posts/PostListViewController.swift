//
//  PostListViewController.swift
//  easy
//
//  Created by Lorenzo Rey Vergara on Jul 13, 2018.
//  Copyright © 2018 enzosv. All rights reserved.
//

import UIKit

class PostListViewController: UIViewController {

	private let navBar: UINavigationBar = {
		let firstItem = UINavigationItem(title: "Posts")
		let bar = UINavigationBar(frame: .zero)
		bar.pushItem(firstItem, animated: false)
		bar.barTintColor = Constants.Colors.DARK
		bar.titleTextAttributes = [.foregroundColor: Constants.Colors.Text.TITLE]
		bar.isTranslucent = false
		return bar
	}()

	let table: UITableView = {
		let table = UITableView()
		table.tableFooterView = UIView()
		table.backgroundColor = Constants.Colors.DARK
		table.separatorColor = Constants.Colors.DARK
		table.separatorInset = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
		return table
	}()

	private let searchFieldContainer: UIView = {
		let view = UIView()
		view.backgroundColor = Constants.Colors.DARK
		view.clipsToBounds = true
		return view
	}()

	let searchField: UITextField = {
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

	private let listSwitcher: UISegmentedControl = {
		let segment = UISegmentedControl()
		segment.backgroundColor = .black
		segment.tintColor = Constants.Colors.Text.SUBTITLE
		return segment
	}()

	let sortButton: UIBarButtonItem = {
		let button = UIBarButtonItem()
		button.style = .plain
		button.tintColor = Constants.Colors.Text.TITLE
		return button
	}()

	private var reviewView: PostReviewView?

	lazy var logicController: PostListLogicController
		= PostListLogicController(controller: self)

	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
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
		logicController.setupPosts(sortType: PostListLogicController.DEFAULTSORT)
		logicController.setupTable(table)
		logicController.setupSearch(field: searchField)
		logicController.setupListSwitcher(listSwitcher)
		logicController.setupSortButton(sortButton)
		setup()
	}

	override func viewSafeAreaInsetsDidChange() {
		remakeLayout()
	}

	private func setup() {
		searchFieldContainer.addSubview(listSwitcher)
		searchFieldContainer.addSubview(searchField)
		table.tableHeaderView = searchFieldContainer
		view.backgroundColor = Constants.Colors.DARK
		view.addSubview(navBar)
		view.addSubview(table)

		navBar.topItem?.rightBarButtonItem = sortButton

	}

	private func remakeLayout() {
		navBar.snp.remakeConstraints { make in
			make.top.left.right.equalTo(view.safeAreaInsets)
		}

		searchFieldContainer.snp.remakeConstraints { make in
			make.top.left.right.width.equalToSuperview()
		}

		searchField.snp.remakeConstraints { (make) in
			make.top.equalToSuperview()
			make.left.right.equalToSuperview().inset(8)
		}

		listSwitcher.snp.remakeConstraints { make in
			make.top.equalTo(searchField.snp.bottom).offset(8).priority(.medium)
			make.centerX.equalToSuperview()
			make.bottom.equalToSuperview().inset(8)
		}
		table.snp.remakeConstraints { (make) in
			make.top.equalTo(navBar.snp.bottom)
			make.left.right.bottom.equalToSuperview().inset(view.safeAreaInsets)
		}
	}

	func showReview(for post: Post) {
		let reviewView = PostReviewView(post: post)
		view.addSubview(reviewView)

		reviewView.snp.remakeConstraints { make in
			make.top.equalTo(view.snp.bottom)
				.offset(view.safeAreaInsets.bottom)
			make.centerX.equalToSuperview()
			make.width.equalToSuperview().inset(32)
		}
		reviewView.superview?.layoutIfNeeded()
		reviewView.remakeLayout()
		reviewView.snp.remakeConstraints { make in
			make.bottom.equalToSuperview().inset(view.safeAreaInsets.bottom+20)
			make.centerX.equalToSuperview()
			make.width.equalToSuperview().inset(32)
		}
		reviewView.layoutIfNeeded()
		UIView.animate(withDuration: 0.3, animations: {
			reviewView.superview?.layoutIfNeeded()
		}, completion: { _ in
			self.reviewView = reviewView
		})
	}

	func hideReview() {
		guard let reviewView = reviewView else {
			return
		}
		reviewView.remove(animated: true) { _ in
			self.reviewView = nil
		}
	}

}
