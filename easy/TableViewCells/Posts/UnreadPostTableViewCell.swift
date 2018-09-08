//
//  UnreadPostTableViewCell.swift
//  easy
//
//  Created by Lorenzo Rey Vergara on Aug 8, 2018.
//  Copyright © 2018 enzosv. All rights reserved.
//

import UIKit

class UnreadPostTableViewCell: PostTableViewCell {
	private let leftOptionButton: UIButton = {
		let button = UIButton(type: .system)
		button.tintColor = Constants.Colors.Text.SUBTITLE
		button.backgroundColor = .black
		button.titleLabel?.font = .preferredFont(forTextStyle: .body)
		button.titleLabel?.adjustsFontForContentSizeCategory = true
		return button
	}()

	private var post: Post?
	private var onToggleReadClick: PostCallback?
	private var onOptionsClick: PostCallback?
	override func setup() {
		super.setup()
		optionsView.addSubview(leftOptionButton)

		middleOptionButton.setTitle("Mark Read", for: .normal)
		rightOptionButton.setTitle("Share", for: .normal)

		leftOptionButton.addTarget(self, action: #selector(toggleIsIgnored), for: .touchUpInside)
		middleOptionButton.addTarget(self, action: #selector(toggleIsRead), for: .touchUpInside)
		rightOptionButton.addTarget(self, action: #selector(shareAction), for: .touchUpInside)
	}

	override func remakeLayout() {
		super.remakeLayout()
		leftOptionButton.snp.remakeConstraints { make in
			make.top.bottom.width.equalTo(rightOptionButton)
			make.left.equalToSuperview().inset(1)
		}
	}

	override func configure(
		with post: Post,
		onToggleReadClick: PostCallback?,
		onOptionsClick: PostCallback?) {
		super.configure(with: post, onToggleReadClick: onToggleReadClick, onOptionsClick: onOptionsClick)
		self.post = post
		self.onToggleReadClick = onToggleReadClick
		self.onOptionsClick = onOptionsClick
		leftOptionButton.setTitle(post.isIgnored ? "Show" : "Ignore", for: .normal)
	}

	@objc func toggleIsIgnored() {
		guard let post = self.post else {
			assertionFailure("post must exist")
			return
		}
		post.setIsIgnored(!post.isIgnored)
	}

	@objc func toggleIsRead() {
		guard let post = self.post else {
			assertionFailure("post must exist")
			return
		}
		onToggleReadClick?(post)
		//TODO: popup asking for upvotes
		post.markAsRead(isRead: true)
	}

	@objc func shareAction() {
		guard let post = self.post else {
			assertionFailure("post must exist")
			return
		}
		onOptionsClick?(post)
	}
}
