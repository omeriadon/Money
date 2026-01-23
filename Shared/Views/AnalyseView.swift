//
//  AnalyseView.swift
//  Money
//
//  Created by Adon Omeri on 22/1/2026.
//

import Charts
import SwiftUI

struct BalancePoint: Identifiable, Equatable {
	var id: String { "\(balance)\(date.description)" }
	let date: Date
	let balance: Double
}

struct ImportanceSlice: Identifiable {
	let id: Importance
	let value: Double
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

	var importanceSlices: [ImportanceSlice] {
		let grouped = Dictionary(grouping: transactionRepo.transactions) { $0.importance }

		return grouped.map { importance, transactions in
			let value: Double = switch selectedPieChart {
				case .count:
					Double(transactions.count)

				case .total:
					transactions.reduce(0) { $0 + abs($1.change) }
			}

			return ImportanceSlice(id: importance, value: value)
		}
	}

	@State private var selectedRange: TimeRange = .month
	@State private var selectedPieChart: TypeOfPieChart = .count

	@State private var annotationOffset: CGPoint = .zero

	@State private var rawSelectedDate: Date?
	@State private var selectedAngle: Double?

	var selectedBalancePoint: BalancePoint? {
		guard let rawSelectedDate else { return nil }

		return cumulativeBalance.last(where: { $0.date <= rawSelectedDate })
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

			Chart {
				ForEach(cumulativeBalance) { point in
					LineMark(
						x: .value("Date", point.date),
						y: .value("Balance", point.balance)
					)
					.interpolationMethod(.stepEnd)
				}

				if let selected = selectedBalancePoint {
					RuleMark(
						x: .value("Selected", selected.date)
					)
					.foregroundStyle(.gray.opacity(0.3))
					.offset(yStart: -10)
					.zIndex(-1)
				}
			}
			.chartOverlay { proxy in
				GeometryReader { geometry in
					if let selected = selectedBalancePoint,
					   let xPos = proxy.position(forX: selected.date)
					{
						let annotation = VStack(alignment: .leading, spacing: 4) {
							Text(selected.date, style: .date)
							Text(selected.balance, format: .currency(code: "AUD"))
						}
						.font(.caption)
						.padding(6)
						.background(.regularMaterial)
						.clipShape(RoundedRectangle(cornerRadius: 8))
						.fixedSize()

						annotation
							.background(
								GeometryReader { annotationGeo in
									Color.clear.preference(
										key: AnnotationSizeKey.self,
										value: annotationGeo.size
									)
								}
							)
							.onPreferenceChange(AnnotationSizeKey.self) { size in
								let halfWidth = size.width / 2
								let minX = halfWidth
								let maxX = geometry.size.width - halfWidth
								let clampedX = min(max(xPos, minX), maxX)

								annotationOffset = CGPoint(x: clampedX, y: 40)
							}
							.position(annotationOffset)
					}
				}
			}
			.animation(.spring, value: selectedBalancePoint)
			.chartXSelection(value: $rawSelectedDate)
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
					AxisValueLabel(format: .dateTime.day())
				}
			}
			.animation(.interactiveSpring, value: selectedRange)
		}
		.padding(.vertical)
		.padding(.bottom)
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

			Chart(importanceSlices) { slice in
				SectorMark(
					angle: .value("Value", slice.value),
					innerRadius: .ratio(0.55),
					angularInset: 2
				)
				.foregroundStyle(by: .value("Importance", slice.id.rawValue))
				.cornerRadius(15)
			}
			.chartLegend(position: .bottom)
			.animation(.interactiveSpring, value: selectedPieChart)
			.padding(.horizontal)
			.padding(.bottom, 32)
		}
	}

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

enum TypeOfPieChart: String, CaseIterable, Identifiable {
	var id: String { rawValue }

	case count = "Amount of Transactions"
	case total = "Total Transaction Cost"
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

struct AnnotationSizeKey: PreferenceKey {
	static var defaultValue: CGSize = .zero
	static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
		value = nextValue()
	}
}
