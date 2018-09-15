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

	deinit {
		print("‼️ \(self) deinited")
	}
	func requestResource(_ resource: Resource) -> Promise<[Post]> {
		let request = ResourceRequest(resource: resource)
		queueRequest(request)
		return request.promise
	}

	func cancelAllRequests() {
		for request in requests {
			print("cancelling \(request.resource.urlString ?? "nil")")
			if currentDataRequest?.request?.url?.absoluteString == request.resource.urlString {
				currentDataRequest?.cancel()
			} else {
				request.resolver.reject(PMKError.cancelled)
			}
		}
	}

	func cancelRequest(for resource: Resource) {
		print("cancelling \(resource.urlString ?? "nil")")
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

	private func queueRequest(_ request: ResourceRequest) {
		guard let urlString = request.resource.urlString else {
			assertionFailure("no url for request")
			return
		}
		let contains = requests.contains { $0.resource.urlString == urlString}
		guard !contains else {
			print("⚠️ \(urlString) already in queue")
			request.resolver.reject(PMKError.cancelled)
			//already in queue
			//TODO: consider prioritizing
			return
		}
		requests.append(request)
		performRequest(request)
	}

	private func performRequest(_ request: ResourceRequest) {
		guard let urlString = request.resource.urlString else {
			assertionFailure("no url for request")
			return
		}
		guard currentDataRequest == nil else {
			print("queing request: \(urlString)")
			//different request already in progress. delay
			return
		}

		//perform next request after success/failure
		request.promise
			.catch { error in
				print("❌ \(error.localizedDescription)")
			}
			.finally {
				if let index = self.requests.index(where: {$0.resource.urlString == urlString}) {
					print("removing request: \(urlString)")
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

		currentDataRequest = Alamofire.request(urlString, headers: ["accept": "application/json"])
		assert(currentDataRequest != nil, "\(urlString) is invalid")

		print("requesting: \(urlString)")
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
				print("✅ successful request:\n\t\(response.response?.statusCode ?? -1): \(urlString)")
				request.resolver.fulfill(posts)
			case .failure(let error):
				print("⚠️ request failed:\n\t\(response.response?.statusCode ?? -1): \(urlString)")
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
				print("⚠️ invalid posts json: \(jsonString)")
				return nil
		}
		guard let posts = references["Post"]?.dictionary else {
			print("⚠️ empty posts json: \(jsonString)")
			return []
		}
		let users = references["User"]?.dictionary
		var pendingPosts = [Post]()
		for (_, json) in posts {
			let author: String? = {
				guard let userId = json["creatorId"].string,
					let user = users?[userId]?.dictionary else {
						print("⚠️ no user")
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
