//
//  ListGoalsIntent.swift
//  Money
//
//  Created by Adon Omeri on 1/3/2026.
//

import AppIntents
import Foundation

enum GoalSortFieldEnum: String, AppEnum {
	case date
	case amount
	case name

	static var typeDisplayRepresentation: TypeDisplayRepresentation = "Sort By"
	static var caseDisplayRepresentations: [GoalSortFieldEnum: DisplayRepresentation] = [
		.date: "Date",
		.amount: "Amount",
		.name: "Name",
	]
}

struct ListGoalsIntent: AppIntent {
	static var title: LocalizedStringResource = "List Goals"
	static var openAppWhenRun: Bool = false

	@Parameter(title: "Min Amount")
	var minAmount: Double?

	@Parameter(title: "Max Amount")
	var maxAmount: Double?

	@Parameter(title: "Sort By")
	var sortBy: GoalSortFieldEnum?

	@Parameter(title: "Sort Direction")
	var sortDirection: TransactionSortDirectionEnum?

	@Parameter(title: "Limit")
	var limit: Int?

	@MainActor
	func perform() async throws -> some IntentResult & ReturnsValue<[GoalEntity]> {
		var results = GoalRepository.shared.goals

		if let minAmount {
			results = results.filter { $0.goalAmount >= minAmount }
		}
		if let maxAmount {
			results = results.filter { $0.goalAmount <= maxAmount }
		}

		let field = sortBy ?? .date
		let ascending = sortDirection == .ascending
		results = results.sorted {
			switch field {
				case .date:
					ascending ? $0.dateCreated < $1.dateCreated : $0.dateCreated > $1.dateCreated
				case .amount:
					ascending ? $0.goalAmount < $1.goalAmount : $0.goalAmount > $1.goalAmount
				case .name:
					ascending ? $0.name < $1.name : $0.name > $1.name
			}
		}

		let cap = min(limit ?? 50, 100)
		return .result(value: Array(results.prefix(cap)).map(GoalEntity.init(from:)))
	}
}
