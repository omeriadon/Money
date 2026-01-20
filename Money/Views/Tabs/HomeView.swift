import SwiftData
import SwiftUI

struct HomeView: View {
	@EnvironmentObject var transactionRepo: TransactionRepository

	@Query(sort: \Transaction.dateCreated, order: .reverse)
	private var transactions: [Transaction]

	var total: Double {
		transactions.reduce(0) { $0 + $1.change }
	}

	@State private var didSyncOnce = false
	@State private var isLoading = false
	@State private var showSuccess = false
	@State private var errorMessage: String?
	@State private var showAddTransaction = false

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
							await refresh()
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
			}
			
			ToolbarSpacer(.fixed, placement: .topBarTrailing)
			

			ToolbarItem(placement: .topBarTrailing) {
				RefreshButton(isLoading: $isLoading, showSuccess: $showSuccess) {
					await refresh()
				}
			}
		}
		.sheet(isPresented: $showAddTransaction) {
			TransactionDetailView(isNew: true)
				.presentationDragIndicator(.hidden)
		}
	}
	}

	private func refresh() async {
		do {
			try await transactionRepo.syncTransactions()
		} catch {
			errorMessage = error.localizedDescription
		}
	}
}
