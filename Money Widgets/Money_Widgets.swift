//
//  Money_Widgets.swift
//  Money Widgets
//
//  Created by Adon Omeri on 12/2/2026.
//

import Defaults
import SwiftUI
import WidgetKit

struct Provider: TimelineProvider {
	func placeholder(in _: Context) -> SimpleEntry {
		SimpleEntry(date: Date(), total: 0.00)
	}

	func getSnapshot(in _: Context, completion: @escaping (SimpleEntry) -> Void) {
		let total = Defaults[.transactions].reduce(0.0) { $0 + $1.change }
		let entry = SimpleEntry(date: Date(), total: total)
		completion(entry)
	}

	func getTimeline(in _: Context, completion: @escaping (Timeline<Entry>) -> Void) {
		let total = Defaults[.transactions].reduce(0.0) { $0 + $1.change }
		let entry = SimpleEntry(date: Date(), total: total)
		let timeline = Timeline(entries: [entry], policy: .atEnd)
		completion(timeline)
	}
}

struct SimpleEntry: TimelineEntry {
	let date: Date
	let total: Double
}

struct Money_WidgetsEntryView: View {
	var entry: Provider.Entry

	var body: some View {
		Text(entry.total, format: .currency(code: "AUD"))
			.foregroundStyle(.white)
			.font(.system(size: 1000))
			.monospaced()
			.lineLimit(1)
			.minimumScaleFactor(0.01)
	}
}

struct Money_Widgets: Widget {
	let kind: String = "Money_Widgets"

	var body: some WidgetConfiguration {
		StaticConfiguration(kind: kind, provider: Provider()) { entry in
			Money_WidgetsEntryView(entry: entry)
				.containerBackground(.black, for: .widget)
		}
		.configurationDisplayName("Total")
		.description("Sum of all transactions.")
	}
}

#Preview(as: .systemSmall) {
	Money_Widgets()
} timeline: {
	SimpleEntry(date: .now, total: 1234.56)
}
