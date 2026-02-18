//
//  moneyWatch_Widgets Chart.swift
//  moneyWatch Watch App
//
//  Created by Adon Omeri on 17/2/2026.
//

import Charts
import Defaults
import SwiftUI
import WidgetKit

struct WatchChartProvider: TimelineProvider {
	func placeholder(in _: Context) -> ChartEntry {
		ChartEntry(date: Date(), transactions: [])
	}

	func getSnapshot(in _: Context, completion: @escaping (ChartEntry) -> Void) {
		let transactions = Defaults[.transactions]
		let entry = ChartEntry(date: Date(), transactions: transactions)
		completion(entry)
	}

	func getTimeline(in _: Context, completion: @escaping (Timeline<ChartEntry>) -> Void) {
		let transactions = Defaults[.transactions]
		let entry = ChartEntry(date: Date(), transactions: transactions)
		let timeline = Timeline(entries: [entry], policy: .atEnd)
		completion(timeline)
	}
}

struct ChartEntry: TimelineEntry {
	let date: Date
	let transactions: [Transaction]

	var cumulativeBalance: [BalancePoint] {
		let sorted = transactions
			.map { ($0.dateCreated, $0.change) }
			.sorted { $0.0 < $1.0 }

		var running = 0.0
		return sorted.map { date, change in
			running += change
			return BalancePoint(date: date, balance: running)
		}
	}

	var currentBalance: Double {
		transactions.reduce(0.0) { $0 + $1.change }
	}
}

struct BalancePoint: Identifiable {
	let id = UUID()
	let date: Date
	let balance: Double
}

struct moneyWatch_WidgetsChartEntryView: View {
	var entry: WatchChartProvider.Entry

	@Environment(\.widgetFamily) var widgetFamily

	var chartGradient: LinearGradient {
		guard !entry.cumulativeBalance.isEmpty else {
			return LinearGradient(
				colors: [.green],
				startPoint: .bottom,
				endPoint: .top
			)
		}

		let minBalance = entry.cumulativeBalance.map(\.balance).min()!
		let maxBalance = entry.cumulativeBalance.map(\.balance).max()!

		guard minBalance != maxBalance else {
			return LinearGradient(
				colors: [minBalance >= 0 ? .green : .red],
				startPoint: .bottom,
				endPoint: .top
			)
		}

		let zero = (0 - minBalance) / (maxBalance - minBalance)
		let blend = 0.2
		let low = max(0, zero - blend / 2)
		let high = min(1, zero + blend / 2)

		let stops: [Gradient.Stop] = {
			if minBalance >= 0 {
				return [
					.init(color: .green, location: 0),
					.init(color: .green, location: 1),
				]
			}

			if maxBalance <= 0 {
				return [
					.init(color: .red, location: 0),
					.init(color: .red, location: 1),
				]
			}

			return [
				.init(color: .red, location: 0),
				.init(color: .red, location: low),
				.init(color: .green, location: high),
				.init(color: .green, location: 1),
			]
		}()

		return LinearGradient(
			gradient: Gradient(stops: stops),
			startPoint: .bottom,
			endPoint: .top
		)
	}

	var body: some View {
		Group {
			if entry.transactions.isEmpty {
				Text("No transactions")
					.foregroundStyle(.white.opacity(0.5))
					.font(.caption)
			} else {
				VStack(alignment: .leading, spacing: 3) {
					HStack(alignment: .center) {
						Color.yellow
							.mask(
								Image("BiggerLogo")
									.renderingMode(.template)
									.resizable()
									.aspectRatio(contentMode: .fit)
							)
							.frame(width: 20)

						Spacer()

						Text(entry.currentBalance, format: .currency(code: "AUD"))
							.foregroundStyle(entry.currentBalance >= 0 ? .green : .red)
					}
					.frame(height: 18)

					Chart {
						ForEach(entry.cumulativeBalance) { point in
							LineMark(
								x: .value("Date", point.date, unit: .day),
								y: .value("Balance", point.balance)
							)
						}
						.lineStyle(StrokeStyle(
							lineWidth: widgetFamily == .accessoryRectangular ? 2 : 3,
							lineCap: .round,
							lineJoin: .round
						))
						.foregroundStyle(chartGradient)
						.interpolationMethod(.stepEnd)
					}
					.chartYAxis(.visible)
					.chartXAxis(.visible)
				}
				.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
				.padding(.top, 4)
				.padding(.horizontal, 7)
				.padding(.bottom, 2)
			}
		}
		.containerBackground(for: .widget) {
			Color.black
		}
	}
}

struct moneyWatch_WidgetsChart: Widget {
	let kind: String = "moneyWatch_Widgets_Chart"

	var body: some WidgetConfiguration {
		StaticConfiguration(kind: kind, provider: WatchChartProvider()) { entry in
			moneyWatch_WidgetsChartEntryView(entry: entry)
				.widgetAccentable()
		}
		.contentMarginsDisabled()
		.configurationDisplayName("Balance Over Time")
		.description("Your balance trend across over time.")
		.supportedFamilies([.accessoryRectangular])
	}
}

#Preview("Watch Chart Widget", as: .accessoryRectangular) {
	moneyWatch_WidgetsChart()
} timeline: {
	ChartEntry(date: .now, transactions: [
		Transaction(change: 1250.00, title: "Salary", desc: "Monthly payment", importance: .dayJob),
		Transaction(change: -405.50, title: "Groceries", desc: "Weekly shopping", importance: .essential),
		Transaction(change: -120.00, title: "Bills", desc: "Utilities", importance: .oneTime),
		Transaction(change: 300.00, title: "Freelance", desc: "Side project", importance: .passiveIncome),
		Transaction(change: -80.00, title: "Transport", desc: "Gas", importance: .oneTime),
		Transaction(change: 1250.00, title: "Salary", desc: "Monthly payment", importance: .dayJob),
		Transaction(change: -350.50, title: "Groceries", desc: "Weekly shopping", importance: .essential),
		Transaction(change: -120.00, title: "Bills", desc: "Utilities", importance: .oneTime),
		Transaction(change: 200.00, title: "Freelance", desc: "Side project", importance: .passiveIncome),
	])
}
