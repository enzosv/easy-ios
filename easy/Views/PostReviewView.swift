//
//  PostReviewView.swift
//  easy
//
//  Created by Lorenzo Rey Vergara on Sep 8, 2018.
//  Copyright © 2018 enzosv. All rights reserved.
//

import UIKit

class PostReviewView: UIView {
	private let headerView: UIView = {
		let view = UIView()
		view.backgroundColor = Constants.Colors.DARK
		return view
	}()

	private let headerLabel: UILabel = {
		let label = UILabel()
		label.font = .preferredFont(forTextStyle: .footnote)
		label.adjustsFontSizeToFitWidth = true
		label.textColor = Constants.Colors.Text.SUBTITLE
		label.backgroundColor = Constants.Colors.DARK
		label.text = "Marked as Read"
		return label
	}()

	private let topBorder: UIView = {
		let view = UIView()
		view.backgroundColor = Constants.Colors.Text.SUBTITLE
		return view
	}()

	private let upvoteView: UIView = {
		let view = UIView()
		view.backgroundColor = Constants.Colors.DARK
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

	private let leftBorder: UIView = {
		let view = UIView()
		view.backgroundColor = Constants.Colors.Text.SUBTITLE
		return view
	}()

	private let rightBorder: UIView = {
		let view = UIView()
		view.backgroundColor = Constants.Colors.Text.SUBTITLE
		return view
	}()

	private let titleView: UIView = {
		let view = UIView()
		view.backgroundColor = .black
		return view
	}()

	private let titleLabel: UILabel = {
		let label = UILabel()
		label.font = .preferredFont(forTextStyle: .headline)
		label.adjustsFontSizeToFitWidth = true
		label.textColor = Constants.Colors.Text.TITLE
		label.backgroundColor = .black
		label.numberOfLines = 0
		label.lineBreakMode = .byWordWrapping
		return label
	}()

	private let undoButton: UIButton = {
		let button = UIButton(type: .system)
		button.setTitle("UNDO", for: .normal)
		button.tintColor = Constants.Colors.Text.TITLE
		button.titleLabel?.font = .preferredFont(forTextStyle: .body)
		button.titleLabel?.adjustsFontSizeToFitWidth = true
		button.backgroundColor = Constants.Colors.DARK
		return button
	}()

	init(post: Post) {
		super.init(frame: .zero)
		setup()
		titleLabel.text = post.title
		upvoteCountLabel.text = "\(post.upvoteCount)"
		upvoteButton.tintColor = post.upvoteCount > 0 ? .blue : Constants.Colors.Text.SUBTITLE
		downvoteButton.tintColor = post.upvoteCount < 0 ? .red : Constants.Colors.Text.SUBTITLE
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func setup() {
		layer.cornerRadius = 8
		layer.borderColor = Constants.Colors.Text.SUBTITLE.cgColor
		layer.borderWidth = 2
		clipsToBounds = true

		upvoteView.addSubview(upvoteButton)
		upvoteView.addSubview(upvoteCountLabel)
		upvoteView.addSubview(downvoteButton)

		headerView.addSubview(headerLabel)
		titleView.addSubview(titleLabel)

		addSubview(headerView)
		addSubview(topBorder)
		addSubview(upvoteView)
		addSubview(leftBorder)
		addSubview(titleView)
		addSubview(rightBorder)
		addSubview(undoButton)
	}

	func remakeLayout() {

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

		headerLabel.snp.remakeConstraints { make in
			make.edges.equalToSuperview()
				.inset(UIEdgeInsets(top: 2, left: 8, bottom: 2, right: 8))
		}
		titleLabel.snp.remakeConstraints { make in
			make.edges.equalToSuperview()
				.inset(UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8))
		}

		headerView.snp.remakeConstraints { make in
			make.top.left.right.equalToSuperview()
		}
		topBorder.snp.remakeConstraints { make in
			make.top.equalTo(headerView.snp.bottom)
			make.left.right.equalToSuperview()
			make.height.equalTo(1)
		}
		upvoteView.snp.remakeConstraints { make in
			make.top.equalTo(topBorder.snp.bottom)
			make.bottom.left.equalToSuperview()
		}
		leftBorder.snp.remakeConstraints { make in
			make.top.bottom.equalTo(upvoteView)
			make.width.equalTo(1)
			make.left.equalTo(upvoteView.snp.right)
		}
		titleView.snp.remakeConstraints { make in
			make.top.bottom.equalTo(upvoteView)
			make.left.equalTo(leftBorder.snp.right)
		}
		rightBorder.snp.remakeConstraints { make in
			make.top.bottom.equalTo(upvoteView)
			make.width.equalTo(1)
			make.left.equalTo(titleLabel.snp.right)
		}
		undoButton.snp.remakeConstraints { make in
			make.top.bottom.equalTo(upvoteView)
			make.right.equalToSuperview()
			make.left.equalTo(rightBorder.snp.right)
			make.width.equalTo(64)
		}
	}

	func remove(animated: Bool, completion: ((Bool) -> Void)?) {
		guard let superview = superview else {
			completion?(true)
			return
		}
		guard animated else {
			removeFromSuperview()
			completion?(true)
			return
		}
		snp.remakeConstraints { make in
			make.top.equalTo(superview.snp.bottom)
				.offset(superview.safeAreaInsets.bottom)
			make.centerX.equalToSuperview()
			make.width.equalToSuperview().inset(32)
		}
		UIView.animate(withDuration: 0.3, animations: {
			superview.layoutIfNeeded()
			self.alpha = 0
		}, completion: { completed in
			self.removeFromSuperview()
			completion?(completed)
		})

	}

}
