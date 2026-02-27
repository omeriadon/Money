import Combine
import Defaults
import Foundation

@MainActor
final class TransactionRepository: ObservableObject {
	@Published private var _transactions: [Transaction] = Defaults[.transactions]

	var transactions: [Transaction] {
		_transactions.sorted { $0.dateCreated > $1.dateCreated }
	}

	let network: NetworkManager
	private var cancellables = Set<AnyCancellable>()

	init(network: NetworkManager) {
		self.network = network

		Defaults.publisher(.transactions)
			.sink { [weak self] change in
				self?._transactions = change.newValue
			}
			.store(in: &cancellables)
	}

	func syncTransactions() async throws {
		let remote = try await network.fetchTransactions()

		_transactions = remote.map {
			Transaction(
				id: $0.id,
				change: $0.change,
				title: $0.title,
				desc: $0.description,
				importance: $0.importance,
				dateCreated: $0.dateCreated,
				dateUpdated: $0.dateUpdated
			)
		}

		Defaults[.transactions] = _transactions
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

		_transactions = remote.map {
			Transaction(
				id: $0.id,
				change: $0.change,
				title: $0.title,
				desc: $0.description,
				importance: $0.importance,
				dateCreated: $0.dateCreated,
				dateUpdated: $0.dateUpdated
			)
		}

		Defaults[.transactions] = _transactions
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

		if let index = _transactions.firstIndex(where: { $0.id == remote.id }) {
			_transactions[index] = t
		} else {
			_transactions.append(t)
		}

		Defaults[.transactions] = _transactions
	}

	func delete(ids: [UUID]) async throws {
		_transactions.removeAll { ids.contains($0.id) }
		Defaults[.transactions] = _transactions

		let remaining = try await network.deleteTransactions(ids: ids)
		_transactions = remaining.map {
			Transaction(
				id: $0.id,
				change: $0.change,
				title: $0.title,
				desc: $0.description,
				importance: $0.importance,
				dateCreated: $0.dateCreated,
				dateUpdated: $0.dateUpdated
			)
		}
		Defaults[.transactions] = _transactions
	}

	#if os(iOS)
		func logout() async throws {
			try await network.logout()
			_transactions.removeAll()
			Defaults[.transactions] = _transactions
			Defaults[.goals] = []
		}

		func deleteUser() async throws {
			try await network.deleteCurrentUser()
			_transactions.removeAll()
			Defaults[.transactions] = _transactions
			Defaults[.goals] = []
		}
	#endif // os(iOS)

	#if os(iOS)
		func updateUser(firstName: String?, email: String?, password: String?) async throws {
			let updatedUser = try await network.updateCurrentUser(firstName: firstName, email: email, password: password)

			// Update local defaults
			network.firstName = updatedUser.firstName
			network.email = updatedUser.email
		}
	#endif // os(iOS)
}
