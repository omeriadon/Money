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

	var body: some View {
		TabView {
			Tab {
				HomeView()

			} label: {
				Label("Money", systemImage: "house")
			}

			if showGoalsTab {
				Tab {
					GoalListView()

				} label: {
					Label("Goals", systemImage: "target")
				}
			}

			Tab {
				ListView()

			} label: {
				Label("Transactions", systemImage: "mail.stack")
			}
		}
		.tabViewStyle(.verticalPage)
	}
}

#Preview {
	ContentView()
}
