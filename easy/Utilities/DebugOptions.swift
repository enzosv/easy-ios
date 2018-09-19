//
//  DebugOptions.swift
//  easy
//
//  Created by Lorenzo Rey Vergara on Sep 19, 2018.
//  Copyright © 2018 enzosv. All rights reserved.
//

func debugLog(_ items: String) {
	#if DEBUG
	Swift.print("👩‍💻 \(items)")
	#endif
}
