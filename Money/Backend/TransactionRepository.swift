//
//  TransactionRepository.swift
//  Money
//
//  Created by Adon Omeri on 20/1/2026.
//

import Combine
import Foundation
import SwiftData

@MainActor
final class TransactionRepository: ObservableObject {
	private(set) var context: ModelContext
	private let network: NetworkManager

	init(context: ModelContext, network: NetworkManager) {
		self.context = context
		self.network = network
	}

	func syncTransactions() async throws {
		let remote = try await network.fetchTransactions()
		let local = try context.fetch(FetchDescriptor<Transaction>())

		for r in remote {
			if let existing = local.first(where: { $0.id == r.id }) {
				existing.update(from: r)
			} else {
				context.insert(Transaction(from: r))
			}
		}
	}

	func delete(ids: [UUID]) async throws {
		let snapshot = try? context.fetch(FetchDescriptor<Transaction>())

		do {
			for tx in snapshot ?? [] where ids.contains(tx.id) {
				context.delete(tx)
			}
			_ = try await network.deleteTransactions(ids: ids)
		} catch {
			try? await syncTransactions()
			throw error
		}
	}

	func createTransaction(
		change: Double,
		title: String,
		description: String,
		importance: Importance
	) async throws {
		let remote = try await network.createTransaction(
			change: change,
			title: title,
			description: description,
			importance: importance
		)

		let local = try context.fetch(FetchDescriptor<Transaction>())
		for r in remote {
			if let existing = local.first(where: { $0.id == r.id }) {
				existing.update(from: r)
			} else {
				context.insert(Transaction(from: r))
			}
		}
	}

	func updateTransaction(
		id: UUID,
		change: Double? = nil,
		title: String? = nil,
		description: String? = nil,
		importance: Importance? = nil
	) async throws {
		let remote = try await network.updateTransaction(
			id: id,
			change: change.map(Int.init),
			title: title,
			description: description,
			importance: importance
		)

		if let local = try context.fetch(FetchDescriptor<Transaction>())
			.first(where: { $0.id == remote.id })
		{
			local.update(from: remote)
		} else {
			context.insert(Transaction(from: remote))
		}
	}
}
