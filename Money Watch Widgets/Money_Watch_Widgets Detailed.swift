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

struct Money_Watch_WidgetsDetailedEntryView: View {
	var entry: DetailedProvider.Entry

	@Environment(\.widgetFamily) var widgetFamily
	@Environment(\.colorScheme) var colorScheme

	var body: some View {
		Group {
			if entry.transactions.isEmpty {
				Text("No transactions")
					.foregroundStyle(.white.opacity(0.5))
					.font(.caption)
			} else {
				Group {
					ForEach(entry.transactions.suffix(2)) { transaction in
						HStack {
							Label {
								Text(transaction.title)
							} icon: {
								Image(systemName: transaction.importance.symbol)
							}
							.foregroundStyle(.secondary)
							Spacer(minLength: 0)
							Text(transaction.change, format: .currency(code: "AUD").precision(.fractionLength(0)))
								.lineLimit(1)
								.font(.title3)
								.foregroundStyle(transaction.change > 0 ? .green : .red)
						}
						if transaction == entry.transactions.suffix(2).first {
							Spacer()
						}
					}
				}
			}
		}
		.containerBackground(for: .widget) {
			Color.black
		}
	}
}

struct Money_Watch_WidgetsDetailed: Widget {
	let kind: String = "Money_Watch_Widgets_Detailed"

	var body: some WidgetConfiguration {
		StaticConfiguration(kind: kind, provider: DetailedProvider()) { entry in
			Money_Watch_WidgetsDetailedEntryView(entry: entry)
				.widgetAccentable()
		}
		.configurationDisplayName("Recent Transactions")
		.description("Details for your recent transactions")
		.supportedFamilies([.accessoryRectangular])
	}
}
