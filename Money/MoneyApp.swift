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

	@Default(.tab) var tab
	@Default(.rememberTab) var rememberTab

	init() {
		if !rememberTab {
			tab = "Home"
		}
	}

	var body: some Scene {
		WindowGroup {
			RootView()
				.environmentObject(networkManager)
		}
	}
}

#Preview {
	RootView()
		.environmentObject(NetworkManager.shared)
		.fontDesign(.monospaced)
}

#if canImport(HotSwiftUI)
	@_exported import HotSwiftUI
#elseif canImport(Inject)
	@_exported import Inject
#elseif canImport(InjectionNext)
	@_exported import InjectionNext
#endif
