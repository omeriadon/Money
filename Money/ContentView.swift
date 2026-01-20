import SwiftUI
import PortalTransitions

struct ContentView: View {
	@EnvironmentObject var transactionRepo: TransactionRepository

	var body: some View {
		PortalContainer {
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
				
				Tab {
					SettingsView()
				} label: {
					Label("Settings", systemImage: "gearshape")
				}
			}
		}
	}
}
