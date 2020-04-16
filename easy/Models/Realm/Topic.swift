//
//  Topic.swift
//  easy
//
//  Created by Lorenzo Rey Vergara on Jul 14, 2018.
//  Copyright © 2018 enzosv. All rights reserved.
//

import Foundation
import RealmSwift
import SwiftyJSON

class Topic: Filterable {
	//TODO: use fetched instead of hardcoded
	static let POPULARID = "9d34e48ecf94"

	@objc dynamic var topicId: String = ""

	override static func primaryKey() -> String? {
		return "topicId"
	}

	static var all: Results<Topic> {
		guard let realm = try? Realm() else {
			preconditionFailure("no realm")
		}
		return realm.objects(Topic.self)
	}

	static var included: Results<Topic> {
		return all.filter("isIncluded == true").sorted(byKeyPath: "name", ascending: true)
	}

	private static func topicIdFromJSON(_ json: JSON) -> String? {
		return json["topicId"].string
	}

	private static func existing(with topicId: String) -> Topic? {
		let realm = try? Realm()
		return realm?.object(ofType: Topic.self, forPrimaryKey: topicId)
	}

	private static func fromJSON(_ json: JSON, topicId: String) -> Topic? {
		if let existing = Topic.existing(with: topicId) {
			return existing
		}
		guard let name = json["name"].string else {
			assertionFailure("invalid json")
			return nil
		}
		let topic = Topic()
		topic.name = name
		topic.topicId = topicId
		let realm = try? Realm()
		try? realm?.write {
			realm?.add(topic)
		}
		return topic
	}

	static func getListFromJSON(_ json: [String: JSON]) -> [Topic]? {
		guard let topics = json["topics"]?.array else {
			return nil
		}

		var pendingTopics = [Topic]()
		for topic in topics {
			guard let topicId = Topic.topicIdFromJSON(topic) else {
				continue
			}
			guard let pendingTopic = Topic.fromJSON(topic, topicId: topicId) else {
				continue
			}
			pendingTopics.append(pendingTopic)
		}
		return pendingTopics
	}
}
