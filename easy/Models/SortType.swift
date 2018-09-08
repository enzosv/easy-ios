//
//  SortType.swift
//  easy
//
//  Created by Lorenzo Rey Vergara on Sep 8, 2018.
//  Copyright © 2018 enzosv. All rights reserved.
//

import RealmSwift
import SwiftyUserDefaults

enum ListSortType {
	case byDateReadDescending
	case byUpvoteCountDescending
	case byClapCountPerDayDescending
	case byClapCountDescending
	case byDatePostedDescending
	case search(String)

	var buttonTitle: String? {
		switch self {
		case .byClapCountPerDayDescending:
			return "Trending"
		case .byClapCountDescending:
			return "Claps ▼"
		case .byDatePostedDescending:
			return "Date Posted ▼"
		case .byDateReadDescending:
			return "Date Read ▼"
		case .byUpvoteCountDescending:
			return "Upvotes ▼"
		case .search:
			return nil
		}
	}

	private var sortDescriptors: [SortDescriptor] {
		switch self {
		case .byClapCountPerDayDescending:
			return [SortDescriptor(keyPath: "clapsPerDay", ascending: false)]
		case .byClapCountDescending:
			return [SortDescriptor(keyPath: "totalClapCount", ascending: false)]
		case .byDatePostedDescending:
			return [SortDescriptor(keyPath: "firstPublishedAt", ascending: false),
					SortDescriptor(keyPath: "totalClapCount", ascending: false)]
		case .byDateReadDescending:
			return [SortDescriptor(keyPath: "dateRead", ascending: false)]
		case .byUpvoteCountDescending:
			return [SortDescriptor(keyPath: "upvoteCount", ascending: false),
					SortDescriptor(keyPath: "dateRead", ascending: false)]
		case .search:
			return [SortDescriptor(keyPath: "upvoteCount", ascending: false),
					SortDescriptor(keyPath: "dateRead", ascending: false),
					SortDescriptor(keyPath: "clapsPerDay", ascending: false)]
		}
	}

	private var filters: [NSPredicate] {
		if case .search(let query) = self {
			let words = query.lowercased().components(separatedBy: " ")
			let orPredicates = NSCompoundPredicate(orPredicateWithSubpredicates:
				words.map {NSPredicate(format: "queryString CONTAINS %@", $0)})
			let searchPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
				NSPredicate(format: "NOT queryString BEGINSWITH %@ AND NOT author BEGINSWITH %@", query, query),
								 orPredicates])
			return [NSPredicate(format: "queryString BEGINSWITH %@", query),
					NSPredicate(format: "author BEGINSWITH %@", query),
					searchPredicate]
		}

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
		switch self {
		case .byClapCountPerDayDescending,
			 .byClapCountDescending,
			 .byDatePostedDescending:
			andPredicates.append(NSPredicate(format: "dateRead == nil"))
		case .byDateReadDescending, .byUpvoteCountDescending:
			andPredicates.append(NSPredicate(format: "dateRead != nil"))
		case .search:
			assertionFailure("handle this before creating andpredicates")
		}
		return [NSCompoundPredicate(andPredicateWithSubpredicates: andPredicates)]
	}

	var posts: [Results<Post>] {
		let all = Post.all
		let sorts = sortDescriptors
		return filters.map {all.filter($0).sorted(by: sorts)}
	}
}

enum ListMode {
	case unread
	case read

	var title: String {
		switch self {
		case .unread:
			return "Unread"
		case .read:
			return "History"
		}
	}

	var sortTypes: [ListSortType] {
		switch self {
		case .unread:
			return [.byClapCountPerDayDescending,
					.byClapCountDescending,
					.byDatePostedDescending]
		case .read:
			return [.byDateReadDescending,
					.byUpvoteCountDescending]
		}
	}
}
