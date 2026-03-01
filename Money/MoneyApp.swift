//
//  MoneyApp.swift
//  Money
//
//  Created by Adon Omeri on 17/1/2026.
//

import Defaults
import SwiftUI

@main
struct MoneyApp: App {
	@StateObject private var networkManager = NetworkManager.shared
	@State private var appRouter = AppRouter()

	@Default(.tab) var tab
	@Default(.rememberTab) var rememberTab

	init() {
		if !Defaults[.rememberTab] {
			Defaults[.tab] = "Home"
		}
	}

	var body: some Scene {
		WindowGroup {
			RootView()
				.environmentObject(networkManager)
				.environment(appRouter)
				.onOpenURL { url in
					appRouter.handle(url: url)
				}
		}
	}
}

#Preview {
	RootView()
		.environmentObject(NetworkManager.shared)
		.environment(AppRouter())
		.fontDesign(.monospaced)
}

#if canImport(HotSwiftUI)
	@_exported import HotSwiftUI
#elseif canImport(Inject)
	@_exported import Inject
#elseif canImport(InjectionNext)
	@_exported import InjectionNext
#endif
