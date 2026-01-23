
import SwiftUI

struct ListView: View {
	@EnvironmentObject var transactionRepo: TransactionRepository

	@State private var isLoading = false
	@State private var showSuccess = false
	@State private var errorMessage: String?

	var body: some View {
		NavigationStack {
			ZStack {
				if transactionRepo.transactions.isEmpty {
					ContentUnavailableView("No Transactions", systemImage: "camera.metering.none")
						.transition(.blurReplace)
				} else {
					List {
						ForEach(transactionRepo.transactions) { transaction in
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
							.transition(.blurReplace)
						}
						.onDelete { indexSet in
							let ids = indexSet.map { transactionRepo.transactions[$0].id }

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
			.animation(.easeInOut, value: transactionRepo.transactions.isEmpty)
			.toolbar { toolbarContent }
			.toolbar {
				#if os(iOS)
					if !transactionRepo.transactions.isEmpty {
						ToolbarItem(placement: .topBarTrailing) {
							EditButton()
						}

						ToolbarSpacer(placement: .topBarTrailing)
					}
				#endif // os(iOS)

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
			Task {
				try? await Task.sleep(for: .seconds(1))
				showSuccess = false
			}
			isLoading = false
		} catch {
			isLoading = false
			errorMessage = error.localizedDescription
		}
	}
}
