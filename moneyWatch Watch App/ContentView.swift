//
//  ContentView.swift
//  moneyWatch Watch App
//
//  Created by Adon Omeri on 21/1/2026.
//

import SwiftUI

struct ContentView: View {
	var body: some View {
		TabView {
			Tab {
				HomeView()

			} label: {
				Label("Money", systemImage: "house")
			}

			Tab {
				ListView()

			} label: {
				Label("Transactions", systemImage: "mail.stack")
			}
		}
		.tabViewStyle(.carousel)
	}
}

#Preview {
	ContentView()
}
