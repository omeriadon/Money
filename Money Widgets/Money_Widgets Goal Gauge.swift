import AppIntents
import SwiftUI
import WidgetKit

// MARK: - Data Models

struct WidgetGoal: Codable, Identifiable {
	let id: UUID
	let name: String
	let description: String
	let goalAmount: Double
}

struct WidgetTransaction: Codable, Identifiable {
	let id: UUID
	let change: Double
}

// MARK: - Shared Store

private enum SharedStore {
	#if DEBUG
		static let suiteName = "group.omeriadon.money"
	#else
		static let suiteName = "group.omeriadon-hackclub-release.money"
	#endif
	static let goalsKey = "widget_goal_gauge_goals_json"
	static let transactionsKey = "widget_goal_gauge_transactions_json"

	static func saveGoals(_ goals: [WidgetGoal]) {
		if let data = try? JSONEncoder().encode(goals) {
			UserDefaults(suiteName: suiteName)?.set(data, forKey: goalsKey)
		}
	}

	static func saveTransactions(_ transactions: [WidgetTransaction]) {
		if let data = try? JSONEncoder().encode(transactions) {
			UserDefaults(suiteName: suiteName)?.set(data, forKey: transactionsKey)
		}
	}

	static func loadGoals() -> [WidgetGoal] {
		guard let data = UserDefaults(suiteName: suiteName)?.data(forKey: goalsKey),
		      let goals = try? JSONDecoder().decode([WidgetGoal].self, from: data)
		else {
			return []
		}
		return goals
	}

	static func loadTransactions() -> [WidgetTransaction] {
		guard let data = UserDefaults(suiteName: suiteName)?.data(forKey: transactionsKey),
		      let transactions = try? JSONDecoder().decode([WidgetTransaction].self, from: data)
		else {
			return []
		}
		return transactions
	}
}

// MARK: - AppEntity

struct GoalChoiceEntity: AppEntity, Identifiable {
	static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Goal")
	static var defaultQuery = GoalChoiceQuery()

	let id: UUID
	let name: String

	var displayRepresentation: DisplayRepresentation {
		DisplayRepresentation(title: .init("\(name)"))
	}
}

struct GoalChoiceQuery: EntityQuery {
	@MainActor
	func entities(for identifiers: [UUID]) async throws -> [GoalChoiceEntity] {
		let goals: [WidgetGoal] = SharedStore.loadGoals()
		return goals
			.filter { identifiers.contains($0.id) }
			.map { GoalChoiceEntity(id: $0.id, name: $0.name) }
	}

	@MainActor
	func suggestedEntities() async throws -> [GoalChoiceEntity] {
		let goals: [WidgetGoal] = SharedStore.loadGoals()
		return goals.map { GoalChoiceEntity(id: $0.id, name: $0.name) }
	}

	func defaultResult() async -> GoalChoiceEntity? {
		try? await suggestedEntities().first
	}
}

// MARK: - Intent

struct GoalGaugeIntent: WidgetConfigurationIntent {
	static var title: LocalizedStringResource = "Goal Gauge"
	static var description = IntentDescription("Track progress toward one of your goals")

	@Parameter(title: "Goal")
	var goal: GoalChoiceEntity?
}

// MARK: - Timeline Entry

struct GoalGaugeEntry: TimelineEntry {
	let date: Date
	let hasGoal: Bool
	let goalName: String
	let goalAmount: Double
	let currentAmount: Double

	var progress: Double {
		guard hasGoal, goalAmount > 0 else { return 0 }
		return max(0, min(currentAmount / goalAmount, 1))
	}
}

// MARK: - Timeline Provider

struct GoalGaugeProvider: AppIntentTimelineProvider {
	func placeholder(in _: Context) -> GoalGaugeEntry {
		GoalGaugeEntry(
			date: .now,
			hasGoal: true,
			goalName: "Emergency Fund",
			goalAmount: 10000,
			currentAmount: 4200
		)
	}

	func snapshot(for configuration: GoalGaugeIntent, in _: Context) async -> GoalGaugeEntry {
		makeEntry(configuration: configuration)
	}

	func timeline(for configuration: GoalGaugeIntent, in _: Context) async -> Timeline<GoalGaugeEntry> {
		let entry = makeEntry(configuration: configuration)
		return Timeline(entries: [entry], policy: .atEnd)
	}

	private func makeEntry(configuration: GoalGaugeIntent) -> GoalGaugeEntry {
		let goals = SharedStore.loadGoals()
		let transactions = SharedStore.loadTransactions()
		let totalSaved = transactions.reduce(0.0) { $0 + $1.change }

		let selectedGoal: WidgetGoal? = {
			if let choiceID = configuration.goal?.id {
				return goals.first { $0.id == choiceID }
			}
			return goals.first
		}()

		return GoalGaugeEntry(
			date: .now,
			hasGoal: selectedGoal != nil,
			goalName: selectedGoal?.name ?? "No Goal",
			goalAmount: selectedGoal?.goalAmount ?? 0,
			currentAmount: totalSaved
		)
	}
}

// MARK: - Widget View

struct Money_WidgetsGoalGaugeEntryView: View {
	var entry: GoalGaugeProvider.Entry
	@Environment(\.widgetFamily) private var family

	var body: some View {
		if !entry.hasGoal {
			Text("No Goal").font(.caption)
		} else {
			switch family {
				case .accessoryCircular:
					Gauge(value: entry.progress) {
						Image(systemName: "target")
					} currentValueLabel: {
						Text("\(Int(entry.progress * 100))%")
					}
					.gaugeStyle(.accessoryCircular)

				case .accessoryInline:
					Label("\(entry.goalName): \(Int(entry.progress * 100))%", systemImage: "target")

				case .accessoryRectangular:
					VStack(alignment: .leading) {
						Text(entry.goalName)
							.font(.headline)
						Spacer()
						Gauge(value: entry.progress) {
							Text("Progress")
						}
						.gaugeStyle(.accessoryLinear)
						Spacer()
						HStack {
							Text("$\(entry.currentAmount, format: .number.precision(.fractionLength(0))) / $\(entry.goalAmount, format: .number.precision(.fractionLength(0)))")
							Spacer()
							Text("\(entry.progress*100, format: .number.precision(.fractionLength(0)))%")
						}
						.font(.subheadline)
					}

				default:
					VStack(alignment: .leading) {
						Text(entry.goalName)
							.font(family == .systemSmall ? .headline : .largeTitle)
						Spacer()
						Gauge(value: entry.progress) {
							Text("")
						}
						.labelsHidden()
						.gaugeStyle(.accessoryLinear)
						.foregroundStyle(.yellow)
						Spacer()
						if family == .systemMedium {
							HStack {
								Text("$\(entry.currentAmount, format: .number.precision(.fractionLength(0))) / $\(entry.goalAmount, format: .number.precision(.fractionLength(0)))")
								Spacer()
								Text("\(entry.progress * 100, format: .number.precision(.fractionLength(0)))%")
							}
						} else {
							Text("$\(entry.currentAmount, format: .number.precision(.fractionLength(0))) / $\(entry.goalAmount, format: .number.precision(.fractionLength(0)))")
							Spacer()
							Text("\(entry.progress * 100, format: .number.precision(.fractionLength(0)))%")
						}
					}
			}
		}
	}
}

// MARK: - Widget

struct Money_WidgetsGoalGauge: Widget {
	let kind: String = "Money_Widgets_GoalGauge"

	var body: some WidgetConfiguration {
		AppIntentConfiguration(
			kind: kind,
			intent: GoalGaugeIntent.self,
			provider: GoalGaugeProvider()
		) { entry in
			Money_WidgetsGoalGaugeEntryView(entry: entry)
				.containerBackground(for: .widget) {
					Color.primary.colorInvert()
				}
		}
		.configurationDisplayName("Goal Gauge")
		.description("Track progress toward a selected goal")
		.supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryInline, .accessoryRectangular])
	}
}
