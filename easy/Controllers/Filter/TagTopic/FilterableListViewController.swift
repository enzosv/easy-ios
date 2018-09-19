//
//  FilterableListViewController.swift
//  easy
//
//  Created by Lorenzo Rey Vergara on Sep 1, 2018.
//  Copyright © 2018 enzosv. All rights reserved.
//

import UIKit
import RealmSwift
import DifferenceKit

class FilterableListViewController: UIViewController {

	private static let REUSEIDENTIFIER = "filterCell"
	typealias DictionaryArray = [ArraySection<DifferentiableKey, FilterRow>]
	struct FilterRow: Differentiable {
		let rowId: String
		let name: String
		var isIncluded: Bool
		let objectType: ObjectType

		var differenceIdentifier: String {
			return rowId
		}

		func isContentEqual(to source: FilterRow) -> Bool {
			return rowId == source.rowId && isIncluded == source.isIncluded
		}
	}

	struct DifferentiableKey: Differentiable {
		let key: Character
		var differenceIdentifier: Character {
			return key
		}

		func isContentEqual(to source: DifferentiableKey) -> Bool {
			return key == source.key
		}
	}

	enum ObjectType {
		case tag
		case topic
	}

	enum FilterMode {
		case topics(Results<Topic>)
		case tags(Results<Tag>)

		var title: String {
			switch self {
			case .topics:
				return "Topics"
			case .tags:
				return "Tags"
			}
		}

		var sections: DictionaryArray {
			var sections: [Character: [FilterRow]] = [:]
			var included: [FilterRow] = []
			switch self {
			case .topics(let topics):
				for topic in topics {
					guard let key = topic.name.capitalized.first else {
						continue
					}
					let filterRow = FilterRow(rowId: topic.topicId, name: topic.name, isIncluded: topic.isIncluded, objectType: .topic)
					if topic.isIncluded {
						included.append(filterRow)
					}
					if sections[key] != nil {
						sections[key]?.append(filterRow)
					} else {
						sections[key] = [filterRow]
					}
				}
			case .tags(let tags):
				for tag in tags {
					guard let key = tag.name.capitalized.first else {
						continue
					}
					let filterRow = FilterRow(rowId: tag.name, name: tag.name, isIncluded: tag.isIncluded, objectType: .tag)
					if tag.isIncluded {
						included.append(filterRow)
					}
					if sections[key] != nil {
						sections[key]?.append(filterRow)
					} else {
						sections[key] = [filterRow]
					}
				}
			}
			let sorted = sections.sorted {$0.0 < $1.0}
			var arraySections: [ArraySection<DifferentiableKey, FilterRow>] = [
				ArraySection(model: DifferentiableKey(key: "✓"), elements: included)
			]
			for (key, value) in sorted {
				arraySections.append(ArraySection(model: DifferentiableKey(key: key), elements: value))
			}
			return arraySections
		}
	}

	private let table: UITableView = {
		let table = UITableView()
		table.tableFooterView = UIView()
		table.backgroundColor = .black
		table.separatorColor = Constants.Colors.DARK
		table.separatorInset = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
		table.sectionIndexColor = Constants.Colors.Text.SUBTITLE
		return table
	}()

	private let inputs: PostListLogicController
	private lazy var mediumService = MediumService()
	private let filterMode: FilterMode
	private var sections: DictionaryArray
	private var allToken: NotificationToken?

	deinit {
		allToken?.invalidate()
		debugLog("‼️ \(self) deinited")
	}

	init(filterMode: FilterMode, inputs: PostListLogicController) {
		self.filterMode = filterMode
		self.sections = filterMode.sections
		self.inputs = inputs
		super.init(nibName: nil, bundle: nil)
		self.title = filterMode.title
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

    override func viewDidLoad() {
        super.viewDidLoad()
		setupViews()
		remakeLayout()
		setupTable(table)
    }

	private func setupViews() {
		view.addSubview(table)
	}

	private func remakeLayout() {
		table.snp.remakeConstraints { make in
			make.edges.equalToSuperview()
		}
	}

	private func setupTable(_ table: UITableView) {
		table.register(FilterableTableViewCell.self, forCellReuseIdentifier: FilterableListViewController.REUSEIDENTIFIER)
		table.dataSource = self
		table.delegate = self

		switch filterMode {
		case .topics(let topics):
			allToken = topics.observe({ [weak self] _ in
				self?.applyTableChanges()
			})
		case .tags(let tags):
			allToken = tags.observe({ [weak self] _ in
				self?.applyTableChanges()
			})
		}
	}

	private func applyTableChanges() {
		let changeset = StagedChangeset(source: sections, target: filterMode.sections)
		table.reload(using: changeset, with: .fade) { [weak self] data in
			self?.sections = data
		}
	}

}

extension FilterableListViewController: UITableViewDataSource {
	func numberOfSections(in tableView: UITableView) -> Int {
		return sections.count
	}

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return sections[safe: section]?.elements.count ?? 0
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard
			let cell = tableView.dequeueReusableCell(withIdentifier: FilterableListViewController.REUSEIDENTIFIER)
				as? FilterableTableViewCell,
			let filterRow = sections[safe: indexPath.section]?.elements[safe: indexPath.row]
			else {
			assertionFailure()
			return UITableViewCell()
		}

		cell.configure(with: filterRow.name, isIncluded: filterRow.isIncluded)
		return cell
	}

	func sectionIndexTitles(for tableView: UITableView) -> [String]? {
		return sections.map {String($0.model.key)}
	}

}

extension FilterableListViewController: UITableViewDelegate {
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		guard
			let realm = try? Realm(),
			let filterRow = sections[safe: indexPath.section]?.elements[safe: indexPath.row] else {
			return
		}
		let resource: Resource
		let included: Bool
		switch filterRow.objectType {
		case .topic:
			included = realm.object(ofType: Topic.self, forPrimaryKey: filterRow.rowId)?.toggleIsIncluded() ?? false
			resource = .topic(filterRow.rowId)
		case .tag:
			included = realm.object(ofType: Tag.self, forPrimaryKey: filterRow.rowId)?.toggleIsIncluded() ?? false
			resource = .tag(filterRow.rowId)
		}
		inputs.setupPosts(sortType: inputs.sortType)

		if included {
			mediumService.requestResource(resource)
				.done { posts in
					RealmService().savePosts(posts)
				}.catch { _ in
					//TODO: handle error
			}
		} else {
			mediumService.cancelRequest(for: resource)
		}
	}

	func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		guard sections[section].elements.count > 0 else {
			return 0
		}
		return 20
	}

	func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		guard sections[section].elements.count > 0 else {
			return nil
		}
		guard section > 0 else {
			return "Included \(filterMode.title) (\(sections[section].elements.count))"
		}
		return String(sections[section].model.key)
	}
}
