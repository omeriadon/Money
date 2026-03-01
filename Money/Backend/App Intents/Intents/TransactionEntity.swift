//
//  TransactionEntity.swift
//  Money
//
//  Created by Adon Omeri on 1/3/2026.
//

import AppIntents
import Foundation

struct TransactionEntity: AppEntity {
	static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Transaction")
	static var defaultQuery = TransactionEntityQuery()

	let id: UUID
	let title: String
	let description: String
	let change: Double
	let importance: String
	let importanceTitle: String
	let dateCreated: Date
	let dateUpdated: Date

	var displayRepresentation: DisplayRepresentation {
		DisplayRepresentation(
			title: "\(title)",
			subtitle: "$\(String(format: "%.2f", change)) - \(importanceTitle)"
		)
	}
}

struct TransactionEntityQuery: EntityQuery {
	@MainActor
	func entities(for identifiers: [UUID]) async throws -> [TransactionEntity] {
		TransactionRepository.shared.transactions
			.filter { identifiers.contains($0.id) }
			.map(TransactionEntity.init(from:))
	}

	@MainActor
	func suggestedEntities() async throws -> [TransactionEntity] {
		Array(TransactionRepository.shared.transactions.prefix(50))
			.map(TransactionEntity.init(from:))
	}

	func defaultResult() async -> TransactionEntity? {
		try? await suggestedEntities().first
	}
}

extension TransactionEntity {
	init(from transaction: Transaction) {
		self.init(
			id: transaction.id,
			title: transaction.title,
			description: transaction.desc,
			change: transaction.change,
			importance: transaction.importance.rawValue,
			importanceTitle: transaction.importance.title,
			dateCreated: transaction.dateCreated,
			dateUpdated: transaction.dateUpdated
		)
	}
}
