//
//  ReadPostTableViewCell.swift
//  easy
//
//  Created by Lorenzo Rey Vergara on Aug 8, 2018.
//  Copyright © 2018 enzosv. All rights reserved.
//

import UIKit

class ReadPostTableViewCell: PostTableViewCell {

	private let upvoteView: UIView = {
		let view = UIView()
		view.backgroundColor = .black
		return view
	}()

	private let upvoteButton: UIButton = {
		let button = UIButton(type: .system)
		button.setTitle("⇧", for: .normal)
		button.titleLabel?.font = .preferredFont(forTextStyle: .body)
		button.titleLabel?.adjustsFontForContentSizeCategory = true
		return button
	}()

	private let downvoteButton: UIButton = {
		let button = UIButton(type: .system)
		button.setTitle("⇩", for: .normal)
		button.titleLabel?.font = .preferredFont(forTextStyle: .body)
		button.titleLabel?.adjustsFontForContentSizeCategory = true
		return button
	}()

	private let upvoteCountLabel: UILabel = {
		let label = UILabel()
		label.textAlignment = .center
		label.textColor = Constants.Colors.Text.SUBTITLE
		label.font = .preferredFont(forTextStyle: .caption1)
		label.adjustsFontForContentSizeCategory = true
		return label
	}()

	private var post: Post?
	private var onOptionsClick: ((Post) -> Void)?

	override func setup() {
		super.setup()

		upvoteView.addSubview(upvoteButton)
		upvoteView.addSubview(upvoteCountLabel)
		upvoteView.addSubview(downvoteButton)
		optionsView.addSubview(upvoteView)

		middleOptionButton.setTitle("Mark Unread", for: .normal)
		rightOptionButton.setTitle("᛫᛫᛫", for: .normal)

		upvoteButton.addTarget(self, action: #selector(upvoteAction), for: .touchUpInside)
		downvoteButton.addTarget(self, action: #selector(downvoteAction), for: .touchUpInside)
		middleOptionButton.addTarget(self, action: #selector(toggleIsRead), for: .touchUpInside)
		rightOptionButton.addTarget(self, action: #selector(showOptions), for: .touchUpInside)
	}

	override func remakeLayout() {
		super.remakeLayout()
		upvoteView.snp.remakeConstraints { make in
			make.top.bottom.width.equalTo(rightOptionButton)
			make.left.equalToSuperview().inset(1)
		}
		upvoteButton.snp.remakeConstraints { make in
			make.top.bottom.left.equalToSuperview().inset(1)
		}
		upvoteCountLabel.snp.remakeConstraints { make in
			make.left.equalTo(upvoteButton.snp.right).offset(1)
			make.top.bottom.equalToSuperview()
		}
		downvoteButton.snp.remakeConstraints { make in
			make.top.bottom.width.equalTo(upvoteButton)
			make.left.equalTo(upvoteCountLabel.snp.right).offset(1)
			make.right.equalToSuperview().inset(1)
		}
	}

	override func configure(with post: Post, onOptionsClick: ((Post) -> Void)?) {
		super.configure(with: post, onOptionsClick: onOptionsClick)
		self.post = post
		self.onOptionsClick = onOptionsClick
		upvoteCountLabel.text = "\(post.upvoteCount)"

		upvoteButton.tintColor = post.upvoteCount > 0 ? .blue : Constants.Colors.Text.SUBTITLE
		downvoteButton.tintColor = post.upvoteCount < 0 ? .red : Constants.Colors.Text.SUBTITLE
	}

	@objc private func showOptions() {
		guard let post = self.post else {
			assertionFailure("post must exist")
			return
		}
		onOptionsClick?(post)
	}

	@objc func toggleIsRead() {
		guard let post = self.post else {
			assertionFailure("post must exist")
			return
		}
		post.markAsRead(isRead: false)
	}

	@objc func upvoteAction() {
		guard let post = self.post else {
			assertionFailure("post must exist")
			return
		}
		post.incrementUpvotes(1)
	}

	@objc func downvoteAction() {
		guard let post = self.post else {
			assertionFailure("post must exist")
			return
		}
		post.incrementUpvotes(-1)
	}
}
