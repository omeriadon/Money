//
//  ListView.swift
//  Money
//
//  Created by Adon Omeri on 19/1/2026.
//

import SwiftData
import SwiftUI

struct ListView: View {
	@EnvironmentObject var networkManager: NetworkManager

	@Environment(\.modelContext) private var modelContext
	@Query(sort: \Transaction.dateCreated, order: .reverse)
	private var transactions: [Transaction]

	@State private var isLoading = false
	@State private var showSuccess = false
	@State private var errorMessage: String?

	var body: some View {
		NavigationStack {
			List {
				ForEach(transactions) { transaction in
					NavigationLink {
						TransactionDetailView(isNew: false, transaction: transaction)
					} label: {
						HStack {
							Text(transaction.title)
							Image(systemName: transaction.importance.symbol)

							Spacer()

							Text(transaction.change, format: .currency(code: "AUD"))
								.foregroundStyle(transaction.change > 0 ? .green : .red)
								.font(.title3)
								.lineLimit(1)
								.minimumScaleFactor(0.01)
						}
					}
				}
				.onDelete { indexSet in
					let ids = indexSet.map { transactions[$0].id }

					Task {
						let _ = try await NetworkManager.shared.deleteTransactions(ids: ids)
						await loadTransactions()
					}
				}
			}
			.toolbar { toolbarContent }
			.toolbar {
				ToolbarItem(placement: .primaryAction) {
					EditButton()
				}
				ToolbarItem(placement: .topBarTrailing) {
					RefreshButton(isLoading: $isLoading, showSuccess: $showSuccess) {
						await loadTransactions()
					}
				}
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

#Preview {
	ListView()
}
