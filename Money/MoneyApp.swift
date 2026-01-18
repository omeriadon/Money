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
	@State private var isLoggedIn: Bool = (Defaults[.userToken] as String?) != nil

	var body: some Scene {
		WindowGroup {
			NavigationStack {
				if isLoggedIn {
					ContentView()
						.environmentObject(networkManager)
						.transition(.blurReplace)

				} else {
					LoginSignupView()
						.environmentObject(networkManager)
						.transition(.blurReplace)
				}
			}
		}
	}
}
