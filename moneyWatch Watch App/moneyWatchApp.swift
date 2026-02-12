// moneyWatchApp.swift

import SwiftUI

@main
struct moneyWatch_Watch_AppApp: App {
	@StateObject private var session = WatchWatchSessionManager.shared
	@StateObject private var networkManager = NetworkManager.shared
	@StateObject private var repoHolder = RepoHolder()

	var body: some Scene {
		WindowGroup {
			ZStack {
				if let repo = repoHolder.repo {
					if networkManager.token != nil {
						ContentView()
							.environmentObject(session)
							.environmentObject(networkManager)
							.environmentObject(repo)
							.transition(.opacity)
					} else {
						ContentUnavailableView(
							"No Token Saved",
							systemImage: "key.shield",
							description: Text("Sign in on your iPhone to create a token and use this app.\niPhone app must be open to sync.")
						)
						.transition(.opacity)
					}
				}
			}
			.fontDesign(.monospaced)
			.animation(.easeInOut, value: networkManager.token)
			.task {
				session.configure(networkManager: networkManager)
				if repoHolder.repo == nil {
					repoHolder.repo = TransactionRepository(
						network: networkManager
					)
				}
				session.refresh()
			}
		}
	}
}
