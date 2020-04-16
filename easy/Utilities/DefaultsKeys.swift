//
//  DefaultsKeys.swift
//  easy
//
//  Created by Lorenzo Rey Vergara on Jul 14, 2018.
//  Copyright © 2018 enzosv. All rights reserved.
//

import Foundation
enum Defaults: String {
    case isPremiumIncluded
    case isShowingIgnored
    case lastRefreshDate

    func setValue(_ value: Any) {
        UserDefaults.standard.setValue(value, forKey: rawValue)
        UserDefaults.standard.synchronize()
    }

    func boolValue() -> Bool {
        UserDefaults.standard.bool(forKey: rawValue)
    }

    func doubleValue() -> Double {
        UserDefaults.standard.double(forKey: rawValue)
    }

    func hasKey() -> Bool {
        UserDefaults.standard.value(forKey: rawValue) != nil
    }
}
