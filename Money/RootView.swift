//
//  RootView.swift
//  Money
//
//  Created by Adon Omeri on 20/1/2026.
//

import Defaults
import SwiftUI

struct RootView: View {
	@EnvironmentObject var networkManager: NetworkManager

	@StateObject private var repoHolder = RepoHolder()
	@Default(.hasSeenIntroSplash) private var hasSeenIntroSplash
	@State private var showIntroSplash = false

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

			if !hasSeenIntroSplash {
				showIntroSplash = true
			}
		}
		.sheet(isPresented: $showIntroSplash, onDismiss: {
			hasSeenIntroSplash = true
		}) {
			FirstLaunchSplashSheetView(isPresented: $showIntroSplash)
		}
		.dynamicTypeSize(...DynamicTypeSize.large)
	}
}
