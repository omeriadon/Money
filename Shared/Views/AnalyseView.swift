//
//  AnalyseView.swift
//  Money
//
//  Created by Adon Omeri on 22/1/2026.
//

import Charts
import SwiftUI

// MARK: - Models

struct BalancePoint: Identifiable {
	var id: String { "\(balance)\(date.description)" }
	let date: Date
	let balance: Double
}

struct ImportanceSlice: Identifiable {
	let id: Importance
	let value: Double
}

// MARK: - Main View

struct AnalyseView: View {
	@EnvironmentObject var transactionRepo: TransactionRepository

	private let importanceOrder = Importance.allCases

	var cumulativeBalance: [BalancePoint] {
		let sorted = transactionRepo.transactions
			.map { ($0.dateCreated, $0.change) }
			.sorted { $0.0 < $1.0 }

		var runningTotal = 0.0

		return sorted.map { date, change in
			runningTotal += change
			return BalancePoint(date: date, balance: runningTotal)
		}
	}

	var importanceSlices: [ImportanceSlice] {
		let grouped = Dictionary(grouping: transactionRepo.transactions) { $0.importance }

		return importanceOrder.map { importance in
			let transactions = grouped[importance] ?? []

			let value: Double = switch selectedPieChart {
				case .count:
					Double(transactions.count)
				case .total:
					transactions.reduce(0) { $0 + abs($1.change) }
			}

			return ImportanceSlice(id: importance, value: value)
		}
	}

	var cumulativeRanges: [(importance: Importance, range: Range<Double>)] {
		var cumulative = 0.0

		return importanceSlices.map { slice in
			let newCumulative = cumulative + slice.value
			let result = (importance: slice.id, range: cumulative ..< newCumulative)
			cumulative = newCumulative
			return result
		}
	}

	var rangeTotalChange: Double {
		guard let seconds = selectedRange.seconds else {
			return transactionRepo.transactions.reduce(0) { $0 + $1.change }
		}

		let cutoff = Date().addingTimeInterval(-Double(seconds))

		return transactionRepo.transactions
			.filter { $0.dateCreated >= cutoff }
			.reduce(0) { $0 + $1.change }
	}

	// MARK: State

	@State private var selectedRange: TimeRange = .month
	@State private var selectedPieChart: TypeOfPieChart = .count
	@State private var rawSelectedDate: Date?
	@State private var selectedAngle: Double?

	// MARK: Selection Resolution

	var selectedBalancePoint: BalancePoint? {
		guard let rawSelectedDate else { return nil }
		return cumulativeBalance.last(where: { $0.date <= rawSelectedDate })
	}

	var selectedSlice: ImportanceSlice? {
		guard let selectedAngle,
		      let index = cumulativeRanges.firstIndex(where: { $0.range.contains(selectedAngle) })
		else { return nil }

		return importanceSlices[index]
	}

	var totalSliceValue: Double {
		importanceSlices.reduce(0) { $0 + $1.value }
	}

	// MARK: Body

	var body: some View {
		NavigationStack {
			TabView {
				ForEach(AnalyseTabItem.allCases) { tab in
					tabView(for: tab)
						.padding(.bottom)
						.tag(tab)
				}
			}
			.tabViewStyle(.page)
			.toolbar { toolbarContent }
		}
	}

	// MARK: - Total Over Time

	@ViewBuilder
	var totalOverTime: some View {
		VStack(alignment: .leading, spacing: 12) {
			BalanceHeader(
				selected: selectedBalancePoint,
				rangeDelta: rangeTotalChange
			)

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

			Chart(cumulativeBalance, id: \.id) { point in
				LineMark(
					x: .value("Date", point.date),
					y: .value("Balance", point.balance)
				)
				.interpolationMethod(.stepEnd)
			}

			if let selected = selectedBalancePoint {
				Chart {
					RuleMark(x: .value("Selected", selected.date))
						.foregroundStyle(.gray.opacity(0.3))
						.offset(yStart: -10)
				}
			}
		}
		.chartXSelection(value: $rawSelectedDate)
		.if(selectedRange.seconds != nil) { chart in
			chart
				.chartScrollableAxes(.horizontal)
				.chartXVisibleDomain(length: selectedRange.seconds!)
		}
		.chartXAxis {
			AxisMarks()
		}
		.chartYAxis {
			AxisMarks()
		}
		.animation(.interactiveSpring, value: selectedRange)
		.padding(.vertical)
	}

	// MARK: - Pie Chart

	@ViewBuilder
	var differentTypes: some View {
		VStack(alignment: .leading, spacing: 12) {
			Picker("Type", selection: $selectedPieChart) {
				ForEach(TypeOfPieChart.allCases) { type in
					Text(type.rawValue).tag(type)
				}
			}
			#if os(iOS)
			.pickerStyle(.segmented)
			.padding(.horizontal)
			#else
			.pickerStyle(.navigationLink)
			#endif

			Chart(importanceSlices, id: \.id) { slice in
				SectorMark(
					angle: .value("Value", slice.value),
					innerRadius: .ratio(0.618),
					angularInset: 1.5
				)
				.cornerRadius(5)
				.foregroundStyle(by: .value("Importance", slice.id))
				.opacity(
					selectedSlice == nil || selectedSlice?.id == slice.id
						? 1.0
						: 0.3
				)
			}
			.chartAngleSelection(value: $selectedAngle)
			.chartBackground { chartProxy in
				GeometryReader { geometry in
					let frame = geometry[chartProxy.plotFrame!]

					VStack {
						if let selected = selectedSlice {
							Text(selected.id.rawValue)
								.font(.callout)
								.foregroundStyle(.secondary)

							switch selectedPieChart {
								case .count:
									Text("\(Int(selected.value))")
										.font(.title2.bold())
									Text("transactions")
										.font(.callout)
										.foregroundStyle(.secondary)
								case .total:
									Text(selected.value, format: .currency(code: "AUD"))
										.font(.title2.bold())
							}
						} else {
							Text("All Importances")
								.font(.callout)
								.foregroundStyle(.secondary)

							switch selectedPieChart {
								case .count:
									Text("\(Int(totalSliceValue))")
										.font(.title2.bold())
									Text("transactions")
										.font(.callout)
										.foregroundStyle(.secondary)
								case .total:
									Text(totalSliceValue, format: .currency(code: "AUD"))
										.font(.title2.bold())
							}
						}
					}
					.position(x: frame.midX, y: frame.midY)
				}
			}
			.chartLegend(position: .bottom)
			.animation(.interactiveSpring, value: selectedPieChart)
			.padding(.horizontal)
			.padding(.bottom, 32)
		}
	}

	// MARK: - Tab Routing

	@ViewBuilder
	private func tabView(for tab: AnalyseTabItem) -> some View {
		switch tab {
			case .tot:
				totalOverTime
			case .dt:
				differentTypes
		}
	}

	// MARK: - Tabs

	enum AnalyseTabItem: String, Identifiable, CaseIterable {
		var id: String { rawValue }
		case tot
		case dt
	}
}

// MARK: - Header

struct BalanceHeader: View {
	let selected: BalancePoint?
	let rangeDelta: Double

	var body: some View {
		VStack(alignment: .leading, spacing: 4) {
			if let selected {
				Text(selected.date, style: .date)
					.font(.caption)
					.foregroundStyle(.secondary)

				Text(selected.balance, format: .currency(code: "AUD"))
					.font(.title2.bold())
			} else {
				Text("Total")
					.font(.caption)
					.foregroundStyle(.secondary)

				Text(rangeDelta, format: .currency(code: "AUD"))
					.font(.title.bold())
			}
		}
		.padding(.horizontal)
	}
}

// MARK: - Supporting Types

enum TypeOfPieChart: String, CaseIterable, Identifiable {
	var id: String { rawValue }
	case count = "Amount of Transactions"
	case total = "Total Transaction Cost"
}

enum TimeRange: String, CaseIterable, Identifiable {
	var id: String { rawValue }

	case week = "1W"
	case month = "1M"
	case threeMonths = "3M"
	case year = "1Y"
	case allTime = "ALL"

	var seconds: Int? {
		switch self {
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
