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
	@Default(.useMonospacedFont) private var useMonospacedFont

	private var showIntroBinding: Binding<Bool> {
		Binding(
			get: { !hasSeenIntroSplash },
			set: { isPresented in
				hasSeenIntroSplash = !isPresented
			}
		)
	}

	var body: some View {
		ZStack {
			if let repo = repoHolder.repo, let goalRepo = repoHolder.goalRepo {
				if networkManager.token != nil {
					ContentView()
						.environmentObject(repo)
						.environmentObject(goalRepo)
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

			if repoHolder.goalRepo == nil {
				repoHolder.goalRepo = GoalRepository(
					network: networkManager
				)
			}
		}
		.sheet(isPresented: showIntroBinding) {
			FirstLaunchSplashSheetView()
		}
		.dynamicTypeSize(...DynamicTypeSize.large)
		.fontDesign(useMonospacedFont ? .monospaced : .default)
	}
}
