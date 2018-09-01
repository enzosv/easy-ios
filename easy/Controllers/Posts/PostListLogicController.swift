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

private let reuseIdentifier = "postCell"
private let readIdentifier = "readPostCell"

class PostListLogicController: NSObject, PostOptionsPresenter {

	private var posts: Results<Post> = Post.filtered.sorted(byKeyPath: "clapsPerDay", ascending: false)
	private var notificationToken: NotificationToken?
	var onPresentRequest: ((UIViewController) -> Void)?
	private let table: UITableView

	private let searchField: UITextField
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

	deinit {
		notificationToken?.invalidate()
		preconditionFailure("main view controller should never deinit")
	}

	init(
		with table: UITableView,
		searchField: UITextField) {
		self.table = table
		self.searchField = searchField
		super.init()

		setupTable()
		searchField.delegate = self
		searchField.addTarget(self, action: #selector(searchChanged(sender:)), for: .editingChanged)

		autoFetchPosts()
	}

	private func setupTable() {
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

		service.onAllCompletion = { [weak self] in
			Defaults[.lastRefreshDate] = Date().timeIntervalSince1970
			DispatchQueue.main.async {
				self?.table.es.stopPullToRefresh()
			}
		}
		service.onStart = { (resource, totalRequestCount, completedRequestCount) in
			guard let animator = header.animator as? ESRefreshHeaderAnimator else {
				return
			}

			let loadingName: String = {
				switch resource {
				case .posts:
					return "Home Feed"
				case .tag(let name):
					return name
				case .topic(let topicId):
					let realm = try? Realm()
					guard let name = realm?.object(ofType: Topic.self, forPrimaryKey: topicId)?.name else {
						return "Topics"
					}
					return name
				case .search(let query):
					return query
				}
			}()
			animator.loadingDescription = "Loading \(loadingName) (\(completedRequestCount)/\(totalRequestCount))"
			let newState: ESRefreshViewState = animator.state == .refreshing ? .autoRefreshing : .refreshing
			DispatchQueue.main.async {
				animator.refresh(view: header, stateDidChange: newState)
			}
			print((header.animator as? ESRefreshHeaderAnimator)?.loadingDescription)
		}

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
		tintClearIfNeeded(sender: sender)
		search(query: sender.text)
	}

	private func search(query: String?) {
		searchService.cancelAllRequests()
		searchQuery = query
		debouncedSearch.call()
		setupPosts()
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

	func setupPosts() {
		let posts: Results<Post>
		if let query = searchQuery?.lowercased(),
			query.count > 0 {
			let predicate: NSPredicate = {

				var andPredicates: [NSPredicate] = []
				for word in query.split(separator: " ") {
					andPredicates.append(NSPredicate(format: "queryString CONTAINS %@", String(word)))
				}
				let orPredicates: [NSPredicate] = [
					NSPredicate(format: "queryString BEGINSWITH %@", query),
					NSCompoundPredicate(andPredicateWithSubpredicates: andPredicates)
				]
				return NSCompoundPredicate(orPredicateWithSubpredicates: orPredicates)
			}()
			posts = Post.all.filter(predicate)
		} else {
			posts = Post.filtered
		}
		self.posts = posts.sorted(byKeyPath: "clapsPerDay", ascending: false)
		table.reloadData()
//		print("displaying \(posts.count) of \(Post.all.count) posts")
		notificationToken = self.posts.observe({ [weak self] changes in
			self?.table.applyChanges(changes: changes, section: 0, additionalUpdates: nil)
		})
	}

	private func autoFetchPosts() {
		guard Defaults[.lastRefreshDate] < Date().timeIntervalSince1970 - 3600 else {
			return
		}
		table.es.startPullToRefresh()
	}
}

extension PostListLogicController: UITableViewDataSource {
	func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return posts.count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let post = posts[safe: indexPath.row] else {
			assertionFailure("\(indexPath.row) out of bounds. \(posts.count) total")
			return UITableViewCell()
		}
		if post.isRead {
			guard let cell = tableView.dequeueReusableCell(withIdentifier: readIdentifier) as? ReadPostTableViewCell else {
				assertionFailure("register PostTableViewCell with reuseIdentifier: \(readIdentifier) first")
				return UITableViewCell()
			}

			cell.configure(with: post, onOptionsClick: { [unowned self] post in
				self.showOptions(for: post)
			})
			return cell
		} else {
			guard let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as? UnreadPostTableViewCell else {
				assertionFailure("register PostTableViewCell with reuseIdentifier: \(reuseIdentifier) first")
				return UITableViewCell()
			}

			cell.configure(with: post, onOptionsClick: { [unowned self] post in
				self.sharePost(post)
			})
			return cell
		}

	}
}

extension PostListLogicController: UITableViewDelegate {
	func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
		searchField.resignFirstResponder()
	}

	func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
		return 128
	}

	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return UITableViewAutomaticDimension
	}

	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		guard let post = posts[safe: indexPath.row],
			let url = URL(string: "https://medium.com/posts/\(post.postId)"),
			UIApplication.shared.canOpenURL(url) else {
				return
		}
		UIApplication.shared.open(url, options: [:], completionHandler: nil)
	}

}

extension PostListLogicController: UITextFieldDelegate {
	func textFieldShouldClear(_ textField: UITextField) -> Bool {
		search(query: nil)
		return true
	}
}
