import Combine
import Defaults
import Foundation

@MainActor
final class GoalRepository: ObservableObject {
	@Published private var _goals: [Goal] = Defaults[.goals]

	var goals: [Goal] {
		_goals.sorted { $0.dateCreated > $1.dateCreated }
	}

	let network: NetworkManager
	private var cancellables = Set<AnyCancellable>()

	init(network: NetworkManager) {
		self.network = network

		Defaults.publisher(.goals)
			.sink { [weak self] change in
				self?._goals = change.newValue
			}
			.store(in: &cancellables)
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

		if let index = _goals.firstIndex(where: { $0.id == remote.id }) {
			_goals[index] = g
		} else {
			_goals.append(g)
		}

		persistGoals()
	}

	func delete(ids: [UUID]) async throws {
		let remaining = try await network.deleteGoals(ids: ids)
		applyRemoteGoals(remaining)
	}

	private func applyRemoteGoals(_ remote: [GoalDTO]) {
		_goals = remote.map {
			let goal = Goal(from: $0)
			goal.goalAmount = abs(goal.goalAmount)
			return goal
		}
		persistGoals()
	}

	private func persistGoals() {
		Defaults[.goals] = _goals
		GoalGaugeWidgetStore.saveGoals(_goals)
	}
}
