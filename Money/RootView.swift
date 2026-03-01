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
	@Default(.fontDesignStyle) private var fontDesignStyle

	private var showIntroBinding: Binding<Bool> {
		Binding(
			get: { !hasSeenIntroSplash },
			set: { isPresented in
				hasSeenIntroSplash = !isPresented
			}
		)
	}

	private var appFontDesign: Font.Design {
		AppFontDesign(rawValue: fontDesignStyle)?.fontDesign ?? .monospaced
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
		.fullScreenCover(isPresented: showIntroBinding) {
			FirstLaunchSplashSheetView()
		}
		.dynamicTypeSize(...DynamicTypeSize.large)
		.fontDesign(appFontDesign)
		.id(appFontDesign)
		.animation(.easeInOut, value: appFontDesign)
#if os(iOS)
			.enableInjection()
		#endif
	}

	#if DEBUG && os(iOS)
		@ObserveInjection var forceRedraw
	#endif
}
