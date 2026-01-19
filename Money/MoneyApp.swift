//
//  MoneyApp.swift
//  Money
//
//  Created by Adon Omeri on 17/1/2026.
//

import Defaults
import SwiftUI
import SwiftData

@main
struct MoneyApp: App {
	@StateObject private var networkManager = NetworkManager.shared

	var body: some Scene {
		WindowGroup {
			Group {
				if networkManager.token != nil {
					ContentView()
						.environmentObject(networkManager)
						.transition(.blurReplace)
				} else {
					LoginSignupView()
						.environmentObject(networkManager)
						.transition(.blurReplace)
				}
			}
			.animation(.easeInOut, value: networkManager.token)
			.fontDesign(.monospaced)
		}
		.modelContainer(for: Transaction.self)
	}
}
