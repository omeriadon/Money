//
//  AnalyseView.swift
//  Money
//
//  Created by Adon Omeri on 22/1/2026.
//

import Charts
import SwiftUI

struct BalancePoint: Identifiable {
	var id: String { "\(balance)\(date.description)" }
	let date: Date
	let balance: Double
}

struct AnalyseView: View {
	@EnvironmentObject var transactionRepo: TransactionRepository

	var cumulativeBalance: [BalancePoint] {
		let sorted = transactionRepo.transactions
			.map { t in
				(t.dateCreated, t.change)
			}
			.sorted { $0.0 < $1.0 }

		var runningTotal = 0.0

		return sorted.map { date, change in
			runningTotal += change
			return BalancePoint(date: date, balance: runningTotal)
		}
	}

	@State private var selectedRange: TimeRange = .month

	var body: some View {
		NavigationStack {
			TabView {
				ForEach(AnalyseTabItem.allCases) { tab in
					tabView(for: tab)
						.tag(tab)
				}
			}
			.tabViewStyle(.page)
			.toolbar { toolbarContent }
		}
	}

	@ViewBuilder
	var totalOverTime: some View {
		VStack(alignment: .leading, spacing: 12) {
			Picker("Range", selection: $selectedRange) {
				ForEach(TimeRange.allCases) { range in
					Text(range.rawValue).tag(range)
				}
			}
			#if os(iOS)
			.pickerStyle(.segmented)
			.padding(.horizontal)
			#else
			.pickerStyle(.navigationLink)
			#endif

			Chart(cumulativeBalance) { point in
				LineMark(
					x: .value("Date", point.date),
					y: .value("Balance", point.balance)
				)
			}
			.if(selectedRange.seconds != nil) { chart in
				chart
					.chartScrollableAxes(.horizontal)
					.chartXVisibleDomain(length: selectedRange.seconds!)
			}
			.chartXAxis {
				AxisMarks(values: .automatic) { _ in
					AxisGridLine()
					AxisValueLabel()
				}
			}
			.chartYAxis {
				AxisMarks(values: .automatic) { _ in
					AxisGridLine()
					AxisValueLabel()
				}
			}
			.animation(.interactiveSpring, value: selectedRange)
		}
		.padding(.vertical)
	}

	@ViewBuilder
	var differentTypes: some View {}

	@ViewBuilder
	private func tabView(for tab: AnalyseTabItem) -> some View {
		switch tab {
			case .tot:
				totalOverTime
			case .dt:
				differentTypes
		}
	}

	enum AnalyseTabItem: String, Identifiable, CaseIterable {
		var id: String { rawValue }

		case tot
		case dt
	}
}

enum TimeRange: String, CaseIterable, Identifiable {
	var id: String { rawValue }

	case day = "1D"
	case week = "1W"
	case month = "1M"
	case threeMonths = "3M"
	case year = "1Y"
	case allTime = "ALL"

	var seconds: Int? {
		switch self {
			case .day:
				3600 * 24
			case .week:
				3600 * 24 * 7
			case .month:
				3600 * 24 * 30
			case .threeMonths:
				3600 * 24 * 30 * 3
			case .year:
				3600 * 24 * 30 * 12
			case .allTime:
				nil
		}
	}
}
