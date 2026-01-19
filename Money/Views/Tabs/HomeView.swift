//
//  HomeView.swift
//  Money
//
//  Created by Adon Omeri on 19/1/2026.
//

import SwiftData
import SwiftUI

struct HomeView: View {
	@EnvironmentObject var networkManager: NetworkManager

	@State private var didSyncOnce = false

	@State private var rotateTrigger = 0

	@Environment(\.modelContext) private var modelContext
	@Query(sort: \Transaction.dateCreated, order: .reverse)
	private var transactions: [Transaction]

	var total: Int {
		transactions.reduce(into: 0) { result, transaction in
			result += transaction.change
		}
	}

	@State private var isLoading = false
	@State private var showSuccess = false
	@State private var errorMessage: String?

	private var iconName: String {
		if isLoading {
			return "arrow.trianglehead.2.clockwise.rotate.90"
		}
		if showSuccess {
			return "checkmark"
		}
		return "arrow.trianglehead.2.clockwise.rotate.90"
	}

	@State var showAddTransaction = false

	var body: some View {
		NavigationStack {
			VStack {
				Text(total.formatted(.currency(code: "AUD")))
					.padding(.horizontal)
					.font(.system(size: 300))
					.lineLimit(1)
					.minimumScaleFactor(0.01)
					.contentTransition(.numericText())
					.task {
						if !didSyncOnce {
							didSyncOnce = true
							await loadTransactions()
						}
					}
			}
			.frame(maxWidth: .infinity, maxHeight: .infinity)
			.ignoresSafeArea()
			.background {
				if total < 0 {
					Rectangle()
						.fill(
							LinearGradient(
								stops: [
									.init(color: Color.red, location: 0),
									.init(color: Color.red.opacity(0.0), location: 1),
								],
								startPoint: .top,
								endPoint: .bottom
							)
						)
						.ignoresSafeArea()
				} else {
					Color.clear
				}
			}
			.toolbar { toolbarContent }
			.toolbar {
				ToolbarItem(placement: .topBarTrailing) {
					Button {
						showAddTransaction = true
					} label: {
						Label("Add Transaction", systemImage: "plus")
					}
					.buttonStyle(.glassProminent)
				}

				ToolbarSpacer(placement: .topBarTrailing)

				ToolbarItem(placement: .topBarTrailing) {
					Button {
						Task {
							await loadTransactions()
						}
					} label: {
						Image(systemName: iconName)
							.contentTransition(.symbolEffect(.replace))
					}
					.animation(.easeInOut, value: "\(isLoading)\(showSuccess)")
					.disabled(isLoading)
				}
			}
			.sheet(isPresented: $showAddTransaction, onDismiss: { Task { await loadTransactions() }}) {
				TransactionDetailView(isNew: true)
					.environmentObject(networkManager)
					.presentationDetents([.large])
					.presentationDragIndicator(.hidden)
			}
		}
	}

	func loadTransactions() async {
		await MainActor.run {
			isLoading = true
			showSuccess = false
		}

		do {
			let fetched = try await networkManager.fetchTransactions()

			for t in fetched {
				if let existing = transactions.first(where: { $0.id == t.id }) {
					if existing.change != t.change ||
						existing.title != t.title ||
						existing.desc != t.description ||
						existing.importance != t.importance ||
						existing.dateCreated != t.dateCreated
					{
						existing.change = t.change
						existing.title = t.title
						existing.desc = t.description
						existing.importance = t.importance
						existing.dateCreated = t.dateCreated
					}
				} else {
					let entity = Transaction(
						id: t.id,
						change: t.change,
						title: t.title,
						desc: t.description,
						importance: t.importance,
						dateCreated: t.dateCreated
					)
					modelContext.insert(entity)
				}
			}

			isLoading = false
			showSuccess = true

			try? await Task.sleep(for: .seconds(1.5))

			showSuccess = false

		} catch {
			isLoading = false
			errorMessage = error.localizedDescription
		}
	}
}
