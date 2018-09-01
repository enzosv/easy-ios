//
//  FilterListViewController.swift
//  easy
//
//  Created by Lorenzo Rey Vergara on Jul 14, 2018.
//  Copyright © 2018 enzosv. All rights reserved.
//

import UIKit
import SwiftyUserDefaults

class FilterListViewController: UIViewController {

	private struct UIConstants {
		static let horizontalInset: CGFloat = 8
		static let verticalInset: CGFloat = 20
		static let buttonHeight: CGFloat = 44
	}
	private let premiumView: UIView = {
		let view = UIView()
		view.backgroundColor = Constants.Colors.DARK
		return view
	}()

	private let premiumLabel: UILabel = {
		let label = UILabel()
		label.text = "Show Premium Articles"
		label.textColor = Constants.Colors.Text.SUBTITLE
		return label
	}()

	private let premiumSwitch: UISwitch = {
		let pswitch = UISwitch()
		pswitch.isOn = Defaults[.isPremiumIncluded]
		return pswitch
	}()

	private let ignoreView: UIView = {
		let view = UIView()
		view.backgroundColor = Constants.Colors.DARK
		return view
	}()

	private let ignoreLabel: UILabel = {
		let label = UILabel()
		label.text = "Show Ignored Articles"
		label.textColor = Constants.Colors.Text.SUBTITLE
		return label
	}()

	private let ignoreSwitch: UISwitch = {
		let iswitch = UISwitch()
		iswitch.isOn = Defaults[.isShowingIgnored]
		return iswitch
	}()

	private let topicButton: UIButton = {
		let button = UIButton(type: .system)
		button.setTitle("Topics", for: .normal)
		button.tintColor = Constants.Colors.Text.SUBTITLE
		button.backgroundColor = Constants.Colors.DARK
		return button
	}()

	private let tagButton: UIButton = {
		let button = UIButton(type: .system)
		button.setTitle("Tags", for: .normal)
		button.tintColor = Constants.Colors.Text.SUBTITLE
		button.backgroundColor = Constants.Colors.DARK
		return button
	}()

	private let postListInputs: PostListLogicController?
	init(postListInputs: PostListLogicController?) {
		self.postListInputs = postListInputs
		super.init(nibName: nil, bundle: nil)
		title = "Filters"
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

    override func viewDidLoad() {
        super.viewDidLoad()
		setup()
		remakeLayout()
    }

	override func viewSafeAreaInsetsDidChange() {
		premiumView.snp.remakeConstraints { (make) in
			make.left.right.equalToSuperview()
			make.top.equalToSuperview().inset(1+view.safeAreaInsets.top)
			make.height.equalTo(UIConstants.buttonHeight)
		}
	}

	private func setup() {
		view.backgroundColor = .black
		premiumView.addSubview(premiumLabel)
		premiumView.addSubview(premiumSwitch)
		view.addSubview(premiumView)

		ignoreView.addSubview(ignoreLabel)
		ignoreView.addSubview(ignoreSwitch)
		view.addSubview(ignoreView)

		view.addSubview(topicButton)
		view.addSubview(tagButton)

		setupActions()
	}

	private func remakeLayout() {

		viewSafeAreaInsetsDidChange()
		premiumLabel.snp.remakeConstraints { (make) in
			make.left.equalToSuperview().inset(UIConstants.horizontalInset)
			make.centerY.equalToSuperview()
		}

		premiumSwitch.snp.remakeConstraints { (make) in
			make.left.equalTo(premiumLabel.snp.right).offset(8)
			make.right.equalToSuperview().inset(UIConstants.horizontalInset)
			make.centerY.equalToSuperview()
		}

		ignoreView.snp.remakeConstraints { make in
			make.top.equalTo(premiumView.snp.bottom).offset(1)
			make.left.right.height.equalTo(premiumView)
		}

		ignoreLabel.snp.remakeConstraints { (make) in
			make.left.equalToSuperview().inset(UIConstants.horizontalInset)
			make.centerY.equalToSuperview()
		}

		ignoreSwitch.snp.remakeConstraints { (make) in
			make.left.equalTo(ignoreLabel.snp.right).offset(8)
			make.right.equalToSuperview().inset(UIConstants.horizontalInset)
			make.centerY.equalToSuperview()
		}

		topicButton.snp.remakeConstraints { (make) in
			make.top.equalTo(ignoreView.snp.bottom).offset(1)
			make.left.right.equalToSuperview()
			make.height.equalTo(UIConstants.buttonHeight)
		}

		tagButton.snp.remakeConstraints { (make) in
			make.top.equalTo(topicButton.snp.bottom).offset(1)
			make.left.right.equalToSuperview()
			make.height.equalTo(UIConstants.buttonHeight)
		}

	}

	private func setupActions() {
		premiumSwitch.addTarget(self, action: #selector(premiumAction(sender:)), for: .valueChanged)
		ignoreSwitch.addTarget(self, action: #selector(ignoreAction(sender:)), for: .valueChanged)
		topicButton.addTarget(self, action: #selector(topicAction(sender:)), for: .touchUpInside)
		tagButton.addTarget(self, action: #selector(tagButton(sender:)), for: .touchUpInside)
	}

	@objc private func premiumAction(sender: UISwitch) {
		let newValue = !Defaults[.isPremiumIncluded]
		Defaults[.isPremiumIncluded] = newValue
		postListInputs?.setupPosts()
	}

	@objc private func ignoreAction(sender: UISwitch) {
		let newValue = !Defaults[.isShowingIgnored]
		Defaults[.isShowingIgnored] = newValue
		postListInputs?.setupPosts()
	}

	@objc private func topicAction(sender: UIButton) {
		let topicList = FilterableListViewController(
			filterMode: .topics(Topic.all.sorted(byKeyPath: "name", ascending: true)),
			inputs: postListInputs)
		navigationController?.pushViewController(topicList, animated: true)
	}

	@objc private func tagButton(sender: UIButton) {
		let tagList = FilterableListViewController(
			filterMode: .tags(Tag.all.sorted(byKeyPath: "name", ascending: true)),
			inputs: postListInputs)
		navigationController?.pushViewController(tagList, animated: true)
	}

}
