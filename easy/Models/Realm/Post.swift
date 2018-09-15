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
	@objc dynamic var author: String?

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

	static func newFromJSON(_ json: JSON, author: String?) -> Post? {
		guard
			let postId = json["id"].string,
			let updatedAt = json["updatedAt"].double
			else {
				return nil
		}
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
		post.author = author

		//DERIVED VALUES
		post.queryString = {
			var queryStrings: [String] = [title]
			queryStrings.append(contentsOf: tags.map {$0.name})
			queryStrings.append(contentsOf: topics.map {$0.name})
			if let author = author {
				queryStrings.append(author)
			}
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

	var reasonForShowing: String {
		let includedTopics = topics.filter("isIncluded == true")
		if let name = includedTopics.filter("topicId != %@", Topic.POPULARID).first?.name {
			return name
		} else if let name = tags.filter("isIncluded == true").first?.name {
			return name
		} else if let name = includedTopics.first?.name {
			return name
		} else if let name = topics.first?.name {
			return name
		} else if let name = tags.first?.name {
			return name
		} else {
			assertionFailure("should have a reason")
			return ""
		}
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
