//
//  ContentView.swift
//  moneyWatch Watch App
//
//  Created by Adon Omeri on 21/1/2026.
//

import Defaults
import SwiftUI

struct ContentView: View {
	@Default(.showGoalsTab) private var showGoalsTab
	@Default(.tab) private var tab

	var body: some View {
		TabView(selection: $tab) {
			Tab(value: "Home") {
				HomeView()

			} label: {
				Label("Money", systemImage: "house")
			}

			if showGoalsTab {
				Tab(value: "Goals") {
					GoalListView()

				} label: {
					Label("Goals", systemImage: "target")
				}
			}

			Tab(value: "Search") {
				ListView()

			} label: {
				Label("Transactions", systemImage: "mail.stack")
			}
		}
		.tabViewStyle(.verticalPage)
		.onAppear {
			tab = normalizedTab(tab)
		}
		.onChange(of: tab) { _, newValue in
			let normalized = normalizedTab(newValue)
			if normalized != newValue {
				tab = normalized
			}
		}
		.onChange(of: showGoalsTab) {
			tab = normalizedTab(tab)
		}
	}

	private func normalizedTab(_ value: String) -> String {
		switch value {
			case "Home", "Search":
				value
			case "Goals":
				showGoalsTab ? "Goals" : "Home"
			case "Analyse", "Settings":
				"Search"
			default:
				"Home"
		}
	}
}

#Preview {
	ContentView()
}
