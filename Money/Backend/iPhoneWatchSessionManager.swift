//
//  iPhoneWatchSessionManager.swift
//  Money
//
//  Created by Adon Omeri on 21/1/2026.
//

import Foundation
import WatchConnectivity

final class iPhoneWatchSessionManager: NSObject, WCSessionDelegate {
	static let shared = iPhoneWatchSessionManager()

	override private init() {
		super.init()
		if WCSession.isSupported() {
			WCSession.default.delegate = self
			WCSession.default.activate()
		}
	}

	func sendAuthToken(_ token: String) {
		WCSession.default.transferUserInfo([
			"authToken": token,
		])
	}

	func sendLogout() {
		WCSession.default.transferUserInfo([
			"logout": true,
		])
	}

	func session(
		_: WCSession,
		activationDidCompleteWith _: WCSessionActivationState,
		error _: Error?
	) {}

	func sessionDidBecomeInactive(_: WCSession) {}
	func sessionDidDeactivate(_: WCSession) {
		WCSession.default.activate()
	}
}
