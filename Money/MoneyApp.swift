//
//  MoneyApp.swift
//  Money
//
//  Created by Adon Omeri on 17/1/2026.
//

import SwiftUI
import Defaults

@main
struct MoneyApp: App {
	@StateObject private var networkManager = NetworkManager.shared
	@State private var isLoggedIn: Bool = (Defaults[.userToken] as String?) != nil

	var body: some Scene {
		WindowGroup {
			if isLoggedIn {
				ContentView()
					.environmentObject(networkManager)

			} else {
				LoginSignupView()
					.environmentObject(networkManager)

			}
		}
	}
}
