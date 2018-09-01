//
//  Extensions.swift
//  easy
//
//  Created by Lorenzo Rey Vergara on Jul 14, 2018.
//  Copyright © 2018 enzosv. All rights reserved.
//

import Foundation
import UIKit.UIColor
import RealmSwift

extension Collection {
	/// Returns the element at the specified index iff it is within bounds, otherwise nil.
	subscript (safe index: Index) -> Element? {
		return indices.contains(index) ? self[index] : nil
	}
}

extension String {
	func deletingPrefix(_ prefix: String) -> String {
		guard self.hasPrefix(prefix) else { return self }
		return String(self.dropFirst(prefix.count))
	}

	func deletingSuffix(_ suffix: String) -> String {
		guard self.hasSuffix(suffix) else { return self }
		return String(self.dropLast(suffix.count))
	}
}

extension UIColor {
	convenience init(red: Int, green: Int, blue: Int) {
		assert(red >= 0 && red <= 255, "Invalid red component")
		assert(green >= 0 && green <= 255, "Invalid green component")
		assert(blue >= 0 && blue <= 255, "Invalid blue component")

		self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
	}

	convenience init(rgb: Int) {
		self.init(
			red: (rgb >> 16) & 0xFF,
			green: (rgb >> 8) & 0xFF,
			blue: rgb & 0xFF
		)
	}
}

extension Int {
	var thousandsString: String {
		guard self > 999 else {
			return "\(self)"
		}
		return "\(Int(round(Double(self)/1000)))K"
	}
}

extension UITableView {
	func applyChanges<T>(
		changes: RealmCollectionChange<T>,
		section: Int,
		_ file: String = #file,
		_ line: Int = #line,
		_ function: String = #function,
		additionalUpdates: (() -> Void)?) {

		switch changes {
		case .initial:
			reloadData()
		case .update(_, let deletions, let insertions, let updates):
				let fromRow = { (row: Int) in return IndexPath(row: row, section: section) }
				beginUpdates()
				additionalUpdates?()
				deleteRows(at: deletions.map(fromRow), with: .automatic)
				insertRows(at: insertions.map(fromRow), with: .automatic)
				reloadRows(at: updates.map(fromRow), with: .automatic)
				endUpdates()
		case .error(let error):
			fatalError("\t\(error) \(file) \(line) \(function)")
		}
	}
}

extension UIImage {
	func imageWithColor(_ color: UIColor) -> UIImage? {
		let rect = CGRect(origin: CGPoint.zero, size: size)
		UIGraphicsBeginImageContextWithOptions(size, false, 0)

		if let context = UIGraphicsGetCurrentContext() {
			context.clip(to: rect, mask: cgImage!)
			context.setFillColor(color.cgColor)
			context.fill(rect)
			let img = UIGraphicsGetImageFromCurrentImageContext()
			UIGraphicsEndImageContext()
			if let cgImage = img?.cgImage {
				return UIImage(cgImage: cgImage, scale: 1, orientation: .downMirrored)
			}

		}
		return self
	}
}
