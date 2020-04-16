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
import Foundation

class Post: Object {
	@objc dynamic var postId: String = ""
	@objc dynamic var firstPublishedAt: Double = Double.nan
	@objc dynamic var createdAt: Double = Double.nan
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

	var reasonForShowing: String? {
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
			//probably searched
			debugLog("⚠️ no reason for showing: \(self.title) \((self.postId))")
			return nil
		}
	}

	var needsUpdate: Bool {
		guard let housekeeping = PostHousekeeping.existing(postId: postId) else {
			assertionFailure("housekeeping must exist")
			return true
		}
		return housekeeping.lastUpdateCheck+86400 < Date().timeIntervalSince1970
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
		let existing = Post.existing(with: postId)
		let oldUpdatedAt = PostHousekeeping.existing(postId: postId)?.updatedAt
			?? 0
		PostHousekeeping.createOrUpdate(updatedAt: updatedAt, lastCheck: Date().timeIntervalSince1970, for: postId)
		guard oldUpdatedAt < updatedAt else {
			assert(oldUpdatedAt == updatedAt, "old must not be greater than new")
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

		let queryString: String = {
			var queryStrings: [String] = [title]
			queryStrings.append(contentsOf: tags.map {$0.name})
			queryStrings.append(contentsOf: topics.map {$0.name})
			if let author = author {
				queryStrings.append(author)
			}
			return queryStrings.joined(separator: " ").lowercased()
		}()

		guard existing?.totalClapCount != totalClapCount
			|| existing?.recommends != recommends
			|| existing?.queryString != queryString
			|| existing?.createdAt != createdAt
			|| existing?.firstPublishedAt != firstPublishedAt
			|| existing?.isSubscriptionLocked != isSubscriptionLocked
			|| existing?.readingTime != readingTime else {
				debugLog("updated \(title) with no changes... skipping")
			return nil
		}

		let post = Post()
		post.postId = postId
		post.firstPublishedAt = firstPublishedAt
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
		post.queryString = queryString
		post.updateDates()
		//USER SET VALUES
		post.isIgnored = existing?.isIgnored ?? false
		post.upvoteCount = existing?.upvoteCount ?? 0
		post.dateRead = existing?.dateRead

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

	func updateDates() {
		let secondsSinceFirstPublished = Date().timeIntervalSince1970-firstPublishedAt/1000
		let daysSinceFirstPublished = Int(secondsSinceFirstPublished/86400)
		if daysSinceFirstPublished == 0 {
			clapsPerDay = Float(totalClapCount)
			recommendsPerDay = Float(recommends)
		} else {
			clapsPerDay = Float(totalClapCount/daysSinceFirstPublished)
			recommendsPerDay = Float(recommends/daysSinceFirstPublished)
		}
	}

	func updateIfNeeded(using service: MediumService) {
		guard needsUpdate else {
			return
		}

		//Uses search instead of fetching entire post content
		service.requestResource(.update(postId))
			.done { posts in
				RealmService().savePosts(posts)
			}.catch { _ in
				//TODO: handle error
		}
	}

	func markAsRead(isRead: Bool) {
		guard let realm = realm else {
			assertionFailure("not in realm yet")
			return
		}
		// REVIEW: consider resetting upvotes
		let date = isRead ? Date() : nil
		try? realm.write {
			self.dateRead = date
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
