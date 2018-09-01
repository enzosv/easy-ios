//
//  FilterableTableViewCell.swift
//  easy
//
//  Created by Lorenzo Rey Vergara on Jul 14, 2018.
//  Copyright © 2018 enzosv. All rights reserved.
//

import UIKit

class FilterableTableViewCell: UITableViewCell {

	private let nameLabel: UILabel = {
		let label = UILabel()
		label.textColor = Constants.Colors.Text.SUBTITLE
		return label
	}()
	override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		setup()
		remakeLayout()
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func setup() {
		selectedBackgroundView = UIView()
		selectedBackgroundView?.backgroundColor = Constants.Colors.DARK
		backgroundColor = .black
		addSubview(nameLabel)
	}

	private func remakeLayout() {
		nameLabel.snp.remakeConstraints { (make) in
			make.left.equalToSuperview().inset(15)
			make.centerY.equalToSuperview()
		}
	}

	func configure(with name: String, isIncluded: Bool) {
		nameLabel.text = name
		configureLabel(isIncluded: isIncluded)
	}

	private func configureLabel(isIncluded: Bool) {
		let pointSize = nameLabel.font.pointSize
		nameLabel.font = isIncluded
			? UIFont.boldSystemFont(ofSize: pointSize)
			: UIFont.systemFont(ofSize: pointSize)
		nameLabel.textColor = isIncluded
			? Constants.Colors.Text.TITLE
			: Constants.Colors.Text.SUBTITLE
	}

}
