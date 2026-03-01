//
//  GoalEntity.swift
//  Money
//
//  Created by Adon Omeri on 1/3/2026.
//

import AppIntents
import Foundation

struct GoalEntity: AppEntity {
	static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Goal")
	static var defaultQuery = GoalEntityQuery()

	let id: UUID
	let name: String
	let description: String
	let goalAmount: Double
	let dateCreated: Date
	let dateUpdated: Date

	var displayRepresentation: DisplayRepresentation {
		DisplayRepresentation(
			title: "\(name)",
			subtitle: "$\(String(format: "%.2f", goalAmount))"
		)
	}
}

struct GoalEntityQuery: EntityQuery {
	@MainActor
	func entities(for identifiers: [UUID]) async throws -> [GoalEntity] {
		GoalRepository.shared.goals
			.filter { identifiers.contains($0.id) }
			.map(GoalEntity.init(from:))
	}

	@MainActor
	func suggestedEntities() async throws -> [GoalEntity] {
		GoalRepository.shared.goals.map(GoalEntity.init(from:))
	}

	func defaultResult() async -> GoalEntity? {
		try? await suggestedEntities().first
	}
}

extension GoalEntity {
	init(from goal: Goal) {
		self.init(
			id: goal.id,
			name: goal.name,
			description: goal.desc,
			goalAmount: goal.goalAmount,
			dateCreated: goal.dateCreated,
			dateUpdated: goal.dateUpdated
		)
	}
}
