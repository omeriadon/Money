//
//  RootView.swift
//  Money
//
//  Created by Adon Omeri on 20/1/2026.
//

import Combine
import SwiftData
import SwiftUI

struct RootView: View {
	@Environment(\.modelContext) private var modelContext
	@EnvironmentObject var networkManager: NetworkManager

	@StateObject private var repoHolder = RepoHolder()

	var body: some View {
		Group {
			if let repo = repoHolder.repo {
				if networkManager.token != nil {
					ContentView()
						.environmentObject(repo)
						.transition(.opacity)
				} else {
					LoginSignupView()
					.transition(.opacity)
				}
			}
		}
		.animation(.easeInOut, value: networkManager.token)
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

final class RepoHolder: ObservableObject {
	@Published var repo: TransactionRepository?
}
