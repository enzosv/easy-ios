//
//  RealmService.swift
//  easy
//
//  Created by Lorenzo Rey Vergara on Jul 14, 2018.
//  Copyright © 2018 enzosv. All rights reserved.
//

import RealmSwift
import SwiftyUserDefaults
import Foundation

class RealmService {

	static func performMigration() {
		let config = Realm.Configuration(
			schemaVersion: 6,
			migrationBlock: { migration, oldSchemaVersion in
				if oldSchemaVersion < 6 {
					migration.enumerateObjects(ofType: Post.className()) { oldObject, _ in
						let housekeeping = migration.create(PostHousekeeping.className())
						guard
							let postId = oldObject?["postId"] as? String,
							let updatedAt = oldObject?["updatedAt"] as? Double
							else {
								assertionFailure("invalid post")
								return
						}
						let lastUpdateCheck = oldObject?["lastUpdateCheck"] as? Double ?? updatedAt/1000
						housekeeping["postId"] = postId
						housekeeping["updatedAt"] = updatedAt
						housekeeping["lastUpdateCheck"] = lastUpdateCheck
					}
				}
		})

		Realm.Configuration.defaultConfiguration = config
		do {
			_ = try Realm()
		} catch {
			assertionFailure("handle migration")
			Realm.Configuration.defaultConfiguration.deleteRealmIfMigrationNeeded = true
		}

	}

	static func updateDates() {
		guard let realm = try? Realm() else {
			assertionFailure("no realm")
			return
		}
		let posts = Post.all
		try? realm.write {
			for post in posts {
				post.updateDates()
			}
		}
	}

	static func initializeDefaults() {
		if !Defaults.hasKey(.isPremiumIncluded) {
			Defaults[.isPremiumIncluded] = true
		}
        MediumSessionManager.shared.requestTopics()
            .done { topics in
            guard let realm = try? Realm() else {
                assertionFailure("no realm")
                return
            }
            try? realm.write {
                realm.add(topics, update: .modified)
            }
        }.catch { error in
            print(error)
        }
	}

	func savePosts(_ posts: [Post]) {
		guard let realm = try? Realm() else {
			assertionFailure("no realm")
			return
		}
		try? realm.write {
            realm.add(posts, update: .modified)
		}
//		debugLog("\(posts.count) new or updated posts")
	}
}
