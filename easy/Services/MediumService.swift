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

class MediumService {
	var onAllCompletion: (() -> Void)?
	private lazy var requests = [DataRequest]()

	deinit {
		debugLog("‼️ \(self) deinited")
	}

	func requestResource(_ resource: Resource) -> Promise<[Post]> {
        let (dataTask, promise) = MediumSessionManager.shared.request(resource: resource)
        if let task = dataTask {
            requests.append(task)
            promise.ensure {
                guard let index = self.requests.firstIndex(
                    where: {$0.request?.url?.absoluteString == task.request?.url?.absoluteString})  else {
                    return
                }
                self.requests.remove(at: index)
                if self.requests.count == 0 {
                    self.onAllCompletion?()
                }
            }.cauterize()
        }
        debugLog("requesting \(resource.urlString ?? "unknown")")
        dataTask?.resume()
        return promise
	}

	func cancelAllRequests() {
		for request in requests {
			debugLog("cancelling \(request.request?.url?.absoluteString ?? "nil")")
            request.cancel()
		}
	}

	func cancelRequest(for resource: Resource) {
        guard let urlString = resource.urlString else {
            return
        }
		debugLog("cancelling \(urlString)")
        requests.first(where: {$0.request?.url?.absoluteString == urlString})?.cancel()
	}
}
