//
//  TotalOverTimeView.swift
//  Money
//
//  Created by Adon Omeri on 7/2/2026.
//

import Charts
import SwiftUI

struct TotalOverTimeView: View {
	@Environment(TransactionRepository.self) var transactionRepo
	@Environment(\.calendar) private var calendar

	@State private var selectedRange: TimeRange = .month
	@State private var rawSelectedDate: Date?

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

	var currentBalance: Double {
		transactionRepo.transactions.reduce(0) { $0 + $1.change }
	}

	var selectedBalancePoint: BalancePoint? {
		guard let rawSelectedDate else { return nil }
		guard !cumulativeBalance.isEmpty else { return nil }

		return cumulativeBalance.min(by: {
			abs($0.date.timeIntervalSince(rawSelectedDate)) < abs($1.date.timeIntervalSince(rawSelectedDate))
		})
	}

	var body: some View {
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
				currentBalance: currentBalance,
				transactions: transactionRepo.transactions
			)

			Chart {
				ForEach(cumulativeBalance) { point in
					LineMark(
						x: .value("Date", point.date, unit: .day),
						y: .value("Balance", point.balance)
					)
				}
				.lineStyle(StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
				.foregroundStyle(chartGradient)
				.interpolationMethod(.stepEnd)

				if let selected = selectedBalancePoint {
					RuleMark(
						x: .value("Selected", selected.date, unit: .day)
					)
					.lineStyle(StrokeStyle(lineWidth: 4))
					.foregroundStyle(Color.gray.opacity(0.3))
					.zIndex(-1)
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
			.animation(.easeInOut, value: selectedRange)
		}
		.padding(.bottom, 32)
		#if os(iOS)
			.enableInjection()
		#endif
	}

	#if DEBUG && os(iOS)
		@ObserveInjection var forceRedraw
	#endif
}
