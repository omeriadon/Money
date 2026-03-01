//
//  Money_Widgets Simple.swift
//  Money Widgets
//
//  Created by Adon Omeri on 12/2/2026.
//

import Defaults
import SwiftUI
import WidgetKit

struct SimpleProvider: TimelineProvider {
	func placeholder(in _: Context) -> SimpleEntry {
		SimpleEntry(date: Date(), total: 0)
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

struct Money_WidgetsSimpleEntryView: View {
	var entry: SimpleProvider.Entry

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

struct Money_WidgetsSimple: Widget {
	let kind: String = "Money_Widgets_Simple"

	var body: some WidgetConfiguration {
		StaticConfiguration(kind: kind, provider: SimpleProvider()) { entry in
			Money_WidgetsSimpleEntryView(entry: entry)
				.containerBackground(for: .widget) {
					Color.primary.colorInvert()
				}
				.widgetURL(AppDeepLink.transactions())
		}
		.configurationDisplayName("Total")
		.description("Sum of all transactions.")
		.supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge, .accessoryInline, .accessoryRectangular])
	}
}

#Preview(as: .systemSmall) {
	Money_WidgetsSimple()
} timeline: {
	SimpleEntry(date: .now, total: 1234.56)
}

#Preview(as: .systemMedium) {
	Money_WidgetsSimple()
} timeline: {
	SimpleEntry(date: .now, total: 1234.56)
}

#Preview(as: .systemLarge) {
	Money_WidgetsSimple()
} timeline: {
	SimpleEntry(date: .now, total: 1234.56)
}

#Preview(as: .systemExtraLarge) {
	Money_WidgetsSimple()
} timeline: {
	SimpleEntry(date: .now, total: 1234.56)
}

#Preview(as: .accessoryInline) {
	Money_WidgetsSimple()
} timeline: {
	SimpleEntry(date: .now, total: 1234.56)
}

#Preview(as: .accessoryRectangular) {
	Money_WidgetsSimple()
} timeline: {
	SimpleEntry(date: .now, total: 1234.56)
}
