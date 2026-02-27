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

		_goals = remote.map {
			Goal(
				id: $0.id,
				name: $0.name,
				desc: $0.description,
				goalAmount: abs($0.goalAmount),
				dateCreated: $0.dateCreated,
				dateUpdated: $0.dateUpdated
			)
		}

		Defaults[.goals] = _goals
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

		_goals = remote.map {
			Goal(
				id: $0.id,
				name: $0.name,
				desc: $0.description,
				goalAmount: abs($0.goalAmount),
				dateCreated: $0.dateCreated,
				dateUpdated: $0.dateUpdated
			)
		}

		Defaults[.goals] = _goals
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

		let g = Goal(
			id: remote.id,
			name: remote.name,
			desc: remote.description,
			goalAmount: abs(remote.goalAmount),
			dateCreated: remote.dateCreated,
			dateUpdated: remote.dateUpdated
		)

		if let index = _goals.firstIndex(where: { $0.id == remote.id }) {
			_goals[index] = g
		} else {
			_goals.append(g)
		}

		Defaults[.goals] = _goals
	}

	func delete(ids: [UUID]) async throws {
		_goals.removeAll { ids.contains($0.id) }
		Defaults[.goals] = _goals

		let remaining = try await network.deleteGoals(ids: ids)
		_goals = remaining.map {
			Goal(
				id: $0.id,
				name: $0.name,
				desc: $0.description,
				goalAmount: abs($0.goalAmount),
				dateCreated: $0.dateCreated,
				dateUpdated: $0.dateUpdated
			)
		}
		Defaults[.goals] = _goals
	}
}
