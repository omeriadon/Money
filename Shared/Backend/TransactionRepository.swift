import Combine
import Defaults
import Foundation

@MainActor
final class TransactionRepository: ObservableObject {
	@Published private(set) var transactions: [Transaction] = Defaults[.transactions]
	private let network: NetworkManager

	init(network: NetworkManager) {
		self.network = network

		// Observe changes in Defaults (optional, for auto-syncing if needed)
		Defaults.publisher(.transactions)
			.sink { [weak self] change in
				self?.transactions = change.newValue
			}
			.store(in: &cancellables)
	}

	private var cancellables = Set<AnyCancellable>()

	func syncTransactions() async throws {
		let remote = try await network.fetchTransactions()
		for r in remote {
			let t = Transaction(
				id: r.id,
				change: r.change,
				title: r.title,
				desc: r.description,
				importance: r.importance,
				dateCreated: r.dateCreated,
				dateUpdated: r.dateUpdated
			)
			if let index = transactions.firstIndex(where: { $0.id == r.id }) {
				transactions[index] = t
			} else {
				transactions.append(t)
			}
		}
		Defaults[.transactions] = transactions
	}

	func createTransaction(change: Double, title: String, description: String, importance: Importance) async throws {
		let remote = try await network.createTransaction(
			change: change,
			title: title,
			description: description,
			importance: importance
		)
		for r in remote {
			let t = Transaction(
				id: r.id,
				change: r.change,
				title: r.title,
				desc: r.description,
				importance: r.importance,
				dateCreated: r.dateCreated,
				dateUpdated: r.dateUpdated
			)
			if let index = transactions.firstIndex(where: { $0.id == r.id }) {
				transactions[index] = t
			} else {
				transactions.append(t)
			}
		}
		Defaults[.transactions] = transactions
	}

	func updateTransaction(id: UUID, change: Double? = nil, title: String? = nil, description: String? = nil, importance: Importance? = nil) async throws {
		let remote = try await network.updateTransaction(
			id: id,
			change: change,
			title: title,
			description: description,
			importance: importance
		)
		let t = Transaction(
			id: remote.id,
			change: remote.change,
			title: remote.title,
			desc: remote.description,
			importance: remote.importance,
			dateCreated: remote.dateCreated,
			dateUpdated: remote.dateUpdated
		)
		if let index = transactions.firstIndex(where: { $0.id == remote.id }) {
			transactions[index] = t
		} else {
			transactions.append(t)
		}
		Defaults[.transactions] = transactions
	}

	func delete(ids: [UUID]) async throws {
		transactions.removeAll { ids.contains($0.id) }
		_ = try await network.deleteTransactions(ids: ids)
		Defaults[.transactions] = transactions
	}

	#if os(iOS)
		func logout() async throws {
			try await network.logout()
			transactions.removeAll()
			Defaults[.transactions] = transactions
		}

		func deleteUser() async throws {
			try await network.deleteCurrentUser()
			transactions.removeAll()
			Defaults[.transactions] = transactions
		}
	#endif
}
