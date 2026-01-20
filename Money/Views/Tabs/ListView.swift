import SwiftData
import SwiftUI

struct ListView: View {
	@EnvironmentObject var transactionRepo: TransactionRepository

	@Query(sort: \Transaction.dateCreated, order: .reverse)
	private var transactions: [Transaction]

	@State private var isLoading = false
	@State private var showSuccess = false
	@State private var errorMessage: String?

	var body: some View {
		NavigationStack {
			ZStack {
				if transactions.isEmpty {
					ContentUnavailableView("No Transactions", systemImage: "camera.metering.none")
						.transition(.blurReplace)
				} else {
					List {
						ForEach(transactions) { transaction in
							NavigationLink {
								TransactionDetailView(
									isNew: false,
									transaction: transaction
								)
							} label: {
								HStack {
									Text(transaction.title)
									Image(systemName: transaction.importance.symbol)

									Spacer()

									Text(
										transaction.change,
										format: .currency(code: "AUD")
									)
									.foregroundStyle(
										transaction.change > 0 ? .green : .red
									)
									.font(.title3)
									.lineLimit(1)
									.minimumScaleFactor(0.01)
								}
							}
						}
						.onDelete { indexSet in
							let ids = indexSet.map { transactions[$0].id }

							Task {
								do {
									try await transactionRepo.delete(ids: ids)
								} catch {
									errorMessage = error.localizedDescription
								}
							}
						}
					}
					.transition(.blurReplace)
				}
			}
			.animation(.easeInOut, value: transactions.isEmpty)
			.toolbar { toolbarContent }
			.toolbar {
				if !transactions.isEmpty {
					ToolbarItem(placement: .topBarTrailing) {
						EditButton()
					}

					ToolbarSpacer(placement: .topBarTrailing)
				}

				ToolbarItem(placement: .topBarTrailing) {
					RefreshButton(
						isLoading: $isLoading,
						showSuccess: $showSuccess
					) {
						await refresh()
					}
				}
			}
		}
	}

	private func refresh() async {
		do {
			isLoading = true
			try await transactionRepo.syncTransactions()
			showSuccess = true
			try? await Task.sleep(for: .seconds(1.2))
			showSuccess = false
			isLoading = false
		} catch {
			isLoading = false
			errorMessage = error.localizedDescription
		}
	}
}
