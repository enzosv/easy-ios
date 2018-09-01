//https://raw.githubusercontent.com/webadnan/swift-debouncer/master/Debouncer.swift
import Foundation

class Debouncer: NSObject {
	var callback: (() -> Void)
	var delay: Double
	weak var timer: Timer?

	init(delay: Double, callback: @escaping (() -> Void)) {
		self.delay = delay
		self.callback = callback
	}

	func call() {
		timer?.invalidate()
		let nextTimer = Timer.scheduledTimer(
			timeInterval: delay,
			target: self,
			selector: #selector(Debouncer.fireNow),
			userInfo: nil,
			repeats: false)
		timer = nextTimer
	}

	@objc func fireNow() {
		self.callback()
	}
}
