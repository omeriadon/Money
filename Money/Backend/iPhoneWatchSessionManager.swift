//
//  iPhoneWatchSessionManager.swift
//  Money
//
//  Created by Adon Omeri on 21/1/2026.
//

import Defaults
import Foundation
import WatchConnectivity

final class iPhoneWatchSessionManager: NSObject, WCSessionDelegate {
	static let shared = iPhoneWatchSessionManager()

	override private init() {
		super.init()

		if WCSession.isSupported() {
			let session = WCSession.default
			session.delegate = self
			session.activate()
		}
	}

	// MARK: - Public sync triggers (you call these)

	func syncNow() {
		writeApplicationContext()
		pushMessageIfReachable()
	}

	func sendAuthToken(_ token: String) {
		Defaults[.userToken] = token
		syncNow()
	}

	func sendLogout() {
		Defaults[.userToken] = nil
		syncNow()
	}

	// MARK: - Application Context (authoritative)

	private func writeApplicationContext() {
		let context: [String: Any] = if let token = Defaults[.userToken] {
			[
				"authState": "loggedIn",
				"authToken": token,
			]
		} else {
			[
				"authState": "loggedOut",
			]
		}

		do {
			try WCSession.default.updateApplicationContext(context)
		} catch {
			// ignored by design
		}
	}

	// MARK: - Foreground acceleration

	private func pushMessageIfReachable() {
		guard WCSession.default.isReachable else { return }

		let message: [String: Any] = if let token = Defaults[.userToken] {
			[
				"authState": "loggedIn",
				"authToken": token,
			]
		} else {
			[
				"authState": "loggedOut",
			]
		}

		WCSession.default.sendMessage(message, replyHandler: nil)
	}

	// MARK: - Watch pull request

	func session(
		_: WCSession,
		didReceiveMessage message: [String: Any]
	) {
		if message["request"] as? String == "authState" {
			syncNow()
		}
	}

	func session(
		_: WCSession,
		activationDidCompleteWith activationState: WCSessionActivationState,
		error _: Error?
	) {
		if activationState == .activated {
			syncNow()
		}
	}

	func sessionDidBecomeInactive(_: WCSession) {}
	func sessionDidDeactivate(_: WCSession) {
		WCSession.default.activate()
	}
}
