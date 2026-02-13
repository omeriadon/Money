//
//  Money_Widgets Detailed.swift
//  Money Widgets
//
//  Created by Adon Omeri on 12/2/2026.
//

import Defaults
import SwiftUI
import WidgetKit

struct DetailedProvider: TimelineProvider {
	func placeholder(in _: Context) -> DetailedEntry {
		DetailedEntry(date: Date(), transactions: [])
	}

	func getSnapshot(in _: Context, completion: @escaping (DetailedEntry) -> Void) {
		let transactions = Defaults[.transactions]
		let entry = DetailedEntry(date: Date(), transactions: transactions)
		completion(entry)
	}

	func getTimeline(in _: Context, completion: @escaping (Timeline<DetailedEntry>) -> Void) {
		let transactions = Defaults[.transactions]
		let entry = DetailedEntry(date: Date(), transactions: transactions)
		let timeline = Timeline(entries: [entry], policy: .atEnd)
		completion(timeline)
	}
}

struct DetailedEntry: TimelineEntry {
	let date: Date
	let transactions: [Transaction]

	var total: Double {
		transactions.reduce(0.0) { $0 + $1.change }
	}
}

struct Money_WidgetsDetailedEntryView: View {
	var entry: DetailedProvider.Entry

	@Environment(\.widgetFamily) var widgetFamily
	@Environment(\.colorScheme) var colorScheme

	var body: some View {
		Group {
			switch widgetFamily {
				case .systemSmall:
					if entry.transactions.isEmpty {
						Text("No transactions")
							.foregroundStyle(.white.opacity(0.5))
							.font(.caption)
					} else {
						VStack(alignment: .trailing, spacing: 10) {
							ForEach(entry.transactions.suffix(3)) { transaction in
								VStack(alignment: .trailing) {
									Text(transaction.title)
										.foregroundStyle(.secondary)
										.font(.callout)
									Text(transaction.change, format: .currency(code: "AUD"))
										.lineLimit(1)
										.font(.title3)
										.foregroundStyle(transaction.change > 0 ? .green : .red)
								}
							}
						}
						.monospaced()
						.foregroundStyle(.white)
						.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
					}

				case .systemMedium:
					if entry.transactions.isEmpty {
						Text("No transactions")
							.foregroundStyle(.white.opacity(0.5))
							.font(.caption)
					} else {
						VStack(alignment: .trailing, spacing: 10) {
							ForEach(entry.transactions.suffix(4)) { transaction in
								HStack {
									Label {
										Text(transaction.title)

									} icon: {
										Image(systemName: transaction.importance.symbol)
									}
									.foregroundStyle(.secondary)
									Spacer(minLength: 0)
									Text(transaction.change, format: .currency(code: "AUD"))
										.lineLimit(1)
										.font(.title3)
										.foregroundStyle(transaction.change > 0 ? .green : .red)
								}
							}
						}
						.monospaced()
						.foregroundStyle(.white)
						.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
					}

				// should be systemLarge
				default:
					if entry.transactions.isEmpty {
						Text("No transactions")
							.foregroundStyle(.white.opacity(0.5))
							.font(.caption)
					} else {
						VStack(alignment: .trailing, spacing: 9) {
							ForEach(entry.transactions.suffix(10)) { transaction in
								HStack {
									Label {
										Text(transaction.title)
									} icon: {
										Image(systemName: transaction.importance.symbol)
									}
									.foregroundStyle(.secondary)
									Spacer(minLength: 0)
									Text(transaction.change, format: .currency(code: "AUD"))
										.lineLimit(1)
										.font(.title3)
										.foregroundStyle(transaction.change > 0 ? .green : .red)
								}
							}
						}
						.monospaced()
						.foregroundStyle(.white)
						.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
					}
			}
		}
		.containerBackground(for: .widget) {
			Color.primary.colorInvert()
		}
	}
}

struct Money_WidgetsDetailed: Widget {
	let kind: String = "Money_Widgets_Detailed"

	var body: some WidgetConfiguration {
		StaticConfiguration(kind: kind, provider: DetailedProvider()) { entry in
			Money_WidgetsDetailedEntryView(entry: entry)
				.widgetAccentable()
		}
		.configurationDisplayName("Recent Transactions")
		.description("Details for your recent transactions")
		.supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
	}
}

#Preview("Widgets", as: .systemLarge) {
	Money_WidgetsDetailed()
} timeline: {
	DetailedEntry(date: .now, transactions: [
		Transaction(change: 1250.00, title: "Salary", desc: "Monthly payment", importance: .dayJob),
		Transaction(change: -4005.50, title: "Groceries", desc: "Weekly shopping", importance: .emergency),
		Transaction(change: -120.00, title: "Bills", desc: "Utilities", importance: .oneTime),
		Transaction(change: -120.00, title: "Bills", desc: "Utilities", importance: .oneTime),
		Transaction(change: 1250.00, title: "Salary", desc: "Monthly payment", importance: .dayJob),
		Transaction(change: -4005.50, title: "Groceries", desc: "Weekly shopping", importance: .emergency),
		Transaction(change: -120.00, title: "Bills", desc: "Utilities", importance: .oneTime),
		Transaction(change: 30.00, title: "Freelance", desc: "Side project", importance: .passiveIncome),
		Transaction(change: 300.00, title: "Freelance", desc: "Side project", importance: .passiveIncome),
		Transaction(change: 30.00, title: "Freelance", desc: "Side project", importance: .passiveIncome),
		Transaction(change: 300.00, title: "Freelance", desc: "Side project", importance: .passiveIncome),
		Transaction(change: 1250.00, title: "Salary", desc: "Monthly payment", importance: .dayJob),
		Transaction(change: -4005.50, title: "Groceries", desc: "Weekly shopping", importance: .emergency),
		Transaction(change: 30.00, title: "Freelance", desc: "Side project", importance: .passiveIncome),
		Transaction(change: 300.00, title: "Freelance", desc: "Side project", importance: .passiveIncome),
		Transaction(change: 20.00, title: "Freelance", desc: "Side project", importance: .passiveIncome),

	])
//	DetailedEntry(date: .now, transactions: [
//		Transaction(change: 1250.00, title: "Salary", desc: "Monthly payment", importance: .dayJob),
//	])
//	DetailedEntry(date: .now, transactions: [])
}
