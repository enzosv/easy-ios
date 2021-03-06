//
//  MediumSessionManager.swift
//  easy
//
//  Created by Enzo on 06/01/2019.
//  Copyright © 2019 enzosv. All rights reserved.
//

import PromiseKit
import Alamofire
import SwiftyJSON
import RealmSwift

class MediumSessionManager: NSObject {
    static let shared = MediumSessionManager()
    private lazy var sessionManager: Alamofire.SessionManager = {
        let identifier = """
        \(Bundle.main.bundleIdentifier
        ?? Bundle.main.bundleURL.absoluteString)
        .background
        """
        let configuration = URLSessionConfiguration.background(
            withIdentifier: identifier)
        configuration.httpAdditionalHeaders = [
            "accept": "application/json",
            "Referer": "https://t.co/JV5396gd2O"
        ]
        configuration.timeoutIntervalForRequest = 3 //seconds
        configuration.sessionSendsLaunchEvents = true
        configuration.shouldUseExtendedBackgroundIdleMode = true
        configuration.httpMaximumConnectionsPerHost = 1
        configuration.waitsForConnectivity = false
        configuration.allowsCellularAccess = true
        configuration.httpShouldSetCookies = false
        let sessionManager = Alamofire.SessionManager(configuration: configuration)
        sessionManager.startRequestsImmediately = false
        return sessionManager
    }()

    private lazy var requestQueue = [String]()

    private override init() {
        super.init()
    }

    func requestTopics() -> Promise<[Topic]> {
        guard let urlString = Resource.topicList.urlString else {
            return Promise<[Topic]>(error: PMKError.badInput)
        }
        let pending = Promise<[Topic]>.pending()
        Alamofire.request(urlString)
        .validate()
            .responseString { response in
            let statusCode: Int = response.response?.statusCode ?? -1
            switch response.result {
            case .success(let value):
                debugLog("""
                ✅ successful request:
                \n\t\(statusCode): \(urlString)
                """)
                guard let dict = MediumSessionManager.sanitizeResponseString(value),
                    let topics = Topic.getListFromJSON(dict) else {
                        pending.resolver.fulfill([])
                        return
                }
                pending.resolver.fulfill(topics)
            case .failure(let error):
                debugLog("""
                ⚠️ request failed:
                \n\t\(statusCode): \(urlString)
                \n\t\(error.localizedDescription)
                """)
                pending.resolver.reject(error)
            }
        }
        return pending.promise
    }

    func request(resource: Resource) -> (dataTask: DataRequest?, promise: Promise<[Post]>) {
        guard
            let urlString = resource.urlString else {
            return (nil, Promise<[Post]>(error: PMKError.badInput))
        }
        guard !requestQueue.contains(urlString) else {
            return (nil, Promise<[Post]>(error: ResourceError.duplicateRequest(urlString: urlString)))
        }
        if case .update(let postId) = resource,
            let existing = Post.existing(with: postId),
            !existing.needsUpdate {
            return (nil, Promise<[Post]>(error: ResourceError.unnecessaryUpdate(urlString: urlString)))
        }
        requestQueue.append(urlString)
        let pending = Promise<[Post]>.pending()
        let dataTask = sessionManager.request(urlString)
        dataTask
        .validate()
            .responseString { response in
            if let index = self.requestQueue.firstIndex(of: urlString) {
                debugLog("removing request: \(urlString)")
                self.requestQueue.remove(at: index)
                if self.requestQueue.count == 0 {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                }
            } else {
                assertionFailure("\(urlString) not in request queue")
            }
            let statusCode: Int = response.response?.statusCode ?? -1
            switch response.result {
            case .success(let value):
                guard let posts = self.parsePostsFromSuccessfulResponse(value) else {
                    assertionFailure("invalid posts json from: \(urlString)")
                    return
                }
                debugLog("""
                    ✅ successful request:
                    \n\t\(statusCode): \(urlString)
                    """)
                pending.resolver.fulfill(posts)
            case .failure(let error):
                debugLog("""
                    ⚠️ request failed:
                    \n\t\(statusCode): \(urlString)
                    \n\t\(error.localizedDescription)
                    """)
                pending.resolver.reject(error)
            }
        }
        return (dataTask, pending.promise)
    }

    private static func sanitizeResponseString(_ responseString: String) -> [String: JSON]? {
        let jsonString = responseString.deletingPrefix("])}while(1);</x>").deletingSuffix("\"")
        let json = JSON(parseJSON: jsonString)
        return json["payload"].dictionary
    }

    private func parsePostsFromSuccessfulResponse(_ responseString: String) -> [Post]? {
        guard let payload = MediumSessionManager.sanitizeResponseString(responseString),
        let references = payload["references"]?.dictionary else {
            debugLog("⚠️ invalid posts response: \(responseString)")
            return nil
        }
        guard let posts = references["Post"]?.dictionary else {
            debugLog("⚠️ empty posts json: \(responseString)")
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
