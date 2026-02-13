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
		DetailedEntry(date: Date(), total: 100.00)
	}

	func getSnapshot(in _: Context, completion: @escaping (DetailedEntry) -> Void) {
		let total = Defaults[.transactions].reduce(0.0) { $0 + $1.change }
		let entry = DetailedEntry(date: Date(), total: total)
		completion(entry)
	}

	func getTimeline(in _: Context, completion: @escaping (Timeline<DetailedEntry>) -> Void) {
		let total = Defaults[.transactions].reduce(0.0) { $0 + $1.change }
		let entry = DetailedEntry(date: Date(), total: total)
		let timeline = Timeline(entries: [entry], policy: .atEnd)
		completion(timeline)
	}
}

struct DetailedEntry: TimelineEntry {
	let date: Date
	let total: Double
}

struct Money_WidgetsDetailedEntryView: View {
	var entry: DetailedProvider.Entry

	@Environment(\.widgetFamily) var widgetFamily

	var body: some View {
		switch widgetFamily {
			case .systemLarge, .systemMedium, .systemSmall:
				Text(entry.total, format: .currency(code: "AUD"))
					.foregroundStyle(.white)
					.font(.system(size: 1000))
					.monospaced()
					.lineLimit(1)
					.minimumScaleFactor(0.01)
			case .accessoryCorner:
				Text(Image("Logo"))
					.font(.system(size: 10))
					.widgetCurvesContent()
					.widgetLabel {
						Text(entry.total, format: .currency(code: "AUD"))
							.monospaced()
					}
			case .accessoryInline:
				Text(entry.total, format: .currency(code: "AUD"))
			// should be accessoryRectangular
			// accessoryCircular not supported
			default:
				VStack(alignment: .trailing) {
					Text("Money")
						.font(.body)

					Text(entry.total, format: .currency(code: "AUD"))
						.font(.system(size: 300))
						.lineLimit(1)
						.minimumScaleFactor(0.001)
				}
		}
	}
}

struct Money_WidgetsDetailed: Widget {
	let kind: String = "Money_Widgets"

	var body: some WidgetConfiguration {
		StaticConfiguration(kind: kind, provider: DetailedProvider()) { entry in
			Money_WidgetsDetailedEntryView(entry: entry)
				.containerBackground(.black, for: .widget)
		}
		.configurationDisplayName("Total")
		.description("Sum of all transactions.")
		.supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge, .accessoryInline, .accessoryRectangular])
	}
}

#Preview(as: .systemSmall) {
	Money_WidgetsDetailed()
} timeline: {
	DetailedEntry(date: .now, total: 1234.56)
}

#Preview(as: .systemMedium) {
	Money_WidgetsDetailed()
} timeline: {
	DetailedEntry(date: .now, total: 1234.56)
}

#Preview(as: .systemLarge) {
	Money_WidgetsDetailed()
} timeline: {
	DetailedEntry(date: .now, total: 1234.56)
}

#Preview(as: .systemExtraLarge) {
	Money_WidgetsDetailed()
} timeline: {
	DetailedEntry(date: .now, total: 1234.56)
}

#Preview(as: .accessoryInline) {
	Money_WidgetsDetailed()
} timeline: {
	DetailedEntry(date: .now, total: 1234.56)
}

#Preview(as: .accessoryRectangular) {
	Money_WidgetsDetailed()
} timeline: {
	DetailedEntry(date: .now, total: 1234.56)
}
