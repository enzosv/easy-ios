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
	case byDateReadDescending(NSPredicate)
	case byUpvoteCountDescending(NSPredicate)
	case byClapCountPerDayDescending(NSPredicate)
	case byClapCountDescending(NSPredicate)
	case byDatePostedDescending(NSPredicate)
	case search(String, NSPredicate, [SortDescriptor])

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

	var sortDescriptors: [SortDescriptor] {
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
		case .search(_, _, let sorts):
			return sorts
		}
	}

	private var defaultFilters: NSPredicate {
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
	}

	var filters: [NSPredicate] {
		if case .search(let query, _, _) = self {
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

		switch self {
		case .byClapCountPerDayDescending(let predicate),
			 .byClapCountDescending(let predicate),
			 .byDatePostedDescending(let predicate),
			.byDateReadDescending(let predicate),
			.byUpvoteCountDescending(let predicate):
			return [predicate]
		case .search:
			preconditionFailure("handle this before creating andpredicates")
		}
	}

	var posts: [Results<Post>] {
		let all: Results<Post> = {
			switch self {
			case .search(_, let filter, _):
				return Post.all.filter(filter)
			default:
				return Post.all.filter(defaultFilters)
			}
		}()
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
			let predicate = NSPredicate(format: "dateRead == nil")
			return [.byClapCountPerDayDescending(predicate),
					.byClapCountDescending(predicate),
					.byDatePostedDescending(predicate)]
		case .read:
			let predicate = NSPredicate(format: "dateRead != nil")
			return [.byDateReadDescending(predicate),
					.byUpvoteCountDescending(predicate),
					.byClapCountPerDayDescending(predicate),
					.byClapCountDescending(predicate),
					.byDatePostedDescending(predicate)]
		}
	}
}
