//
//  Resource.swift
//  easy
//
//  Created by Lorenzo Rey Vergara on Jul 14, 2018.
//  Copyright © 2018 enzosv. All rights reserved.
//

private let ROOTURL = "https://medium.com"

enum ResourceError: Error {
	case duplicateRequest
	case invalidJSON(urlString:String)
	var localizedDescription: String {
		switch self {
		case .duplicateRequest:
			return "Duplicate request"
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
		}
	}
}
