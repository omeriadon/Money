//
//  iPhoneWatchSessionManager.swift
//  Money
//
//  Created by Adon Omeri on 21/1/2026.
//

import Combine
import Defaults
import Foundation
import WatchConnectivity

final class iPhoneWatchSessionManager: NSObject, WCSessionDelegate {
	static let shared = iPhoneWatchSessionManager()

	private var cancellables = Set<AnyCancellable>()

	override private init() {
		super.init()

		if WCSession.isSupported() {
			let session = WCSession.default
			session.delegate = self
			session.activate()
		}

		setupAppearanceObservers()
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
		var context: [String: Any] = if let token = Defaults[.userToken] {
			[
				"authState": "loggedIn",
				"authToken": token,
			]
		} else {
			[
				"authState": "loggedOut",
			]
		}
		context[AppearanceSync.key] = AppearanceSync.payload()

		do {
			try WCSession.default.updateApplicationContext(context)
		} catch {
			// ignored by design
		}
	}

	// MARK: - Foreground acceleration

	private func pushMessageIfReachable() {
		guard WCSession.default.isReachable else { return }

		var message: [String: Any] = if let token = Defaults[.userToken] {
			[
				"authState": "loggedIn",
				"authToken": token,
			]
		} else {
			[
				"authState": "loggedOut",
			]
		}
		message[AppearanceSync.key] = AppearanceSync.payload()

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

	private func setupAppearanceObservers() {
		Defaults.publisher(.useNewGradient)
			.sink { [weak self] _ in
				self?.syncNow()
			}
			.store(in: &cancellables)

		Defaults.publisher(.fontDesignStyle)
			.sink { [weak self] _ in
				self?.syncNow()
			}
			.store(in: &cancellables)

		Defaults.publisher(.showGoalsTab)
			.sink { [weak self] _ in
				self?.syncNow()
			}
			.store(in: &cancellables)
	}
}

private enum AppearanceSync {
	static let key = "appearance"

	static func payload() -> [String: Any] {
		[
			"useNewGradient": Defaults[.useNewGradient],
			"fontDesignStyle": Defaults[.fontDesignStyle],
			"showGoalsTab": Defaults[.showGoalsTab],
		]
	}
}
