//
//  Money_Watch_Widgets Simple.swift
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
					}
			case .accessoryInline:
				Text("Money \(entry.total, format: .currency(code: "AUD"))")
			// should be accessoryRectangular
			// accessoryCircular not supported
			default:
				VStack(alignment: .leading, spacing: 0) {
					HStack(alignment: .top) {
						Image("BiggerLogo")
							.renderingMode(.template)
							.resizable()
							.aspectRatio(contentMode: .fit)
							.foregroundStyle(Color.yellow)

						Spacer()

						Text("Balance")
							.font(.subheadline)
					}

					Spacer(minLength: 0)

					HStack {
						Spacer(minLength: 0)
						Text(entry.total, format: .currency(code: "AUD").precision(.fractionLength(0)))
							.foregroundStyle(entry.total >= 0 ? .green : .red)
							.font(.title)
							.lineLimit(1)
					}
				}
				.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
				.padding(.trailing)
				.padding(.top, 5)
				.padding(.leading, 4)
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
		.contentMarginsDisabled()
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
