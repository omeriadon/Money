// moneyWatchApp.swift

import Defaults
import SwiftUI

@main
struct moneyWatch_Watch_AppApp: App {
	@StateObject private var session = WatchWatchSessionManager.shared
	@StateObject private var networkManager = NetworkManager.shared
	@StateObject private var repoHolder = RepoHolder()
	@State private var appRouter = AppRouter()
	@Default(.fontDesignStyle) private var fontDesignStyle

	private var appFontDesign: Font.Design {
		fontDesignStyle.fontDesign
	}

	var body: some Scene {
		WindowGroup {
			ZStack {
				if let repo = repoHolder.repo, let goalRepo = repoHolder.goalRepo {
					if networkManager.token != nil {
						ContentView()
							.environmentObject(session)
							.environmentObject(networkManager)
							.environment(repo)
							.environment(goalRepo)
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
			.environment(appRouter)
			.onOpenURL { url in
				appRouter.handle(url: url)
			}
			.animation(.easeInOut, value: networkManager.token)
			.task {
				session.configure(networkManager: networkManager)
				if repoHolder.repo == nil {
					repoHolder.repo = TransactionRepository.shared
				}
				if repoHolder.goalRepo == nil {
					repoHolder.goalRepo = GoalRepository.shared
				}
				session.refresh()
			}
		}
	}
}
