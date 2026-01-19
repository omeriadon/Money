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

	@Environment(\.modelContext) private var modelContext
	@Query(sort: \Transaction.dateCreated, order: .reverse)
	private var transactions: [Transaction]

	var total: Int {
		transactions.reduce(into: 0) { result, transaction in
			result += transaction.change
		}
	}

	@State private var isLoading = false
	@State private var errorMessage: String?

	@State var showAddTransaction = false

	var body: some View {
		NavigationStack {
			VStack {
				Text(total.formatted(.currency(code: "AUD")))
					.font(.largeTitle.scaled(by: 2))
					.contentTransition(.numericText())
					.task {
						if !didSyncOnce {
							didSyncOnce = true
							await loadTransactions()
						}
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
						Label("Sync", systemImage: "arrow.trianglehead.2.clockwise.rotate.90")
					}
				}
			}

			.sheet(isPresented: $showAddTransaction) {
				AddTransactionView()
					.environmentObject(networkManager)
					.presentationDetents([.large])
					.presentationDragIndicator(.hidden)
			}
		}
	}

	func loadTransactions() async {
		isLoading = true
		do {
			let fetched = try await networkManager.fetchTransactions()

			for t in fetched {
				if !transactions.contains(where: { $0.id == t.id }) {
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
		} catch {
			errorMessage = error.localizedDescription
		}
		isLoading = false
	}
}

#Preview {
	HomeView()
}
