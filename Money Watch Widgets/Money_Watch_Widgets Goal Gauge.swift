import Defaults
import SwiftUI
import WidgetKit

private enum WatchGoalsGaugeStore {
	#if DEBUG
		static let suite = UserDefaults(suiteName: "group.omeriadon.money")!
	#else
		static let suite = UserDefaults(suiteName: "group.omeriadon-hackclub-release.money")!
	#endif
}

struct WatchWidgetGoal: Codable, Defaults.Serializable, Identifiable {
	let id: UUID
	let name: String
	let description: String
	let goalAmount: Double
}

struct WatchWidgetTransaction: Codable, Defaults.Serializable, Identifiable {
	let id: UUID
	let change: Double
}

extension Defaults.Keys {
	static let watchWidgetGoalsGaugeGoals = Key<[WatchWidgetGoal]>("goals", default: [], suite: WatchGoalsGaugeStore.suite)
	static let watchWidgetGoalsGaugeTransactions = Key<[WatchWidgetTransaction]>("transactions", default: [], suite: WatchGoalsGaugeStore.suite)
}

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

struct WatchGoalGaugeProvider: TimelineProvider {
	func placeholder(in _: Context) -> WatchGoalGaugeEntry {
		WatchGoalGaugeEntry(date: .now, hasGoal: true, goalName: "Emergency Fund", goalAmount: 10000, currentAmount: 4200)
	}

	func getSnapshot(in _: Context, completion: @escaping (WatchGoalGaugeEntry) -> Void) {
		completion(makeEntry())
	}

	func getTimeline(in _: Context, completion: @escaping (Timeline<WatchGoalGaugeEntry>) -> Void) {
		completion(Timeline(entries: [makeEntry()], policy: .atEnd))
	}

	private func makeEntry() -> WatchGoalGaugeEntry {
		let goals = Defaults[.watchWidgetGoalsGaugeGoals]
		let transactions = Defaults[.watchWidgetGoalsGaugeTransactions]
		let total = transactions.reduce(0.0) { $0 + $1.change }
		let selected = goals.first

		return WatchGoalGaugeEntry(
			date: .now,
			hasGoal: selected != nil,
			goalName: selected?.name ?? "No Goal",
			goalAmount: abs(selected?.goalAmount ?? 0),
			currentAmount: total
		)
	}
}

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
			case .accessoryRectangular:
				VStack(alignment: .leading, spacing: 4) {
					Text(entry.goalName)
						.lineLimit(1)
						.font(.caption)
					Gauge(value: entry.progress) {
						Text("Goal")
					}
					.gaugeStyle(.accessoryLinear)
					Text("\(entry.currentAmount, format: .currency(code: "AUD").precision(.fractionLength(0)))")
						.font(.caption2)
				}
			default:
				Text("\(entry.goalName): \(Int(entry.progress * 100))%")
		}
		}
	}
}

struct Money_Watch_WidgetsGoalGauge: Widget {
	let kind: String = "Money_Watch_Widgets_GoalGauge"

	var body: some WidgetConfiguration {
		StaticConfiguration(kind: kind, provider: WatchGoalGaugeProvider()) { entry in
			Money_Watch_WidgetsGoalGaugeEntryView(entry: entry)
				.containerBackground(.black, for: .widget)
		}
		.contentMarginsDisabled()
		.configurationDisplayName("Goal Gauge")
		.description("Track progress toward your first goal")
		.supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
	}
}
