//
//  Tag.swift
//  easy
//
//  Created by Lorenzo Rey Vergara on Jul 14, 2018.
//  Copyright © 2018 enzosv. All rights reserved.
//

import RealmSwift
import SwiftyJSON

class Tag: Filterable {
	override static func primaryKey() -> String? {
		return "name"
	}

	static var all: Results<Tag> {
		guard let realm = try? Realm() else {
			preconditionFailure("no realm")
		}
		return realm.objects(Tag.self)
	}

	static var included: Results<Tag> {
		return all.filter("isIncluded == true").sorted(byKeyPath: "name", ascending: true)
	}

	private static func existing(named: String) -> Tag? {
		let realm = try? Realm()
		return realm?.object(ofType: Tag.self, forPrimaryKey: named)
	}

	private static func fromJSON(_ json: JSON) -> Tag? {
		guard let name = json["name"].string else {
			return nil
		}
		if let existing = Tag.existing(named: name) {
			return existing
		}
		let tag = Tag()
		tag.name = name

		let realm = try? Realm()
		try? realm?.write {
			realm?.add(tag)
		}
		return tag
	}

	static func getListFromJSON(_ json: [String: JSON]) -> [Tag]? {
		guard let tags = json["tags"]?.array else {
			return nil
		}
		var pendingTags = [Tag]()
		for tag in tags {
			guard let pendingTag = Tag.fromJSON(tag) else {
				continue
			}
			pendingTags.append(pendingTag)
		}
		return pendingTags
	}
}
