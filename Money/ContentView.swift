//
//  ContentView.swift
//  Money
//
//  Created by Adon Omeri on 17/1/2026.
//

import SwiftUI

struct ContentView: View {
	@EnvironmentObject var networkManager: NetworkManager

	var body: some View {
		TabView {
			Tab {
				HomeView()
					.environmentObject(networkManager)

			} label: {
				Label("Money", systemImage: "house")
			}
			Tab {
				ListView()
					.environmentObject(networkManager)

			} label: {
				Label("Transactions", systemImage: "mail.stack")
			}
			Tab {
				SettingsView()
					.environmentObject(networkManager)
			} label: {
				Label("Settings", systemImage: "gearshape")
			}
		}
	}
}

#Preview {
	ContentView()
}

@ToolbarContentBuilder
var toolbarContent: some ToolbarContent {
	ToolbarItem(placement: .title) {
		Text("Money")
	}

	ToolbarItem(placement: .topBarLeading) {
		HStack {
			LinearGradient(
				colors: [Color.yellow, Color.yellow.opacity(0.8)],
				startPoint: .top,
				endPoint: .bottom
			)
			.mask(
				Image("Logo")
					.renderingMode(.template)
					.resizable()
					.aspectRatio(contentMode: .fit)
			)
			.frame(width: 35, height: 35)
		}
	}
	.sharedBackgroundVisibility(.hidden)
}
