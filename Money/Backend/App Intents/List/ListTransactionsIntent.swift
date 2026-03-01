//
//  ListTransactionsIntent.swift
//  Money
//
//  Created by Adon Omeri on 1/3/2026.
//

import AppIntents
import Foundation

enum TransactionSortFieldEnum: String, AppEnum {
	case date
	case amount
	case title

	static var typeDisplayRepresentation: TypeDisplayRepresentation = "Sort By"
	static var caseDisplayRepresentations: [TransactionSortFieldEnum: DisplayRepresentation] = [
		.date: "Date",
		.amount: "Amount",
		.title: "Title",
	]
}

enum TransactionSortDirectionEnum: String, AppEnum {
	case ascending
	case descending

	static var typeDisplayRepresentation: TypeDisplayRepresentation = "Sort Direction"
	static var caseDisplayRepresentations: [TransactionSortDirectionEnum: DisplayRepresentation] = [
		.ascending: "Ascending",
		.descending: "Descending",
	]
}

enum TransactionTypeFilterEnum: String, AppEnum {
	case income
	case expense

	static var typeDisplayRepresentation: TypeDisplayRepresentation = "Transaction Type"
	static var caseDisplayRepresentations: [TransactionTypeFilterEnum: DisplayRepresentation] = [
		.income: "Income",
		.expense: "Expense",
	]
}

struct ListTransactionsIntent: AppIntent {
	static var title: LocalizedStringResource = "List Transactions"
	static var openAppWhenRun: Bool = false

	@Parameter(title: "Category")
	var category: TransactionImportanceIntentEnum?

	@Parameter(title: "Type")
	var type: TransactionTypeFilterEnum?

	@Parameter(title: "From Date")
	var fromDate: Date?

	@Parameter(title: "To Date")
	var toDate: Date?

	@Parameter(title: "Min Amount")
	var minAmount: Double?

	@Parameter(title: "Max Amount")
	var maxAmount: Double?

	@Parameter(title: "Sort By")
	var sortBy: TransactionSortFieldEnum?

	@Parameter(title: "Sort Direction")
	var sortDirection: TransactionSortDirectionEnum?

	@Parameter(title: "Limit")
	var limit: Int?

	@MainActor
	func perform() async throws -> some IntentResult & ReturnsValue<[TransactionEntity]> {
		var results = TransactionRepository.shared.transactions

		if let category {
			results = results.filter { $0.importance == category.modelValue }
		}

		if let type {
			switch type {
				case .income:
					results = results.filter { Importance.positive.contains($0.importance) }
				case .expense:
					results = results.filter { Importance.negative.contains($0.importance) }
			}
		}

		if let fromDate {
			results = results.filter { $0.dateCreated >= fromDate }
		}
		if let toDate {
			results = results.filter { $0.dateCreated <= toDate }
		}

		if let minAmount {
			results = results.filter { abs($0.change) >= minAmount }
		}
		if let maxAmount {
			results = results.filter { abs($0.change) <= maxAmount }
		}

		let field = sortBy ?? .date
		let ascending = sortDirection == .ascending
		results = results.sorted {
			switch field {
				case .date:
					ascending ? $0.dateCreated < $1.dateCreated : $0.dateCreated > $1.dateCreated
				case .amount:
					ascending ? abs($0.change) < abs($1.change) : abs($0.change) > abs($1.change)
				case .title:
					ascending ? $0.title < $1.title : $0.title > $1.title
			}
		}

		let cap = min(limit ?? 20, 50)
		return .result(value: Array(results.prefix(cap)).map(TransactionEntity.init(from:)))
	}
}
