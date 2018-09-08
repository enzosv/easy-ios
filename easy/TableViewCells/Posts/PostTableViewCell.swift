//
//  PostTableViewCell.swift
//  easy
//
//  Created by Lorenzo Rey Vergara on Jul 14, 2018.
//  Copyright © 2018 enzosv. All rights reserved.
//

import UIKit

fileprivate extension UILabel {
	static func make(font: UIFont, color: UIColor) -> UILabel {
		let label = UILabel()
		label.textColor = color
		label.font = font
		label.numberOfLines = 0
		label.lineBreakMode = .byWordWrapping
		label.adjustsFontForContentSizeCategory = true
		return label
	}

	static func makeForSubtitle() -> UILabel {
		let label = UILabel()
		label.textColor = Constants.Colors.Text.SUBTITLE
		label.font = .preferredFont(forTextStyle: .footnote)
		label.adjustsFontForContentSizeCategory = true
		return label
	}
}

typealias PostCallback = ((Post) -> Void)

class PostTableViewCell: UITableViewCell {

	private let titleLabel: UILabel =
		UILabel.make(font: .preferredFont(forTextStyle: .headline),
					 color: Constants.Colors.Text.TITLE)

	private let reasonLabel: UILabel = UILabel.makeForSubtitle()
	private let dateLabel: UILabel = UILabel.makeForSubtitle()
	private let virtualsLabel: UILabel = UILabel.makeForSubtitle()

	let optionsView: UIView = {
		let view = UIView()
		view.backgroundColor = Constants.Colors.DARK
		return view
	}()

	let middleOptionButton: UIButton = {
		let button = UIButton(type: .system)
		button.tintColor = Constants.Colors.Text.SUBTITLE
		button.backgroundColor = .black
		button.titleLabel?.font = .preferredFont(forTextStyle: .body)
		button.titleLabel?.adjustsFontForContentSizeCategory = true
		return button
	}()

	let rightOptionButton: UIButton = {
		let button = UIButton(type: .system)
		button.tintColor = Constants.Colors.Text.SUBTITLE
		button.backgroundColor = .black
		button.titleLabel?.font = .preferredFont(forTextStyle: .body)
		button.titleLabel?.adjustsFontForContentSizeCategory = true
		return button
	}()

	private let dateFormatter: DateFormatter = {
		let formatter = DateFormatter()
		formatter.dateFormat = "MMM d yy"
		return formatter
	}()

	override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		setup()
	}

	override func didMoveToSuperview() {
		super.didMoveToSuperview()
		remakeLayout()
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	func setup() {
		selectedBackgroundView = UIView()
		selectedBackgroundView?.backgroundColor = Constants.Colors.DARK
		backgroundColor = .black
		addSubview(reasonLabel)
		addSubview(titleLabel)
		addSubview(dateLabel)
		addSubview(virtualsLabel)

		optionsView.addSubview(middleOptionButton)
		optionsView.addSubview(rightOptionButton)
		addSubview(optionsView)
	}

	func remakeLayout() {
		reasonLabel.snp.remakeConstraints { (make) in
			make.left.right.equalToSuperview().inset(15)
			make.top.equalToSuperview().inset(20)
		}
		titleLabel.snp.remakeConstraints { (make) in
			make.left.right.equalTo(reasonLabel)
			make.top.equalTo(reasonLabel.snp.bottom).offset(8)
		}

		dateLabel.snp.remakeConstraints { (make) in
			make.left.equalTo(reasonLabel)
			make.top.equalTo(titleLabel.snp.bottom).offset(8)
		}
		virtualsLabel.snp.remakeConstraints { (make) in
			make.left.equalTo(reasonLabel)
			make.top.equalTo(dateLabel.snp.bottom).offset(8)
		}

		optionsView.snp.remakeConstraints { make in
			make.top.equalTo(virtualsLabel.snp.bottom).offset(20)
			make.left.right.bottom.equalToSuperview()
			make.height.equalTo(32)
		}

		rightOptionButton.snp.remakeConstraints { make in
			make.left.equalTo(middleOptionButton.snp.right).offset(1)
			make.top.bottom.right.equalToSuperview().inset(1)
		}

		middleOptionButton.snp.remakeConstraints { make in
			make.top.bottom.width.equalTo(rightOptionButton)
			make.centerX.equalToSuperview()
		}
	}

	func configure(
		with post: Post,
		onToggleReadClick: PostCallback?,
		onOptionsClick: PostCallback?) {
		let alpha: CGFloat = post.isIgnored ? 0.75 : 1
		titleLabel.alpha = alpha
		reasonLabel.alpha = alpha
		dateLabel.alpha = alpha
		virtualsLabel.alpha = alpha

		titleLabel.text = post.title
		reasonLabel.text = post.reasonForShowing.uppercased()
		dateLabel.text = {
			let date = Date(timeIntervalSince1970: post.firstPublishedAt/1000)
			return dateFormatter.string(from: date)
		}()

		let readString: String = {
			let time = post.readingTime
			guard !time.isNaN else {
				return ""
			}
			return "\(Int(round(time))) min read"
		}()
		let clapString: String = {
			let count = post.totalClapCount.thousandsString
			return "👏 \(count)"
		}()
		let recommendString: String = {
			let count = post.recommends.thousandsString
			return "🙌 \(count)"
		}()

		let virtuals = post.isSubscriptionLocked
			? [clapString, recommendString, readString, "★"]
			: [clapString, recommendString, readString]
		virtualsLabel.text = virtuals.joined(separator: " • ")
	}

}
