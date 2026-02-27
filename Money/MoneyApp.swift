//
//  MoneyApp.swift
//  Money
//
//  Created by Adon Omeri on 17/1/2026.
//

import SwiftUI

@main
struct MoneyApp: App {
	@StateObject private var networkManager = NetworkManager.shared

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
