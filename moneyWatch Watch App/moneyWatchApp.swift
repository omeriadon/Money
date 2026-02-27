// moneyWatchApp.swift

import Defaults
import SwiftUI

@main
struct moneyWatch_Watch_AppApp: App {
	@StateObject private var session = WatchWatchSessionManager.shared
	@StateObject private var networkManager = NetworkManager.shared
	@StateObject private var repoHolder = RepoHolder()
	@Default(.fontDesignStyle) private var fontDesignStyle

	private var appFontDesign: Font.Design {
		AppFontDesign(rawValue: fontDesignStyle)?.fontDesign ?? .monospaced
	}

	var body: some Scene {
		WindowGroup {
			ZStack {
				if let repo = repoHolder.repo, let goalRepo = repoHolder.goalRepo {
					if networkManager.token != nil {
						ContentView()
							.environmentObject(session)
							.environmentObject(networkManager)
							.environmentObject(repo)
							.environmentObject(goalRepo)
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
			.fontDesign(appFontDesign)
			.animation(.easeInOut, value: networkManager.token)
			.task {
				session.configure(networkManager: networkManager)
				if repoHolder.repo == nil {
					repoHolder.repo = TransactionRepository(
						network: networkManager
					)
				}
				if repoHolder.goalRepo == nil {
					repoHolder.goalRepo = GoalRepository(
						network: networkManager
					)
				}
				session.refresh()
			}
		}
	}
}
