//
//  ContentView.swift
//  Money
//
//  Created by Adon Omeri on 17/1/2026.
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
				SettingsView()
			} label: {
				Label("Settings", systemImage: "gearshape")
			}
		}
    }
}

#Preview {
    ContentView()
}
