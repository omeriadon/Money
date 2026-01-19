//
//  SettingsView.swift
//  Money
//
//  Created by Adon Omeri on 19/1/2026.
//

import SwiftUI

struct SettingsView: View {
	@EnvironmentObject var networkManager: NetworkManager

	@State private var showAlert = false
	@State private var errorMessage = ""
	@State private var errorTitle = ""

	@State var showLogoutConfirmation = false

	var body: some View {
		NavigationStack {
			List {
				Section("Account") {
					Button {
						showLogoutConfirmation = true
					} label: {
						Label("Logout", systemImage: "arrow.right.to.line")
					}
					.alert("Logout?", isPresented: $showLogoutConfirmation) {
						Button(role: .destructive) {
							Task {
								do {
									try await networkManager.logout()
								} catch {
									errorTitle = "Failed to Logout"
									errorMessage = error.localizedDescription
									showAlert = true
								}
							}
						} label: {
							Text("Yes")
						}

						Button(role: .cancel) {} label: {
							Text("No")
						}
					}
				}
			}
			.toolbar { toolbarContent }
			.alert("Failed To Logout", isPresented: $showAlert, actions: {
				Button("OK", role: .cancel) {}
			}, message: {
				Text(errorMessage)
			})
		}
	}
}

#Preview {
	SettingsView()
}
