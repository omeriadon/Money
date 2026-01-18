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

	var body: some Scene {
		WindowGroup {
			NavigationStack {
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
			.fontDesign(.monospaced)
		}
	}
}
