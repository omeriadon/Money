//
//  AnalyseView.swift
//  Money
//
//  Created by Adon Omeri on 22/1/2026.
//

import Charts
import SwiftUI

struct BalancePoint: Identifiable {
	let date: Date
	let balance: Double
	var id: Date { date }
}

struct ImportanceSlice: Identifiable, Equatable {
	let id: Importance
	let value: Double
}

struct AnalyseView: View {
	@EnvironmentObject var transactionRepo: TransactionRepository
	@Environment(\.calendar) private var calendar

	private let importanceOrder = Importance.allCases

	var cumulativeBalance: [BalancePoint] {
		let sorted = transactionRepo.transactions
			.map { ($0.dateCreated, $0.change) }
			.sorted { $0.0 < $1.0 }

		var running = 0.0
		return sorted.map { date, change in
			running += change
			return BalancePoint(date: date, balance: running)
		}
	}

	var chartGradient: LinearGradient {
		guard !cumulativeBalance.isEmpty else {
			return LinearGradient(
				colors: [.green],
				startPoint: .bottom,
				endPoint: .top
			)
		}

		let minBalance = cumulativeBalance.map(\.balance).min()!
		let maxBalance = cumulativeBalance.map(\.balance).max()!

		guard minBalance != maxBalance else {
			return LinearGradient(
				colors: [minBalance >= 0 ? .green : .red],
				startPoint: .bottom,
				endPoint: .top
			)
		}

		let zero = (0 - minBalance) / (maxBalance - minBalance)

		let blend = 0.05
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

	var importanceSlices: [ImportanceSlice] {
		let grouped = Dictionary(grouping: transactionRepo.transactions) { $0.importance }

		return importanceOrder.map { importance in
			let tx = grouped[importance] ?? []
			let value: Double = switch selectedPieChart {
				case .count:
					Double(tx.count)
				case .total:
					tx.reduce(0) { $0 + abs($1.change) }
			}
			return ImportanceSlice(id: importance, value: value)
		}
	}

	var cumulativeRanges: [(importance: Importance, range: Range<Double>)] {
		var cumulative = 0.0
		return importanceSlices.map {
			let next = cumulative + $0.value
			defer { cumulative = next }
			return ($0.id, cumulative ..< next)
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

	@State private var selectedRange: TimeRange = .month
	@State private var selectedPieChart: TypeOfPieChart = .count
	@State private var rawSelectedDate: Date?
	@State private var selectedAngle: Double?

	var selectedBalancePoint: BalancePoint? {
		guard let rawSelectedDate else { return nil }

		return cumulativeBalance.last {
			calendar.isDate($0.date, equalTo: rawSelectedDate, toGranularity: .day)
				|| $0.date < rawSelectedDate
		}
	}

	var selectedSlice: ImportanceSlice? {
		guard
			let selectedAngle,
			let index = cumulativeRanges.firstIndex(where: { $0.range.contains(selectedAngle) })
		else { return nil }

		return importanceSlices[index]
	}

	var totalSliceValue: Double {
		importanceSlices.reduce(0) { $0 + $1.value }
	}

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

			BalanceHeader(
				selected: selectedBalancePoint,
				rangeDelta: rangeTotalChange
			)

			Chart(cumulativeBalance, id: \.id) { point in
				if let selected = selectedBalancePoint,
				   calendar.isDate(point.date, equalTo: selected.date, toGranularity: .day)
				{
					RuleMark(
						x: .value("Selected", selected.date, unit: .day)
					)
					.foregroundStyle(.accent)
					.offset(yStart: -10)
					.zIndex(-1)
				}

				LineMark(
					x: .value("Date", point.date, unit: .day),
					y: .value("Balance", point.balance)
				)
				.zIndex(1)
				.lineStyle(StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
				.foregroundStyle(chartGradient)
				.interpolationMethod(.stepEnd)
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
			.animation(.easeInOut, value: selectedRange)
		}
		.padding(.bottom, 32)
	}

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
										.contentTransition(.numericText())
										.font(.title.bold())
									Text(Int(selected.value) == 1 ? "transaction" : "transactions")
										.contentTransition(.numericText())
										.font(.callout)
										.foregroundStyle(.secondary)
								case .total:
									Text(selected.value, format: .currency(code: "AUD"))
										.contentTransition(.numericText())
										.font(.title.bold())
							}
						} else {
							Text("All Transactions")
								.font(.callout)
								.foregroundStyle(.secondary)

							let centerValueText: String = if selectedPieChart == .count {
								String(Int(totalSliceValue))
							} else {
								totalSliceValue.formatted(.currency(code: "AUD"))
							}
							Text(centerValueText)
								.contentTransition(.numericText())
								.font(.title.bold())

							if selectedPieChart == .count {
								Text("transactions")
									.font(.callout)
									.foregroundStyle(.secondary)
									.transition(.opacity)
							}
						}
					}
					.position(x: frame.midX, y: frame.midY)
					.animation(.easeInOut, value: selectedSlice)
					.animation(.easeInOut, value: selectedPieChart)
				}
			}
			.chartLegend(position: .bottom)
			.animation(.easeInOut, value: selectedPieChart)
			.padding(.horizontal)
			.padding(.bottom, 32)
		}
	}

	@ViewBuilder
	private func tabView(for tab: AnalyseTabItem) -> some View {
		switch tab {
			case .tot: totalOverTime
			case .dt: differentTypes
		}
	}

	enum AnalyseTabItem: String, Identifiable, CaseIterable {
		var id: String { rawValue }
		case tot
		case dt
	}
}

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
					.font(.title.bold())
					.foregroundStyle(selected.balance > 0 ? .green : .red)
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
			case .week: 3600 * 24 * 7
			case .month: 3600 * 24 * 30
			case .threeMonths: 3600 * 24 * 30 * 3
			case .year: 3600 * 24 * 30 * 12
			case .allTime: nil
		}
	}
}
