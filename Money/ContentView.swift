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
			.onChange(of: whatsNewSeenState) {
				if !showWhatsNewSheet {
					presentWhatsNewIfNeeded()
				}
			}
			.task {
				await transactionRepo.network.refreshCurrentUser()
				try? await goalRepo.syncGoals()
			}
			.sheet(isPresented: $showWhatsNewSheet, onDismiss: clearPendingRelease) {
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
		guard let items = WhatsNewReleaseCatalog.items(for: currentRelease), !items.isEmpty else { return }

		switch whatsNewSeenState {
			case let .release(shownRelease) where shownRelease == currentRelease:
				return
			case .unseen, .resetRequested, .release:
				pendingWhatsNewRelease = currentRelease
				pendingWhatsNewItems = items
				showWhatsNewSheet = true
		}
	}

	private func dismissWhatsNew() {
		if let release = pendingWhatsNewRelease {
			whatsNewSeenState = .release(release)
		}
		showWhatsNewSheet = false
		clearPendingRelease()
	}

	private func clearPendingRelease() {
		pendingWhatsNewRelease = nil
		pendingWhatsNewItems = []
	}
}

private struct WhatsNewSheetView: View {
	let release: WhatsNewRelease
	let items: [WhatsNewItem]
	let onDismiss: () -> Void

	var body: some View {
		VStack(alignment: .leading, spacing: 16) {
			Text("What's New")
				.font(.title2.bold())

			Text("Version \(release.version) (\(release.build))")
				.font(.subheadline)
				.foregroundStyle(.secondary)

			ScrollView {
				VStack(alignment: .leading, spacing: 14) {
					ForEach(items) { item in
						HStack(alignment: .top, spacing: 12) {
							Image(systemName: item.symbolName)
								.frame(width: 24)
							VStack(alignment: .leading, spacing: 4) {
								Text(item.title).font(.headline)
								Text(item.description).font(.subheadline)
							}
						}
					}
				}
			}

			Button("OK") {
				onDismiss()
			}
			.frame(maxWidth: .infinity)
			.padding(.top, 4)
		}
		.padding()
	}
}
