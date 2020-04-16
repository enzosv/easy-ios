//
//  PostHousekeeping.swift
//  easy
//
//  Created by Lorenzo Rey Vergara on Sep 26, 2018.
//  Copyright © 2018 enzosv. All rights reserved.
//

import Foundation
import RealmSwift

class PostHousekeeping: Object {
	@objc dynamic var updatedAt: Double = 0
	@objc dynamic var lastUpdateCheck: Double = 0
	@objc dynamic var postId: String = ""

	override static func primaryKey() -> String? {
		return "postId"
	}

	static func existing(postId: String) -> PostHousekeeping? {
		guard let realm = try? Realm() else {
			assertionFailure("realm must exist")
			return nil
		}
		return realm.object(ofType: PostHousekeeping.self, forPrimaryKey: postId)
	}

	@discardableResult
	static func createOrUpdate(
		updatedAt: Double,
		lastCheck: Double,
		for postId: String) -> PostHousekeeping {
		guard let realm = try? Realm() else {
			preconditionFailure("realm must exist")
		}
		guard let existing = realm.object(ofType: PostHousekeeping.self, forPrimaryKey: postId) else {
			let new = PostHousekeeping()
			new.postId = postId
			new.updatedAt = updatedAt
			new.lastUpdateCheck = lastCheck
			try? realm.write {
				realm.add(new)
			}
			return new
		}
		try? realm.write {
			existing.updatedAt = updatedAt
			existing.lastUpdateCheck = lastCheck
		}
		return existing
	}
}
