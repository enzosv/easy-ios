//
//  HistoryViewController.swift
//  easy
//
//  Created by Lorenzo Rey Vergara on Jul 15, 2018.
//  Copyright © 2018 enzosv. All rights reserved.
//

import UIKit
import RealmSwift
import SwiftyUserDefaults

private let reuseIdentifier = "postCell"

enum HistorySortType: Int {
	case byDateReadDescending = 0
	case byUpvoteCountDescending = 1

	var buttonTitle: String? {
		switch self {
		case .byDateReadDescending:
			return "Date ▼"
		case .byUpvoteCountDescending:
			return "Upvotes ▼"
		}
	}
}

class HistoryViewController: UIViewController, PostOptionsPresenter {

	var onPresentRequest: ((UIViewController) -> Void)?
	private let statusBG: UIView = {
		let view = UIView()
		view.backgroundColor = Constants.Colors.DARK
		return view
	}()
	private let navBar: UINavigationBar = {
		let firstItem = UINavigationItem(title: "History")
		let bar = UINavigationBar(frame: .zero)
		bar.pushItem(firstItem, animated: false)
		bar.barTintColor = Constants.Colors.DARK
		bar.titleTextAttributes = [.foregroundColor: Constants.Colors.Text.TITLE]
		bar.isTranslucent = false
		return bar
	}()

	private let table: UITableView = {
		let table = UITableView()
		table.tableFooterView = UIView()
		table.backgroundColor = .black
		table.separatorColor = Constants.Colors.DARK
		table.separatorInset = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
		return table
	}()

	private var readPosts = Post.read
	private var notificationToken: NotificationToken?

	deinit {
		notificationToken?.invalidate()
		preconditionFailure("main view controller should never deinit")
	}

	init() {
		super.init(nibName: nil, bundle: nil)
		onPresentRequest = { [unowned self] controller in
			self.present(controller, animated: true, completion: nil)
		}
		setupActions()
		setupTable()
		setupPosts()
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

    override func viewDidLoad() {
        super.viewDidLoad()
		setupView()
		remakeLayout()
    }

	override func viewSafeAreaInsetsDidChange() {
		super.viewSafeAreaInsetsDidChange()
		statusBG.snp.updateConstraints { make in
			make.height.equalTo(view.safeAreaInsets.top)
		}
		table.snp.updateConstraints { make in
			make.left.right.bottom.equalToSuperview().inset(view.safeAreaInsets)
		}
	}

	private func setupView() {
		view.backgroundColor = .black
		view.addSubview(statusBG)
		view.addSubview(navBar)
		view.addSubview(table)
	}

	private func remakeLayout() {
		let defaultNavHeight: CGFloat = {
			let nav = UINavigationController()
			return nav.navigationBar.frame.size.height
		}()
		statusBG.snp.remakeConstraints { make in
			make.top.left.right.equalToSuperview()
			make.height.equalTo(view.safeAreaInsets.top)
		}
		navBar.snp.remakeConstraints { make in
			make.top.equalTo(statusBG.snp.bottom)
			make.left.right.equalToSuperview()
			make.height.equalTo(defaultNavHeight)
		}
		table.snp.remakeConstraints { (make) in
			make.top.equalTo(navBar.snp.bottom)
			make.left.right.bottom.equalToSuperview().inset(view.safeAreaInsets)
		}
	}

	private func setupTable() {
		table.register(ReadPostTableViewCell.self, forCellReuseIdentifier: reuseIdentifier)
		table.dataSource = self
		table.delegate = self
	}

	private func setupPosts() {
		readPosts = Post.read
		notificationToken = readPosts.observe({ [weak self] changes in
			guard let strongSelf = self else {
				return
			}
			let table = strongSelf.table
			switch changes {
			case .initial:
				table.reloadData()
			case .update(_, let deletions, let insertions, let modifications):
				table.beginUpdates()
				table.insertRows(at: insertions.map({ IndexPath(row: $0, section: 0) }),
								 with: .automatic)
				table.deleteRows(at: deletions.map({ IndexPath(row: $0, section: 0)}),
								 with: .automatic)
				table.reloadRows(at: modifications.map({ IndexPath(row: $0, section: 0) }),
								 with: .automatic)
				table.endUpdates()
			case .error(let error):
				assertionFailure(error.localizedDescription)
			}
		})
		table.reloadData()
	}

	private func setupActions() {
		let currentSort = HistorySortType(rawValue: Defaults[.historySortType]) ?? .byDateReadDescending
		let button = UIBarButtonItem(
			title: currentSort.buttonTitle,
			style: .plain,
			target: self,
			action: #selector(sortByAction(sender:)))
		button.tintColor = Constants.Colors.Text.TITLE
		navBar.topItem?.rightBarButtonItem = button
	}

	@objc private func sortByAction(sender: UIBarButtonItem) {
		let newSort: HistorySortType = {
			if HistorySortType(rawValue: Defaults[.historySortType]) == .byDateReadDescending {
				return HistorySortType.byUpvoteCountDescending
			} else {
				return HistorySortType.byDateReadDescending
			}
		}()
		Defaults[.historySortType] = newSort.rawValue
		sender.title = newSort.buttonTitle
		setupPosts()
	}

}

extension HistoryViewController: UITableViewDataSource {
	func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return readPosts.count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as? ReadPostTableViewCell else {
			assertionFailure("register PostTableViewCell with reuseIdentifier: \(reuseIdentifier) first")
			return UITableViewCell()
		}
		guard let post = readPosts[safe: indexPath.row] else {
			assertionFailure("\(indexPath.row) out of bounds. \(readPosts.count) total")
			return UITableViewCell()
		}
		cell.configure(with: post, onOptionsClick: { [unowned self] selectedPost in
			self.showOptions(for: selectedPost)
		})
		return cell
	}
}

extension HistoryViewController: UITableViewDelegate {

	func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
		return 128
	}

	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return UITableViewAutomaticDimension
	}

	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		guard let post = readPosts[safe: indexPath.row],
			let url = URL(string: "https://medium.com/posts/\(post.postId)"),
			UIApplication.shared.canOpenURL(url) else {
				return
		}
		UIApplication.shared.open(url, options: [:], completionHandler: nil)
	}

}
