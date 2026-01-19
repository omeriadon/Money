//
//  ListView.swift
//  Money
//
//  Created by Adon Omeri on 19/1/2026.
//

import SwiftUI
import SwiftData

struct ListView: View {
	@Environment(\.modelContext) private var modelContext
	@Query(sort: \Transaction.dateCreated, order: .reverse)
	private var transactions: [Transaction]

    var body: some View {
		NavigationStack {
			List {
				ForEach(transactions) { transaction in
					Text(transaction.title)
				}
			}
			
		}
    }
}

#Preview {
    ListView()
}
