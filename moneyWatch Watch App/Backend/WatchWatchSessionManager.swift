//
//  WatchWatchSessionManager.swift
//  Money
//
//  Created by Adon Omeri on 21/1/2026.
//

import Combine
import Foundation
import WatchConnectivity

final class WatchWatchSessionManager: NSObject, WCSessionDelegate, ObservableObject {
	static let shared = WatchWatchSessionManager()

	@Published private(set) var hasToken: Bool = false

	override private init() {
		super.init()
		if WCSession.isSupported() {
			WCSession.default.delegate = self
			WCSession.default.activate()
		}

		hasToken = TokenStore.shared.load() != nil
	}

	func session(
		_: WCSession,
		didReceiveUserInfo userInfo: [String: Any]
	) {
		if userInfo["logout"] as? Bool == true {
			TokenStore.shared.clear()
			DispatchQueue.main.async {
				self.hasToken = false
			}
			return
		}

		if let token = userInfo["authToken"] as? String {
			TokenStore.shared.save(token)
			DispatchQueue.main.async {
				self.hasToken = true
			}
		}
	}

	func session(
		_: WCSession,
		activationDidCompleteWith _: WCSessionActivationState,
		error _: Error?
	) {}
}
