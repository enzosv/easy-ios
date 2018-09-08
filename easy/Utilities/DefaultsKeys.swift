//
//  DefaultsKeys.swift
//  easy
//
//  Created by Lorenzo Rey Vergara on Jul 14, 2018.
//  Copyright © 2018 enzosv. All rights reserved.
//

import SwiftyUserDefaults

extension DefaultsKeys {
	static let isPremiumIncluded = DefaultsKey<Bool>("isPremiumIncluded")
	static let isShowingIgnored = DefaultsKey<Bool>("isShowingIgnored")
	static let lastRefreshDate = DefaultsKey<Double>("lastRefreshDate")
}
