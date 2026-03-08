import Foundation

enum GoalGaugeWidgetStore {
	private static let goalsKey = "widget_goal_gauge_goals_json"
	private static let transactionsKey = "widget_goal_gauge_transactions_json"

	private static let userDefaults = UserDefaults(suiteName: AppConfig.appGroupSuiteName)

	struct WidgetGoal: Codable, Identifiable {
		let id: UUID
		let name: String
		let description: String
		let goalAmount: Double
		let status: String
		let isArchived: Bool
	}

	struct WidgetTransaction: Codable, Identifiable {
		let id: UUID
		let change: Double
	}

	static func saveGoals(_ goals: [Goal]) {
		let payload = goals.map {
			WidgetGoal(
				id: $0.id,
				name: $0.name,
				description: $0.desc,
				goalAmount: abs($0.goalAmount),
				status: $0.status.rawValue,
				isArchived: $0.isArchived
			)
		}

		if let data = try? JSONEncoder().encode(payload) {
			userDefaults?.set(data, forKey: goalsKey)
		}
	}

	static func saveTransactions(_ transactions: [Transaction]) {
		let payload = transactions.map {
			WidgetTransaction(id: $0.id, change: $0.change)
		}

		if let data = try? JSONEncoder().encode(payload) {
			userDefaults?.set(data, forKey: transactionsKey)
		}
	}
}
