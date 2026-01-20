//
//  SettingsView.swift
//  Money
//
//  Created by Adon Omeri on 19/1/2026.
//

import SwiftUI

struct SettingsView: View {
	@EnvironmentObject var transactionRepo: TransactionRepository

	@State private var showAlert = false
	@State private var errorMessage = ""
	@State private var errorTitle = ""

	@State var showLogoutConfirmation = false
	@State var showDeleteAccountConfirmation = false

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
									try await transactionRepo.logout()
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
					Button {
						showDeleteAccountConfirmation = true
					} label: {
						Label("Delete Account", systemImage: "trash")
							.foregroundStyle(.red)
					}
					.alert("Are you sure you want to delete your account?", isPresented: $showDeleteAccountConfirmation) {
						Button(role: .destructive) {
							Task {
								do {
									try await transactionRepo.deleteUser()
								} catch {
									errorTitle = "Failed to Delete Account"
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
					} message: {
						Text("This will permanently delete all your transactions.")
					}
				}
			}
			.toolbar { toolbarContent }
			.alert(errorTitle, isPresented: $showAlert, actions: {
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
