import Combine
import Foundation

@MainActor
final class TransactionRepository: ObservableObject {
	@Published private(set) var transactions: [Transaction] = []
	private let network: NetworkManager
	private let key = "transactions"

	init(network: NetworkManager) {
		self.network = network
		load()
	}

	private func load() {
		if let data = UserDefaults.standard.data(forKey: key),
		   let decoded = try? JSONDecoder().decode([Transaction].self, from: data)
		{
			transactions = decoded
		}
	}

	private func save() {
		if let encoded = try? JSONEncoder().encode(transactions) {
			UserDefaults.standard.set(encoded, forKey: key)
		}
	}

	func syncTransactions() async throws {
		let remote = try await network.fetchTransactions()
		// Merge remote into local
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
		save()
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
		save()
	}

	func updateTransaction(id: UUID, change: Double? = nil, title: String? = nil, description: String? = nil, importance: Importance? = nil) async throws {
		let remote = try await network.updateTransaction(id: id, change: change, title: title, description: description, importance: importance)
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
		save()
	}

	func delete(ids: [UUID]) async throws {
		transactions.removeAll { ids.contains($0.id) }
		_ = try await network.deleteTransactions(ids: ids)
		save()
	}

	#if os(iOS)
		func logout() async throws {
			try await network.logout()
			transactions.removeAll()
			save()
		}

		func deleteUser() async throws {
			try await network.deleteCurrentUser()
			transactions.removeAll()
			save()
		}
	#endif // os(iOS)
}
