//
//  CreateGoalIntent.swift
//  Money
//
//  Created by Adon Omeri on 1/3/2026.
//

import AppIntents

struct CreateGoalIntent: AppIntent {
	static var title: LocalizedStringResource = "Create Goal"
	static var supportedModes: IntentModes = .background

	@Parameter(title: "Name")
	var name: String

	@Parameter(title: "Description")
	var description: String?

	@Parameter(title: "Goal Amount")
	var goalAmount: Double

	@MainActor
	func perform() async throws -> some IntentResult {
		try await GoalRepository.shared.createGoal(
			name: name,
			description: description ?? "",
			goalAmount: goalAmount
		)
		return .result()
	}
}
