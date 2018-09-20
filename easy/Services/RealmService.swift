//
//  RealmService.swift
//  easy
//
//  Created by Lorenzo Rey Vergara on Jul 14, 2018.
//  Copyright © 2018 enzosv. All rights reserved.
//

import RealmSwift
import SwiftyUserDefaults

class RealmService {

	static func performMigration() {
		let config = Realm.Configuration(
			schemaVersion: 5,
			migrationBlock: { migration, oldSchemaVersion in
				if oldSchemaVersion < 5 {
					migration.enumerateObjects(ofType: Post.className()) { oldObject, newObject in
						guard let updatedAt = oldObject?["updatedAt"] as? Double else {
							assertionFailure("no updated at")
							return
						}
						newObject?["lastUpdateCheck"] = updatedAt/1000
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
	}

	func savePosts(_ posts: [Post]) {
		guard let realm = try? Realm() else {
			assertionFailure("no realm")
			return
		}
		try? realm.write {
			realm.add(posts, update: true)
		}
//		debugLog("\(posts.count) new or updated posts")
	}
}
