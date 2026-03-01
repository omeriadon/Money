import Defaults
import Foundation
import Observation

@MainActor
@Observable
final class GoalRepository {
	static let shared = GoalRepository(network: NetworkManager.shared)

	private var _goals: [Goal] = Defaults[.goals]

	var goals: [Goal] {
		_goals.sorted { $0.dateCreated > $1.dateCreated }
	}

	let network: NetworkManager

	init(network: NetworkManager) {
		self.network = network
	}

	func syncGoals() async throws {
		let remote = try await network.fetchGoals()
		applyRemoteGoals(remote)
	}

	func createGoal(
		name: String,
		description: String,
		goalAmount: Double
	) async throws {
		let remote = try await network.createGoal(
			name: name,
			description: description,
			goalAmount: abs(goalAmount)
		)

		applyRemoteGoals(remote)
	}

	func updateGoal(
		id: UUID,
		name: String? = nil,
		description: String? = nil,
		goalAmount: Double? = nil
	) async throws {
		let remote = try await network.updateGoal(
			id: id,
			name: name,
			description: description,
			goalAmount: goalAmount.map(abs)
		)

		let g = Goal(from: remote)
		g.goalAmount = abs(g.goalAmount)

		var updatedGoals = _goals
		if let index = updatedGoals.firstIndex(where: { $0.id == remote.id }) {
			updatedGoals[index] = g
		} else {
			updatedGoals.append(g)
		}
		replaceGoals(updatedGoals)

		persistGoals()
	}

	func delete(ids: [UUID]) async throws {
		let remaining = try await network.deleteGoals(ids: ids)
		applyRemoteGoals(remaining)
	}

	private func applyRemoteGoals(_ remote: [GoalDTO]) {
		replaceGoals(remote.map {
			let goal = Goal(from: $0)
			goal.goalAmount = abs(goal.goalAmount)
			return goal
		})
		persistGoals()
	}

	private func replaceGoals(_ newGoals: [Goal]) {
		_goals = newGoals
	}

	private func persistGoals() {
		Defaults[.goals] = _goals
		GoalGaugeWidgetStore.saveGoals(_goals)
	}
}
