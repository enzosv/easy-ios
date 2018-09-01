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
			schemaVersion: 3,
			migrationBlock: { _, _ in

		})

		Realm.Configuration.defaultConfiguration = config
		do {
			_ = try Realm()
		} catch {
			assertionFailure("handle migration")
			Realm.Configuration.defaultConfiguration.deleteRealmIfMigrationNeeded = true
		}

	}

	static func initializeDefaults() {
		if !Defaults.hasKey(.isPremiumIncluded) {
			Defaults[.isPremiumIncluded] = true
		}
		if !Defaults.hasKey(.historySortType) {
			Defaults[.historySortType] = HistorySortType.byDateReadDescending.rawValue
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
//		print("\(posts.count) new or updated posts")
	}
}
