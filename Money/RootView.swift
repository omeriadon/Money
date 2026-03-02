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
		fontDesignStyle.fontDesign
	}

	var body: some View {
		ZStack {
			if let transactionRepo = repoHolder.transactionRepo, let goalRepo = repoHolder.goalRepo {
				if networkManager.token != nil {
					ContentView()
						.environment(transactionRepo)
						.environment(goalRepo)
						.transition(.opacity)
				} else {
					LoginSignupView()
						.transition(.opacity)
				}
			}
		}
		.animation(.easeInOut, value: networkManager.token)
		.task {
			if repoHolder.transactionRepo == nil {
				repoHolder.transactionRepo = TransactionRepository.shared
			}

			if repoHolder.goalRepo == nil {
				repoHolder.goalRepo = GoalRepository.shared
			}
		}
		.fullScreenCover(isPresented: showIntroBinding) {
			FirstLaunchSplashSheetView()
		}
		.dynamicTypeSize(...DynamicTypeSize.large)
		.fontDesign(appFontDesign)
		#if os(iOS)
			.enableInjection()
		#endif
	}

	#if DEBUG && os(iOS)
		@ObserveInjection var forceRedraw
	#endif
}
