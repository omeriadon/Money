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

	var body: some View {
		NavigationStack {
			VStack {
				Text(total.formatted(.currency(code: "AUD")))
					.font(.largeTitle.scaled(by: 2))
					.contentTransition(.numericText())
			}
			.task {
				await loadTransactions()
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
