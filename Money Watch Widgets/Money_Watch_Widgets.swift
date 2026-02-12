//
//  Money_Watch_Widgets.swift
//  Money Watch Widgets
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

struct Money_Watch_WidgetsEntryView: View {
	var entry: Provider.Entry

	@Environment(\.widgetFamily) var widgetFamily

	var body: some View {
		switch widgetFamily {
			case .accessoryCorner:
				Text(Image("Logo"))
					.font(.system(size: 10))
					.widgetCurvesContent()
					.widgetLabel {
						Text(entry.total, format: .currency(code: "AUD"))
							.monospaced()
					}
			case .accessoryInline:
				Text("Money \(entry.total, format: .currency(code: "AUD"))")
			// should be accessoryRectangular
			// accessoryCircular not supported
			default:
				HStack {
					Color.yellow
						.mask(
							Image("BiggerLogo")
								.renderingMode(.template)
								.resizable()
								.aspectRatio(contentMode: .fit)
								.frame(height: 50)
								.offset(x: -20)
						)

					Spacer()

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
}

struct Money_Watch_Widgets: Widget {
	let kind: String = "Money_Widgets"

	var body: some WidgetConfiguration {
		StaticConfiguration(kind: kind, provider: Provider()) { entry in
			Money_Watch_WidgetsEntryView(entry: entry)
				.containerBackground(.black, for: .widget)
		}
		.configurationDisplayName("Total")
		.description("Sum of all transactions.")
		.supportedFamilies([.accessoryCorner, .accessoryInline, .accessoryRectangular])
	}
}

#Preview(as: .accessoryCorner) {
	Money_Watch_Widgets()
} timeline: {
	SimpleEntry(date: .now, total: 1234.56)
}

#Preview(as: .accessoryInline) {
	Money_Watch_Widgets()
} timeline: {
	SimpleEntry(date: .now, total: 1234.56)
}

#Preview(as: .accessoryRectangular) {
	Money_Watch_Widgets()
} timeline: {
	SimpleEntry(date: .now, total: 1234.56)
}
