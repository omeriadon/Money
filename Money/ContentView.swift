import Defaults
import SwiftUI
import UIKit

struct ContentView: View {
	@Environment(TransactionRepository.self) var transactionRepo
	@Environment(GoalRepository.self) var goalRepo

	@State private var showWhatsNewSheet = false

	let generator = UIImpactFeedbackGenerator(style: .medium)

	@Default(.showAnalyseTab) var showAnalyseTab
	@Default(.showGoalsTab) var showGoalsTab
	@Default(.whatsNewSeenState) var whatsNewSeenState
	@Default(.tab) var tab

	var body: some View {
		tabView
			.onChange(of: tab) {
				generator.impactOccurred(intensity: 1)
				generator.prepare()
			}
			.onAppear {
				generator.prepare()
				presentWhatsNewIfNeeded()
			}
			.onChange(of: whatsNewSeenState) { _, newValue in
				switch newValue {
					case .resetRequested:
						presentWhatsNewIfNeeded()
					case let .release(shownRelease):
						if let currentRelease = WhatsNewReleaseCatalog.currentRelease,
						   shownRelease < currentRelease
						{
							presentWhatsNewIfNeeded()
						}
					default:
						break
				}
			}
			.task {
				await transactionRepo.network.refreshCurrentUser()
				try? await goalRepo.syncGoals()
			}
			.sheet(isPresented: $showWhatsNewSheet, onDismiss: handleWhatsNewSheetDismiss) {
				if let release = WhatsNewReleaseCatalog.currentRelease,
				   let items = WhatsNewReleaseCatalog.items(for: release)
				{
					WhatsNewSheetView(
						release: release,
						items: items,
						showSheet: $showWhatsNewSheet
					)
					.interactiveDismissDisabled()
					.presentationDetents([.large])
				}
			}
		#if os(iOS)
			.enableInjection()
		#endif
	}

	#if DEBUG && os(iOS)
		@ObserveInjection var forceRedraw
	#endif

	var tabView: some View {
		TabView(selection: $tab) {
			Tab(value: "Home") {
				HomeView()
			} label: {
				Label("Home", systemImage: "house")
			}

			if showGoalsTab {
				Tab(value: "Goals") {
					GoalListView()
				} label: {
					Label("Goals", systemImage: "target")
				}
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
				TransactionListView()
			} label: {
				Label("Transactions", systemImage: "mail.stack")
			}
		}
	}

	private func presentWhatsNewIfNeeded() {
		guard let currentRelease = WhatsNewReleaseCatalog.currentRelease else { return }

		switch whatsNewSeenState {
			case let .release(shownRelease) where shownRelease >= currentRelease:
				return
			default:
				break
		}

		guard WhatsNewReleaseCatalog.items(for: currentRelease)?.isEmpty == false else { return }
		showWhatsNewSheet = true
	}

	private func handleWhatsNewSheetDismiss() {
		if let release = WhatsNewReleaseCatalog.currentRelease {
			whatsNewSeenState = .release(release)
		}
	}
}
