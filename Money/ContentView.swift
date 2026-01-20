//
//  ContentView.swift
//  Money
//
//  Created by Adon Omeri on 17/1/2026.
//

import SwiftUI

struct ContentView: View {
	@Environment(\.modelContext) private var modelContext
	@EnvironmentObject var networkManager: NetworkManager

	@StateObject private var repo: TransactionRepository

	init() {
		// repo must be created on main actor, but @StateObject handles that
		_repo = StateObject(wrappedValue: TransactionRepository(
			context: nil, // temporarily nil, will fix in body
			network: networkManager
		))
	}

	var body: some View {
		// Now we have modelContext, assign it if needed
		let _ = repo.context = modelContext

		TabView {
			Tab {
				HomeView()
					.environmentObject(repo) // inject repo, not networkManager

			} label: {
				Label("Money", systemImage: "house")
			}

			Tab {
				ListView()
					.environmentObject(repo) // inject repo

			} label: {
				Label("Transactions", systemImage: "mail.stack")
			}

			Tab {
				SettingsView()
					.environmentObject(networkManager) // still only needs auth
			} label: {
				Label("Settings", systemImage: "gearshape")
			}
		}
	}
}

#Preview {
	ContentView()
}
