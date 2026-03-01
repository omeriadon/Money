import Defaults
import Foundation
import Observation

@MainActor
@Observable
final class TransactionRepository {
	static let shared = TransactionRepository(network: NetworkManager.shared)

	private var _transactions: [Transaction] = Defaults[.transactions]

	var transactions: [Transaction] {
		_transactions.sorted { $0.dateCreated > $1.dateCreated }
	}

	let network: NetworkManager

	init(network: NetworkManager) {
		self.network = network
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

		var updatedTransactions = _transactions
		if let index = updatedTransactions.firstIndex(where: { $0.id == remote.id }) {
			updatedTransactions[index] = t
		} else {
			updatedTransactions.append(t)
		}

		replaceTransactions(updatedTransactions)

		persistTransactions()
	}

	func delete(ids: [UUID]) async throws {
		let remaining = try await network.deleteTransactions(ids: ids)
		applyRemoteTransactions(remaining)
	}

	#if os(iOS)
		func logout() async throws {
			try await network.logout()
			replaceTransactions([])
			persistTransactions()
			Defaults[.goals] = []
			GoalGaugeWidgetStore.saveGoals([])
		}

		func deleteUser() async throws {
			try await network.deleteCurrentUser()
			replaceTransactions([])
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
		replaceTransactions(remote.map(Transaction.init(from:)))
		persistTransactions()
	}

	private func replaceTransactions(_ newTransactions: [Transaction]) {
		_transactions = newTransactions
	}

	private func persistTransactions() {
		Defaults[.transactions] = _transactions
		GoalGaugeWidgetStore.saveTransactions(_transactions)
	}
}
