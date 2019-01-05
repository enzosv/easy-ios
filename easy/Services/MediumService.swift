//
//  MediumService.swift
//  easy
//
//  Created by Lorenzo Rey Vergara on Jul 13, 2018.
//  Copyright © 2018 enzosv. All rights reserved.
//

import PromiseKit
import RealmSwift
import Alamofire
import SwiftyJSON

//delay is intentional because this uses an unofficial API
private let DELAY: Double = 2.0
class MediumService {
	private struct ResourceRequest {
		var resource: Resource
		var promise: Promise<[Post]>
		var resolver: Resolver<[Post]>

		init(resource: Resource) {
			self.resource = resource
			let pending = Promise<[Post]>.pending()
			self.promise = pending.promise
			self.resolver = pending.resolver
		}
	}
	var onStart: ((Resource, Int, Int) -> Void)?
	var onAllCompletion: (() -> Void)?
	var completedRequestCount: Int = 0
	private var currentDataRequest: DataRequest?
	private var requests = [ResourceRequest]()

    private static let sessionManager: Alamofire.SessionManager = {
        let identifier = "\(Bundle.main.bundleIdentifier ?? Bundle.main.bundleURL.absoluteString).background"
        let configuration = URLSessionConfiguration.background(
            withIdentifier: identifier)
        configuration.httpAdditionalHeaders = ["accept": "application/json"]
        configuration.timeoutIntervalForRequest = 2000
        configuration.timeoutIntervalForResource = 2000
        configuration.sessionSendsLaunchEvents = false
        configuration.shouldUseExtendedBackgroundIdleMode = true
        configuration.httpMaximumConnectionsPerHost = 1
        configuration.waitsForConnectivity = false
        configuration.allowsCellularAccess = true
        configuration.httpShouldSetCookies = false

        return Alamofire.SessionManager(configuration: configuration)
    }()

	deinit {
		debugLog("‼️ \(self) deinited")
	}
	func requestResource(_ resource: Resource) -> Promise<[Post]> {

		let result = prepareRequest(resource: resource)
		if let error = result.error {
			return Promise<[Post]>.init(error: error)
		}
		guard let request = result.request else {
			assertionFailure("Error should exist")
			return Promise<[Post]>.init(error: ResourceError.other(message: "unknown error"))
		}
		requests.append(request)
		performRequest(request)
		return request.promise
	}

	func cancelAllRequests() {
		for request in requests {
			debugLog("cancelling \(request.resource.urlString ?? "nil")")
			if currentDataRequest?.request?.url?.absoluteString == request.resource.urlString {
				currentDataRequest?.cancel()
			} else {
				request.resolver.reject(PMKError.cancelled)
			}
		}
	}

	func cancelRequest(for resource: Resource) {
		debugLog("cancelling \(resource.urlString ?? "nil")")
		for request in requests {
			guard request.resource.urlString == resource.urlString else {
				continue
			}
			if currentDataRequest?.request?.url?.absoluteString == resource.urlString {
				currentDataRequest?.cancel()
			} else {
				request.resolver.reject(PMKError.cancelled)
			}
		}
	}

	private func prepareRequest(resource: Resource) -> (request: ResourceRequest?, error: Error?) {
		guard let urlString = resource.urlString else {
			assertionFailure("no url for request")
			return (nil, PMKError.badInput)
		}
		//prevent construction of duplicate requests
		let contains = requests.contains { $0.resource.urlString == urlString}
		guard !contains else {
			return (nil, ResourceError.duplicateRequest(urlString: urlString))
		}

		let request = ResourceRequest(resource: resource)
		request.promise
			.catch { error in
				debugLog("❌ \(error.localizedDescription)")
			}
			.finally {
				if let index = self.requests.index(where: {$0.resource.urlString == urlString}) {
					debugLog("removing request: \(urlString)")
					self.requests.remove(at: index)
				} else {
					assertionFailure("\(urlString) not in stack")
				}
				self.completedRequestCount += 1
				self.currentDataRequest = nil
				DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + DELAY, execute: {
					if let pending = self.requests.first {
						self.performRequest(pending)
					} else {
						self.completedRequestCount = 0
						self.onAllCompletion?()
					}
				})
		}
		return (request, nil)
	}

	private func performRequest(_ request: ResourceRequest) {
		guard let urlString = request.resource.urlString else {
			assertionFailure("no url for request")
			request.resolver.reject(PMKError.badInput)
			return
		}
		guard currentDataRequest == nil else {
			//different request already in progress. delay
			debugLog("queing request: \(urlString)")
			return
		}
		if case .update(let postId) = request.resource,
			let existing = Post.existing(with: postId),
			!existing.needsUpdate {
			request.resolver.reject(ResourceError.unnecessaryUpdate(urlString: urlString))
			return
		}

		currentDataRequest = MediumService.sessionManager.request(urlString)
		assert(currentDataRequest != nil, "\(urlString) is invalid")

		debugLog("requesting: \(urlString)")
		onStart?(request.resource, requests.count+completedRequestCount, completedRequestCount+1)
		currentDataRequest?.responseString { response in
			//not using weak self to keep service alive
			switch response.result {
			case .success(let value):
				guard let posts = self.parsePostsFromSuccessfulResponse(value) else {
					assertionFailure("invalid posts json from: \(urlString)")
					request.resolver.reject(ResourceError.invalidJSON(urlString: urlString))
					return
				}
				debugLog("✅ successful request:\n\t\(response.response?.statusCode ?? -1): \(urlString)")
				request.resolver.fulfill(posts)
			case .failure(let error):
				debugLog("⚠️ request failed:\n\t\(response.response?.statusCode ?? -1): \(urlString)")
				request.resolver.reject(error)
			}
		}

	}

	private func parsePostsFromSuccessfulResponse(_ response: String) -> [Post]? {
		let jsonString = response.deletingPrefix("])}while(1);</x>").deletingSuffix("\"")
		let json = JSON(parseJSON: jsonString)
		guard
			let payload = json["payload"].dictionary,
			let references = payload["references"]?.dictionary else {
				//happens when search is empty
				debugLog("⚠️ invalid posts json: \(jsonString)")
				return nil
		}
		guard let posts = references["Post"]?.dictionary else {
			debugLog("⚠️ empty posts json: \(jsonString)")
			return []
		}
		let users = references["User"]?.dictionary
		var pendingPosts = [Post]()
		for (_, json) in posts {
			let author: String? = {
				guard let userId = json["creatorId"].string,
					let user = users?[userId]?.dictionary else {
						debugLog("⚠️ no user")
						return nil
				}
				return user["name"]?.string
			}()

			guard let post = Post.newFromJSON(json, author: author) else {
				continue
			}
			pendingPosts.append(post)
		}
		return pendingPosts
	}
}
