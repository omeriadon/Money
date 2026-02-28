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
		applyRemoteTransactions(remote)
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

		applyRemoteTransactions(remote)
	}

	func updateTransaction(id: UUID, change: Double? = nil, title: String? = nil, description: String? = nil, importance: Importance? = nil) async throws {
		let remote = try await network.updateTransaction(
			id: id,
			change: change,
			title: title,
			description: description,
			importance: importance
		)
		let t = Transaction(from: remote)

		if let index = _transactions.firstIndex(where: { $0.id == remote.id }) {
			_transactions[index] = t
		} else {
			_transactions.append(t)
		}

		persistTransactions()
	}

	func delete(ids: [UUID]) async throws {
		let remaining = try await network.deleteTransactions(ids: ids)
		applyRemoteTransactions(remaining)
	}

	#if os(iOS)
		func logout() async throws {
			try await network.logout()
			_transactions.removeAll()
			persistTransactions()
			Defaults[.goals] = []
			GoalGaugeWidgetStore.saveGoals([])
		}

		func deleteUser() async throws {
			try await network.deleteCurrentUser()
			_transactions.removeAll()
			persistTransactions()
			Defaults[.goals] = []
			GoalGaugeWidgetStore.saveGoals([])
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

	private func applyRemoteTransactions(_ remote: [TransactionDTO]) {
		_transactions = remote.map(Transaction.init(from:))
		persistTransactions()
	}

	private func persistTransactions() {
		Defaults[.transactions] = _transactions
		GoalGaugeWidgetStore.saveTransactions(_transactions)
	}
}
