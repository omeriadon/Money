import Defaults
import SwiftUI

struct ContentView: View {
	@EnvironmentObject var transactionRepo: TransactionRepository

	@State var currentTab = "Home"

	let generator = UIImpactFeedbackGenerator(style: .medium)

	@Default(.showAnalyseTab) var showAnalyseTab

	var body: some View {
		TabView(selection: $currentTab) {
			Tab(value: "Home") {
				HomeView()
			} label: {
				Label("Home", systemImage: "house")
			}

			if showAnalyseTab {
				Tab(value: "Analyse") {
					AnalyseView()
				} label: {
					Label("Analyse", systemImage: "chart.xyaxis.line")
				}
			}

			Tab(value: "Settings") {
				SettingsView()
			} label: {
				Label("Settings", systemImage: "gearshape")
			}

			Tab(value: "Search", role: .search) {
				ListView()
			} label: {
				Label("Transactions", systemImage: "mail.stack")
			}
		}
		.onChange(of: currentTab) {
			generator.impactOccurred(intensity: 1)
			generator.prepare()
		}
		.onAppear {
			generator.prepare()
		}
		.task {
			await transactionRepo.network.refreshCurrentUser()
		}
	}
}
