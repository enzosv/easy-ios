//
//  PostListLogicController.swift
//  easy
//
//  Created by Lorenzo Rey Vergara on Jul 14, 2018.
//  Copyright © 2018 enzosv. All rights reserved.
//

import RealmSwift
import SwiftyUserDefaults
import ESPullToRefresh
import Foundation
import UIKit

private let reuseIdentifier = "postCell"
private let readIdentifier = "readPostCell"

class PostListLogicController: NSObject, PostOptionsPresenter {

	static let DEFAULTSORT: ListSortType = .byClapCountPerDayDescending(NSPredicate(format: "dateRead == nil"))
	private var posts: [Results<Post>]!
	private var notificationTokens: [NotificationToken?] = []
	var onPresentRequest: ((UIViewController) -> Void)?

	private let viewController: PostListViewController
	private var searchQuery: String?
	private lazy var searchService = MediumService()
	private lazy var debouncedSearch: Debouncer = Debouncer(delay: 0.4) {
		guard let query = self.searchQuery?.trimmingCharacters(in: .whitespaces),
			query.count > 0 else {
				return
		}
		self.searchService.requestResource(.search(query))
			.done { posts in
				RealmService().savePosts(posts)
			}.catch { _ in
				//TODO: handle error
		}
	}

	private var hasClearColorChanged: Bool = false
	private let listModes: [ListMode] = [.unread, .read]
	private var selectedListModeIndex: Int = 0
	private var selectedSortTypeIndex: Int = 0
	var sortType: ListSortType {
		guard let sort = listModes[safe: selectedListModeIndex]?.sortTypes[safe: selectedSortTypeIndex] else {
			assertionFailure("out of bounds")
			return PostListLogicController.DEFAULTSORT
		}
		if let query = searchQuery,
			query.count > 0,
			let filter = sort.filters.first {
			return .search(query, filter, sort.sortDescriptors)
		}
		return sort

	}

	deinit {
		for token in notificationTokens {
			token?.invalidate()
		}
		preconditionFailure("main view controller should never deinit")
	}

	init(controller: PostListViewController) {
		self.viewController = controller
		super.init()
	}

	private func tintClearIfNeeded(sender: UITextField) {
		guard !hasClearColorChanged else {
			return
		}
		for view in sender.subviews {
			guard let clearButton = view as? UIButton else {
				continue
			}

			let templateImage = clearButton.image(for: .highlighted)?.imageWithColor(Constants.Colors.Text.TITLE)
			clearButton.setImage(templateImage, for: .normal)
			clearButton.setImage(templateImage, for: .highlighted)
			hasClearColorChanged = true
			return
		}
	}

	@objc private func searchChanged(sender: UITextField) {
		viewController.hideReview()
		tintClearIfNeeded(sender: sender)
		search(query: sender.text)
	}

	private func search(query: String?) {
		searchService.cancelAllRequests()
		searchQuery = query
		debouncedSearch.call()
		setupPosts(sortType: sortType)
	}

	private func fetchTopics(_ topics: Results<Topic>, using service: MediumService) {
		for topic in topics {
			service.requestResource(.topic(topic.topicId))
				.done { posts in
					RealmService().savePosts(posts)
				}.catch { _ in
					//TODO: handle error
			}
		}
	}

	private func fetchTags(_ tags: Results<Tag>, using service: MediumService) {
		for tag in tags {
			service.requestResource(.tag(tag.name))
				.done { posts in
				RealmService().savePosts(posts)
				}.catch { _ in
					//TODO: handle error
			}
		}
	}

	private func fetchHome(using service: MediumService) {
		service.requestResource(.posts)
			.done { posts in
				RealmService().savePosts(posts)
			}.catch { _ in
				//TODO: handle error
		}
		service.requestResource(.topic(Topic.POPULARID))
			.done { posts in
				RealmService().savePosts(posts)
			}.catch { _ in
				//TODO: handle error
		}
	}

	private func autoFetchPosts(table: UITableView) {
		guard Defaults[.lastRefreshDate] < Date().timeIntervalSince1970 - 3600 else {
			return
		}
		table.es.startPullToRefresh()
	}

	// MARK: Inputs
	func setupPosts(sortType: ListSortType) {
		self.posts = sortType.posts
		self.viewController.table.reloadData()

		for token in notificationTokens {
			token?.invalidate()
		}
		notificationTokens = []
		for (section, post) in posts.enumerated() {
			notificationTokens.append(post.observe({ [weak self] changes in
				self?.viewController.table.applyChanges(changes: changes, section: section, additionalUpdates: nil)
			}))
		}

	}

	func setupSearch(field: UITextField) {
		field.delegate = self
		field.addTarget(self, action: #selector(searchChanged(sender:)), for: .editingChanged)
	}

	func setupTable(_ table: UITableView) {
		table.register(UnreadPostTableViewCell.self, forCellReuseIdentifier: reuseIdentifier)
		table.register(ReadPostTableViewCell.self, forCellReuseIdentifier: readIdentifier)
		table.dataSource = self
		table.delegate = self

		let service = MediumService()

		let header = table.es.addPullToRefresh { [weak self] in
			guard let strongSelf = self else {
				return
			}
			let topics = Topic.included
			let tags = Tag.included
			if topics.count > 0 {
				strongSelf.fetchTopics(topics, using: service)
			}
			if tags.count > 0 {
				strongSelf.fetchTags(tags, using: service)
			}
			if topics.count == 0 && tags.count == 0 {
				strongSelf.fetchHome(using: service)
			}
		}

		service.onAllCompletion = {
			Defaults[.lastRefreshDate] = Date().timeIntervalSince1970
			DispatchQueue.main.async {
				table.es.stopPullToRefresh()
			}
		}
//        service.onStart = { (resource, totalRequestCount, completedRequestCount) in
//            guard let animator = header.animator as? ESRefreshHeaderAnimator else {
//                return
//            }
//
//            let loadingName: String = {
//                switch resource {
//                case .posts:
//                    return "Home Feed"
//                case .tag(let name):
//                    return name
//                case .topic(let topicId):
//                    let realm = try? Realm()
//                    guard let name = realm?.object(ofType: Topic.self, forPrimaryKey: topicId)?.name else {
//                        return "Topics"
//                    }
//                    return name
//                case .search(let query):
//                    return query
//                case .update(let postId):
//                    return postId
//                }
//            }()
//            animator.loadingDescription = "Loading \(loadingName) (\(completedRequestCount)/\(totalRequestCount))"
//            let newState: ESRefreshViewState = animator.state == .refreshing ? .autoRefreshing : .refreshing
//            DispatchQueue.main.async {
//                animator.refresh(view: header, stateDidChange: newState)
//            }
//        }

		autoFetchPosts(table: table)
	}

	func setupListSwitcher(_ switcher: UISegmentedControl) {
		for (index, segment) in listModes.enumerated() {
			switcher.insertSegment(withTitle: segment.title, at: index, animated: false)
		}
		switcher.selectedSegmentIndex = selectedListModeIndex
		switcher.addTarget(self, action: #selector(listSwitch(sender:)), for: .valueChanged)
	}

	func setupSortButton(_ button: UIBarButtonItem) {
		guard let listMode = listModes[safe: selectedListModeIndex] else {
			assertionFailure("\(selectedListModeIndex) out of bounds")
			return
		}
		button.title = listMode.sortTypes.first?.buttonTitle
		button.target = self
		button.action = #selector(sortByAction(sender:))
	}

	// MARK: Selectors
	@objc func sortByAction(sender: UIBarButtonItem) {
		viewController.hideReview()
		guard let listMode = listModes[safe: selectedListModeIndex] else {
			assertionFailure("\(selectedListModeIndex) out of bounds")
			return
		}
		let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

		for (index, type) in listMode.sortTypes.enumerated() {
			controller.addAction(UIAlertAction(title: type.buttonTitle, style: .default, handler: { [unowned self] _ in
				sender.title = type.buttonTitle
				self.selectedSortTypeIndex = index
				self.setupPosts(sortType: self.sortType)
			}))
		}
		controller.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
			controller.dismiss(animated: true, completion: nil)
		}))
		controller.isModalInPopover = true
		controller.popoverPresentationController?.barButtonItem = sender
		viewController.present(controller, animated: true, completion: nil)
	}

	@objc func listSwitch(sender: UISegmentedControl) {
		viewController.hideReview()
		selectedListModeIndex = sender.selectedSegmentIndex
		//TODO: use previous selected for type
		selectedSortTypeIndex = 0
		setupPosts(sortType: sortType)
		viewController.sortButton.title =
			listModes[safe: sender.selectedSegmentIndex]?.sortTypes[0].buttonTitle
			?? PostListLogicController.DEFAULTSORT.buttonTitle
	}
}

extension PostListLogicController: UITableViewDataSource {
	func numberOfSections(in tableView: UITableView) -> Int {
		return posts.count
	}

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return posts[safe: section]?.count ?? 0
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let post = posts[safe: indexPath.section]?[safe: indexPath.row] else {
			assertionFailure("\(indexPath.row) out of bounds. \(posts.count) total")
			return UITableViewCell()
		}
		post.updateIfNeeded(using: searchService)
		if post.isRead {
			guard let cell = tableView.dequeueReusableCell(withIdentifier: readIdentifier) as? ReadPostTableViewCell else {
				assertionFailure("register PostTableViewCell with reuseIdentifier: \(readIdentifier) first")
				return UITableViewCell()
			}

			cell.configure(
				with: post,
				onToggleReadClick: nil,
				onOptionsClick: { [unowned self] post in
					self.viewController.hideReview()
				self.showOptions(for: post)
			})
			return cell
		} else {
			guard let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as? UnreadPostTableViewCell else {
				assertionFailure("register PostTableViewCell with reuseIdentifier: \(reuseIdentifier) first")
				return UITableViewCell()
			}

			cell.configure(
				with: post,
				onToggleReadClick: { [unowned self] post in
					self.viewController.hideReview()
					self.viewController.showReview(for: post)
				}, onOptionsClick: { [unowned self] post in
					self.viewController.hideReview()
					self.sharePost(post)
			})
			return cell
		}

	}
}

extension PostListLogicController: UITableViewDelegate {
	func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
		viewController.searchField.resignFirstResponder()
		viewController.hideReview()
	}

	func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
		return 128
	}

	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return UITableViewAutomaticDimension
	}

	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		viewController.hideReview()
		guard let post = posts[safe:indexPath.section]?[safe: indexPath.row],
			let url = URL(string: "https://medium.com/posts/\(post.postId)"),
			UIApplication.shared.canOpenURL(url) else {
				return
		}
		UIApplication.shared.open(url, options: [:], completionHandler: nil)
	}

}

extension PostListLogicController: UITextFieldDelegate {
	func textFieldShouldClear(_ textField: UITextField) -> Bool {
		viewController.hideReview()
		search(query: nil)
		return true
	}

	func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
		viewController.hideReview()
		return true
	}
}
