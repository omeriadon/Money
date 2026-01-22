import PortalTransitions
import SwiftUI

struct ContentView: View {
	@EnvironmentObject var transactionRepo: TransactionRepository

	@State var currentTab = TabItem.home

	let generator = UIImpactFeedbackGenerator(style: .medium)

	var body: some View {
		TabView(selection: $currentTab) {
			ForEach(TabItem.allCases) { tab in
				Tab(value: tab) {
					tab.view
				} label: {
					Label(tab.title, systemImage: tab.symbol)
				}
			}
		}
		.onChange(of: currentTab) {
			generator.impactOccurred(intensity: 1)
		}
		.onAppear {
			generator.prepare()
		}
	}
}

enum TabItem: CaseIterable, Identifiable {
	case home, list, settings

	var id: String { title }

	var title: String {
		switch self {
			case .home:
				"Money"
			case .list:
				"Transactions"
			case .settings:
				"Settings"
		}
	}

	@ViewBuilder
	var view: some View {
		switch self {
			case .home:
				HomeView()
			case .list:
				ListView()
			case .settings:
				SettingsView()
		}
	}

	var symbol: String {
		switch self {
			case .home:
				"house"
			case .list:
				"mail.stack"
			case .settings:
				"gearshape"
		}
	}
}
