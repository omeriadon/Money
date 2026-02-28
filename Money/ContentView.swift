import Defaults
import SwiftUI
import UIKit

struct ContentView: View {
	@EnvironmentObject var transactionRepo: TransactionRepository
	@EnvironmentObject var goalRepo: GoalRepository

	@State var currentTab = "Home"
	@State private var showWhatsNewSheet = false
	@State private var pendingWhatsNewRelease: WhatsNewRelease?
	@State private var pendingWhatsNewItems: [WhatsNewItem] = []

	let generator = UIImpactFeedbackGenerator(style: .medium)

	@Default(.showAnalyseTab) var showAnalyseTab
	@Default(.showGoalsTab) var showGoalsTab
	@Default(.whatsNewSeenState) var whatsNewSeenState

	var body: some View {
		tabView
			.onChange(of: currentTab) {
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
							shownRelease < currentRelease {
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
				whatsNewSheet
			}
	}

	var tabView: some View {
		TabView(selection: $currentTab) {
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
				ListView()
			} label: {
				Label("Transactions", systemImage: "mail.stack")
			}
		}
	}

	@ViewBuilder
	private var whatsNewSheet: some View {
		if let release = pendingWhatsNewRelease {
			WhatsNewSheetView(
				release: release,
				items: pendingWhatsNewItems,
				onDismiss: dismissWhatsNew
			)
			.presentationDetents([.large])
		} else {
			EmptyView()
		}
	}

	private func presentWhatsNewIfNeeded() {
		print("starting")

		#if DEBUG
			if ProcessInfo.processInfo.arguments.contains("-reset-whats-new") {
				whatsNewSeenState = .resetRequested
			}
		#endif

		guard let currentRelease = WhatsNewReleaseCatalog.currentRelease else { return }
		print(currentRelease)
		guard let items = WhatsNewReleaseCatalog.items(for: currentRelease), !items.isEmpty else { return }
		print(items)

		var shouldPresent = false
		switch whatsNewSeenState {
			case let .release(shownRelease) where shownRelease == currentRelease:
				print("same")
				shouldPresent = false
			case let .release(shownRelease) where shownRelease < currentRelease:
				print("unseen")
				shouldPresent = true
			case .unseen, .resetRequested:
				print("unseen")
				shouldPresent = true
			default:
				shouldPresent = false
		}

		if shouldPresent {
			pendingWhatsNewRelease = currentRelease
			pendingWhatsNewItems = items
			showWhatsNewSheet = true
		}
	}

	private func dismissWhatsNew() {
		print("dismissWhatsNew")
		showWhatsNewSheet = false
	}

	private func handleWhatsNewSheetDismiss() {
		print("handleWhatsNewSheetDismiss")
		markPendingReleaseAsSeen()
		clearPendingRelease()
	}

	private func clearPendingRelease() {
		pendingWhatsNewRelease = nil
		pendingWhatsNewItems = []
	}

	private func markPendingReleaseAsSeen() {
		print("markPendingReleaseAsSeen \(whatsNewSeenState)")
		if let release = pendingWhatsNewRelease {
			whatsNewSeenState = .release(release)
		}
	}
}

