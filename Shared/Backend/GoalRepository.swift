import Defaults
import Foundation
import Observation

@MainActor
@Observable
final class GoalRepository {
	static let shared = GoalRepository(network: NetworkManager.shared)

	private static let currentGoalsSchemaVersion = 2

	private var _goals: [Goal] = Defaults[.goals]

	var goals: [Goal] {
		_goals.sorted { $0.dateCreated > $1.dateCreated }
	}

	let network: NetworkManager

	init(network: NetworkManager) {
		self.network = network
		migrateGoalsIfNeeded()
	}

	func setGoalStatus(id: UUID, status: Goal.GoalStatus) async throws {
		let remote = try await network.updateGoal(id: id, status: status)
		let updated = Goal(from: remote)
		updated.goalAmount = abs(updated.goalAmount)

		if let index = _goals.firstIndex(where: { $0.id == id }) {
			_goals[index] = updated
		} else {
			var appendedGoals = _goals
			appendedGoals.append(updated)
			replaceGoals(appendedGoals)
		}

		persistGoals()
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

	private func migrateGoalsIfNeeded() {
		let schemaVersion = Defaults[.goalsSchemaVersion]
		guard schemaVersion < Self.currentGoalsSchemaVersion else { return }

		for goal in _goals {
			if goal.status == .completed, goal.goalAmount == 0 {
				goal.goalAmount = 1
			}
		}

		Defaults[.goalsSchemaVersion] = Self.currentGoalsSchemaVersion
		persistGoals()
	}
}
