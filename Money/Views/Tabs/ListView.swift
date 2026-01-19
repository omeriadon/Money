//
//  ListView.swift
//  Money
//
//  Created by Adon Omeri on 19/1/2026.
//

import SwiftData
import SwiftUI

struct ListView: View {
	@Environment(\.modelContext) private var modelContext
	@Query(sort: \Transaction.dateCreated, order: .reverse)
	private var transactions: [Transaction]

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
						}
					}
				}
			}
			.toolbar { toolbarContent }
		}
	}
}

#Preview {
	ListView()
}
