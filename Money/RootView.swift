//
//  RootView.swift
//  Money
//
//  Created by Adon Omeri on 20/1/2026.
//

import SwiftUI

struct RootView: View {
	@EnvironmentObject var networkManager: NetworkManager

	@StateObject private var repoHolder = RepoHolder()

	var body: some View {
		ZStack {
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
					network: networkManager
				)
			}
		}
		.dynamicTypeSize(...DynamicTypeSize.large)
	}
}
