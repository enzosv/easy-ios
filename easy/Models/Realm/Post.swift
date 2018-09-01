//
//  Post.swift
//  easy
//
//  Created by Lorenzo Rey Vergara on Jul 13, 2018.
//  Copyright © 2018 enzosv. All rights reserved.
//

import RealmSwift
import SwiftyJSON
import Alamofire
import SwiftyUserDefaults

class Post: Object {
	@objc dynamic var postId: String = ""
	@objc dynamic var firstPublishedAt: Double = Double.nan
	@objc dynamic var createdAt: Double = Double.nan
	@objc dynamic var updatedAt: Double = Double.nan
	@objc dynamic var readingTime: Double = Double.nan
	@objc dynamic var isSubscriptionLocked: Bool = true
	@objc dynamic var recommends: Int = 0
	@objc dynamic var totalClapCount: Int = 0
	@objc dynamic var title: String = ""

	@objc dynamic var recommendsPerDay: Float = 0
	@objc dynamic var clapsPerDay: Float = 0
	@objc dynamic var queryString: String = ""

	@objc dynamic var dateRead: Date?
	@objc dynamic var isIgnored: Bool = false
	@objc dynamic var upvoteCount: Int = 0

	let tags = List<Tag>()
	let topics = List<Topic>()

	var isRead: Bool {
		return dateRead != nil
	}

	override static func primaryKey() -> String? {
		return "postId"
	}

	static func newFromJSON(_ json: JSON) -> Post? {
		guard
			let postId = json["id"].string,
			let updatedAt = json["updatedAt"].double
			else {
				return nil
		}
//		if let existing = Post.existing(with: id),
//			existing.updatedAt == updatedAt {
//			return nil
//		}
		guard
			let createdAt = json["createdAt"].double,
			let firstPublishedAt = json["firstPublishedAt"].double,
			let title = json["title"].string,
			let isSubscriptionLocked = json["isSubscriptionLocked"].bool,
			let virtuals = json["virtuals"].dictionary,
			let readingTime = virtuals["readingTime"]?.double,
			let recommends = virtuals["recommends"]?.int,
			let totalClapCount = virtuals["totalClapCount"]?.int,
			let tags = Tag.getListFromJSON(virtuals),
			let topics = Topic.getListFromJSON(virtuals)
			else {
				assertionFailure("invalid json")
				return nil
		}

		let post = Post()
		post.postId = postId
		post.firstPublishedAt = firstPublishedAt
		post.updatedAt = updatedAt
		post.createdAt = createdAt
		post.title = title
		post.readingTime = readingTime
		post.isSubscriptionLocked = isSubscriptionLocked
		post.recommends = recommends
		post.totalClapCount = totalClapCount
		post.tags.append(objectsIn: tags)
		post.topics.append(objectsIn: topics)

		//DERIVED VALUES
		post.queryString = {
			var queryStrings: [String] = [title]
			queryStrings.append(contentsOf: tags.map {$0.name})
			queryStrings.append(contentsOf: topics.map {$0.name})
			return queryStrings.joined(separator: " ").lowercased()
		}()

		let secondsSinceFirstPublished = Date().timeIntervalSince1970-firstPublishedAt/1000
		let daysSinceFirstPublished = Float(secondsSinceFirstPublished/86400)

		post.clapsPerDay = Float(totalClapCount)/daysSinceFirstPublished
		post.recommendsPerDay = Float(recommends)/daysSinceFirstPublished

		//USER SET VALUES
		if let existing = Post.existing(with: postId) {
			post.isIgnored = existing.isIgnored
			post.upvoteCount = existing.upvoteCount
			post.dateRead = existing.dateRead
		}

		return post
	}

	static func existing(with postId: String) -> Post? {
		let realm = try? Realm()
		return realm?.object(ofType: Post.self, forPrimaryKey: postId)
	}

	static var all: Results<Post> {
		guard let realm = try? Realm() else {
			preconditionFailure("no realm")
		}
		return realm.objects(Post.self)
	}

	static var unread: Results<Post> {
		return all.filter("dateRead == nil")
	}

	static var read: Results<Post> {
		let sortProperties: [SortDescriptor] = {
			if HistorySortType(rawValue: Defaults[.historySortType]) == HistorySortType.byUpvoteCountDescending {
				return [
					SortDescriptor(keyPath: "upvoteCount", ascending: false),
					SortDescriptor(keyPath: "dateRead", ascending: false)
				]
			} else {
				return [SortDescriptor(keyPath: "dateRead", ascending: false)]
			}
		}()

		return all.filter("dateRead != nil").sorted(by: sortProperties)
	}

//	static var freePosts: Results<Post>{
//		return unread.filter("isSubscriptionLocked == false")
//	}

	static var filtered: Results<Post> {
		let predicate: NSPredicate = {
			var andPredicates = [NSPredicate]()
			if !Defaults[.isPremiumIncluded] {
				andPredicates.append(NSPredicate(format: "isSubscriptionLocked == false"))
			}
			if !Defaults[.isShowingIgnored] {
				andPredicates.append(NSPredicate(format: "isIgnored == false"))
			}
			if Topic.included.count > 0 || Tag.included.count > 0 {
				andPredicates.append(NSPredicate(format: "ANY topics.isIncluded == true OR ANY tags.isIncluded == true"))
			}
			return NSCompoundPredicate(andPredicateWithSubpredicates: andPredicates)
		}()

		let results: Results<Post> = unread.filter(predicate)
		return results
	}

	var reasonForShowing: String {
		let included = topics.filter("isIncluded == true")
		if let first = included.first {
			if first.topicId == Topic.POPULARID {
				return included[safe: 1]?.name ?? first.name
			}
			return first.name
		}

		return
			tags.filter("isIncluded == true").first?.name
				?? topics.first?.name
				?? tags.first?.name ?? ""
	}

	func markAsRead(isRead: Bool) {
		guard let realm = realm else {
			assertionFailure("not in realm yet")
			return
		}
		try? realm.write {
			self.dateRead = isRead ? Date() : nil
		}
	}

	func setIsIgnored(_ isIgnored: Bool) {
		guard self.isIgnored != isIgnored else {
			return
		}
		guard let realm = realm else {
			assertionFailure("not in realm yet")
			return
		}
		try? realm.write {
			self.isIgnored = isIgnored
		}
	}

	func incrementUpvotes(_ upvotes: Int) {
		guard let realm = realm else {
			assertionFailure("not in realm yet")
			return
		}
		try? realm.write {
			self.upvoteCount += upvotes
		}
	}
}
