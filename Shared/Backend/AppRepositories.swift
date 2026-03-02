import SwiftUI

@MainActor
final class AppRepositories {
	static let `default` = AppRepositories(
		transactionRepo: TransactionRepository.shared,
		goalRepo: GoalRepository.shared
	)

	let transactionRepo: TransactionRepository
	let goalRepo: GoalRepository

	init(transactionRepo: TransactionRepository, goalRepo: GoalRepository) {
		self.transactionRepo = transactionRepo
		self.goalRepo = goalRepo
	}
}

private struct AppRepositoriesKey: EnvironmentKey {
	static let defaultValue = AppRepositories.default
}

extension EnvironmentValues {
	var repositories: AppRepositories {
		get { self[AppRepositoriesKey.self] }
		set { self[AppRepositoriesKey.self] = newValue }
	}
}
