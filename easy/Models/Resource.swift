//
//  Resource.swift
//  easy
//
//  Created by Lorenzo Rey Vergara on Jul 14, 2018.
//  Copyright © 2018 enzosv. All rights reserved.
//

import Foundation.NSError

private let ROOTURL = "https://medium.com"

public enum ResourceError: Error {
	case duplicateRequest(urlString:String)
	case unnecessaryUpdate(urlString:String)
	case invalidJSON(urlString:String)
}

extension ResourceError: LocalizedError {
	public var errorDescription: String? {
		switch self {
		case .duplicateRequest(let urlString):
			return "Duplicate request: \(urlString)"
		case .unnecessaryUpdate(let urlString):
			return "Unnecessary update: \(urlString)"
		case .invalidJSON(let urlString):
			return "Invalid JSON for \(urlString)"
		}
	}
}

enum Resource {
	case posts
	case topic(String)
	case tag(String)
	case search(String)
	case update(String)

	var urlString: String? {
		switch self {
		case .posts:
			return "\(ROOTURL)/_/api/home-feed"
		case .topic(let topicId):
			return "\(ROOTURL)/_/api/topics/\(topicId)/stream"
		case .tag(let name):
			guard let encoded = name.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {
				assertionFailure("unable to encode: \(name)")
				return nil
			}
			return "\(ROOTURL)/_/api/tags/\(encoded)/stream"
		case .search(let query):
			let trimmed = query.trimmingCharacters(in: .whitespaces)
			guard trimmed.count > 0 else {
				return nil
			}
			guard let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {
				assertionFailure("unable to encode: \(query)")
				return nil
			}
			return "\(ROOTURL)/search?q=\(encoded)"
		case .update(let postId):
			return "\(ROOTURL)/search?q=\(postId)"
		}
	}
}
