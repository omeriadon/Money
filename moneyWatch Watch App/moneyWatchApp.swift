// moneyWatchApp.swift

import SwiftData
import SwiftUI

@main
struct moneyWatch_Watch_AppApp: App {
	@StateObject private var session = WatchWatchSessionManager.shared
	@StateObject private var networkManager = NetworkManager.shared
	@StateObject private var repoHolder = RepoHolder()
	@Environment(\.modelContext) private var modelContext

	var body: some Scene {
		WindowGroup {
			ZStack {
				if let repo = repoHolder.repo {
					if session.hasToken {
						ContentView()
							.environmentObject(session)
							.environmentObject(networkManager)
							.environmentObject(repo)
							.transition(.blurReplace)
					} else {
						ContentUnavailableView(
							"No Token Saved",
							systemImage: "key.shield",
							description: Text("Sign in on your iPhone to create a token and use this app.")
						)
						.transition(.blurReplace)
					}
				}
			}
			.fontDesign(.monospaced)
			.animation(.easeInOut, value: session.hasToken)
			.task {
				if repoHolder.repo == nil {
					repoHolder.repo = TransactionRepository(
						context: modelContext,
						network: networkManager
					)
				}
			}
		}
	}
}
