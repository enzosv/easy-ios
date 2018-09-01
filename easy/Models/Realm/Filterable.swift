//
//  Filterable.swift
//  easy
//
//  Created by Lorenzo Rey Vergara on Jul 14, 2018.
//  Copyright © 2018 enzosv. All rights reserved.
//

import RealmSwift
import DifferenceKit

class Filterable: Object, Differentiable {
	@objc dynamic var name: String = ""
	@objc dynamic var isIncluded: Bool = false

	func toggleIsIncluded() -> Bool {
		guard let realm = self.realm else {
			return isIncluded
		}
		try? realm.write {
			isIncluded = !isIncluded
		}
		return isIncluded
	}
}
