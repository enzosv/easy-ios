//
//  PostOptionsPresenter.swift
//  easy
//
//  Created by Lorenzo Rey Vergara on Aug 2, 2018.
//  Copyright © 2018 enzosv. All rights reserved.
//

import UIKit

protocol PostOptionsPresenter: class {
	func showOptions(for post: Post)
	func sharePost(_ post: Post)
	var onPresentRequest: ((UIViewController) -> Void)? {
		get set
	}
}

extension PostOptionsPresenter {
	func showOptions(for post: Post) {
		let isRead = post.dateRead != nil
		let isIgnored = post.isIgnored
		let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
		actionSheet.view.tintColor = Constants.Colors.DARK
		actionSheet.addAction(UIAlertAction(title: "Mark as \(isRead ? "Unread" : "Read")", style: .default, handler: { _ in
			post.markAsRead(isRead: !isRead)
		}))
		actionSheet.addAction(UIAlertAction(title: "\(isIgnored ? "Show" : "Ignore")", style: .default, handler: { _ in
			post.setIsIgnored(!isIgnored)
		}))
		actionSheet.addAction(UIAlertAction(title: "Share", style: .default, handler: { [unowned self] _ in
			self.sharePost(post)
		}))
		actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
			actionSheet.dismiss(animated: true, completion: nil)
		}))
		onPresentRequest?(actionSheet)
	}

	func sharePost(_ post: Post) {
		let link = "https://medium.com/posts/\(post.postId)"
		let shareSheet = UIActivityViewController(activityItems: [link], applicationActivities: nil)
		shareSheet.view.tintColor = Constants.Colors.DARK
		shareSheet.excludedActivityTypes = [
			.airDrop,
			.assignToContact,
			.print,
			.saveToCameraRoll,
			.markupAsPDF,
			.openInIBooks,
			.postToFlickr,
			.postToTencentWeibo,
			.postToVimeo,
			.postToWeibo
		]
		onPresentRequest?(shareSheet)
	}
}
