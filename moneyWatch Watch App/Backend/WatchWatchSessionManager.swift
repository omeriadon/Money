//
//  WatchWatchSessionManager.swift
//  Money Watch App
//
//  Created by Adon Omeri on 21/1/2026.
//

import Combine
import Defaults
import Foundation
import WatchConnectivity

final class WatchWatchSessionManager: NSObject, WCSessionDelegate, ObservableObject {
	static let shared = WatchWatchSessionManager()

	private var networkManager: NetworkManager?

	override private init() {
		super.init()

		if WCSession.isSupported() {
			let session = WCSession.default
			session.delegate = self
			session.activate()
		}
	}

	// MARK: - Configuration

	func configure(networkManager: NetworkManager) {
		self.networkManager = networkManager
		rehydrateFromDefaults()
		rehydrateFromContext()
	}

	// MARK: - Public (you call on refresh button)

	func refresh() {
		rehydrateFromContext()
		pullFromPhoneIfReachable()
	}

	// MARK: - Application Context (truth)

	func session(
		_: WCSession,
		didReceiveApplicationContext context: [String: Any]
	) {
		apply(context)
	}

	private func rehydrateFromContext() {
		apply(WCSession.default.receivedApplicationContext)
	}

	// MARK: - Messages (fast path)

	func session(
		_: WCSession,
		didReceiveMessage message: [String: Any]
	) {
		apply(message)
	}

	// MARK: - State application (destructive)

	private func apply(_ payload: [String: Any]) {
		guard let networkManager else { return }

		Task { @MainActor in
			switch payload["authState"] as? String {
				case "loggedIn":
					if let token = payload["authToken"] as? String {
						Defaults[.userToken] = token
						networkManager.token = token
					}

				case "loggedOut":
					Defaults[.userToken] = nil
					networkManager.token = nil
					Defaults[.transactions] = []

				default:
					break
			}
		}
	}

	// MARK: - Pull from phone

	private func pullFromPhoneIfReachable() {
		guard WCSession.default.isReachable else { return }

		WCSession.default.sendMessage(
			["request": "authState"],
			replyHandler: nil
		)
	}

	private func rehydrateFromDefaults() {
		guard let networkManager else { return }
		Task { @MainActor in
			if let token = Defaults[.userToken] {
				networkManager.token = token
			}
		}
	}

	func session(
		_: WCSession,
		activationDidCompleteWith activationState: WCSessionActivationState,
		error _: Error?
	) {
		if activationState == .activated {
			refresh()
		}
	}
}
