import AppIntents
import SwiftUI
import WidgetKit

// MARK: - Store

private enum WatchGoalsGaugeStore {
	#if DEBUG
		static let suite = UserDefaults(suiteName: "group.omeriadon.money")!
	#else
		static let suite = UserDefaults(suiteName: "group.omeriadon-hackclub-release.money")!
	#endif

	static let goalsKey = "widget_goal_gauge_goals_json"
	static let transactionsKey = "widget_goal_gauge_transactions_json"

	static func loadGoals() -> [WatchWidgetGoal] {
		guard let data = suite.data(forKey: goalsKey),
		      let goals = try? JSONDecoder().decode([WatchWidgetGoal].self, from: data)
		else { return [] }
		return goals
	}

	static func loadTransactions() -> [WatchWidgetTransaction] {
		guard let data = suite.data(forKey: transactionsKey),
		      let transactions = try? JSONDecoder().decode([WatchWidgetTransaction].self, from: data)
		else { return [] }
		return transactions
	}
}

// MARK: - Models

struct WatchWidgetGoal: Codable, Identifiable {
	let id: UUID
	let name: String
	let description: String
	let goalAmount: Double
}

struct WatchWidgetTransaction: Codable, Identifiable {
	let id: UUID
	let change: Double
}

// MARK: - AppEntity

struct WatchGoalChoiceEntity: AppEntity, Identifiable {
	static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Goal")
	static var defaultQuery = WatchGoalChoiceQuery()

	let id: UUID
	let name: String

	var displayRepresentation: DisplayRepresentation {
		DisplayRepresentation(title: .init("\(name)"))
	}
}

struct WatchGoalChoiceQuery: EntityQuery {
	func entities(for identifiers: [UUID]) async throws -> [WatchGoalChoiceEntity] {
		WatchGoalsGaugeStore.loadGoals()
			.filter { identifiers.contains($0.id) }
			.map { WatchGoalChoiceEntity(id: $0.id, name: $0.name) }
	}

	func suggestedEntities() async throws -> [WatchGoalChoiceEntity] {
		WatchGoalsGaugeStore.loadGoals()
			.map { WatchGoalChoiceEntity(id: $0.id, name: $0.name) }
	}

	func defaultResult() async -> WatchGoalChoiceEntity? {
		try? await suggestedEntities().first
	}
}

// MARK: - Intent

struct WatchGoalGaugeIntent: WidgetConfigurationIntent {
	static var title: LocalizedStringResource = "Goal Gauge"
	static var description = IntentDescription("Track progress toward one of your goals")

	@Parameter(title: "Goal")
	var goal: WatchGoalChoiceEntity?
}

// MARK: - Entry

struct WatchGoalGaugeEntry: TimelineEntry {
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

// MARK: - Provider

struct WatchGoalGaugeProvider: AppIntentTimelineProvider {
	func placeholder(in _: Context) -> WatchGoalGaugeEntry {
		WatchGoalGaugeEntry(date: .now, hasGoal: true, goalName: "Emergency Fund", goalAmount: 10000, currentAmount: 4200)
	}

	func snapshot(for configuration: WatchGoalGaugeIntent, in _: Context) async -> WatchGoalGaugeEntry {
		makeEntry(configuration: configuration)
	}

	func timeline(for configuration: WatchGoalGaugeIntent, in _: Context) async -> Timeline<WatchGoalGaugeEntry> {
		Timeline(entries: [makeEntry(configuration: configuration)], policy: .atEnd)
	}

	func recommendations() -> [AppIntentRecommendation<WatchGoalGaugeIntent>] {
		WatchGoalsGaugeStore.loadGoals().map { goal in
			let intent = WatchGoalGaugeIntent()
			intent.goal = WatchGoalChoiceEntity(id: goal.id, name: goal.name)
			return AppIntentRecommendation(intent: intent, description: goal.name)
		}
	}

	private func makeEntry(configuration: WatchGoalGaugeIntent) -> WatchGoalGaugeEntry {
		let goals = WatchGoalsGaugeStore.loadGoals()
		let transactions = WatchGoalsGaugeStore.loadTransactions()
		let total = transactions.reduce(0.0) { $0 + $1.change }

		let selected: WatchWidgetGoal? = {
			if let id = configuration.goal?.id {
				return goals.first { $0.id == id }
			}
			return goals.first
		}()

		return WatchGoalGaugeEntry(
			date: .now,
			hasGoal: selected != nil,
			goalName: selected?.name ?? "No Goal",
			goalAmount: abs(selected?.goalAmount ?? 0),
			currentAmount: total
		)
	}
}

// MARK: - View

struct Money_Watch_WidgetsGoalGaugeEntryView: View {
	var entry: WatchGoalGaugeProvider.Entry
	@Environment(\.widgetFamily) private var family

	var body: some View {
		if !entry.hasGoal {
			Text("No Goal")
				.font(.caption)
				.lineLimit(1)
		} else {
			switch family {
				case .accessoryCircular:
					Gauge(value: entry.progress) {
						Image(systemName: "target")
					} currentValueLabel: {
						Text("\(Int(entry.progress * 100))%")
					}
					.gaugeStyle(.accessoryCircular)
					.tint(.yellow)
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
							Text("\(Int(entry.progress * 100))%")
						}
						.font(.subheadline)
						.tint(.yellow)
					}
					.padding(10)
					.foregroundStyle(.yellow)
					.tint(.yellow)
				case .accessoryCorner:
					Text("\(Int(entry.progress * 100))%")
						.widgetCurvesContent()
						.font(.title)
						.widgetLabel {
							Gauge(value: entry.progress) {
								Image(systemName: "target")
							} currentValueLabel: {
								Text("\(entry.currentAmount, format: .number.precision(.fractionLength(0)))")
							} minimumValueLabel: {
								Text("\(entry.currentAmount, format: .number.precision(.fractionLength(0)))")
							} maximumValueLabel: {
								Text("\(entry.goalAmount, format: .number.precision(.fractionLength(0)))")
							}
							.tint(.yellow)
						}
						.tint(.yellow)
				default:
					Label("\(Int(entry.progress * 100))%", systemImage: "target")
			}
		}
	}
}

// MARK: - Widget

struct Money_Watch_WidgetsGoalGauge: Widget {
	let kind: String = "Money_Watch_Widgets_GoalGauge"

	var body: some WidgetConfiguration {
		AppIntentConfiguration(
			kind: kind,
			intent: WatchGoalGaugeIntent.self,
			provider: WatchGoalGaugeProvider()
		) { entry in
			Money_Watch_WidgetsGoalGaugeEntryView(entry: entry)
				.containerBackground(.black, for: .widget)
		}
		.contentMarginsDisabled()
		.configurationDisplayName("Goal Gauge")
		.description("Track progress toward a selected goal")
		.supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline, .accessoryCorner])
	}
}
