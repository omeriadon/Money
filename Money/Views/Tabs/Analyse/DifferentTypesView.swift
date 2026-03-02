//
//  DifferentTypesView.swift
//  Money
//
//  Created by Adon Omeri on 7/2/2026.
//

import Charts
import SwiftUI

struct DifferentTypesView: View {
	@Environment(\.repositories) private var repositories

	private var transactionRepo: TransactionRepository {
		repositories.transactionRepo
	}

	@State private var selectedPieChart: TypeOfPieChart = .count
	@State private var selectedAngle: Double?

	private let importanceOrder = Importance.allCases

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
			return ImportanceSlice(id: importance, value: value, color: importance.colour)
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
				.cornerRadius(10)
				.foregroundStyle(slice.color)
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
								.transition(.opacity)

							switch selectedPieChart {
								case .count:
									VStack {
										Text("\(Int(selected.value))")
											.contentTransition(.numericText())
											.lineLimit(1)
											.font(.title)
										Text(Int(selected.value) == 1 ? "transaction" : "transactions")
											.contentTransition(.numericText())
											.lineLimit(1)
											.foregroundStyle(.secondary)
											.font(.caption)
									}
									.transition(.opacity)
								case .total:
									Text(selected.value, format: .currency(code: "AUD"))
										.contentTransition(.numericText())
										.lineLimit(1)
										.font(.title2)
										.transition(.opacity)
							}

						} else {
							Text("All Transactions")
								.lineLimit(1)
								.foregroundStyle(.secondary)
								.transition(.opacity)
								.transition(.opacity)

							let centerValueText: String = if selectedPieChart == .count {
								String(Int(totalSliceValue))
							} else {
								totalSliceValue.formatted(.currency(code: "AUD"))
							}

							Text(centerValueText)
								.contentTransition(.numericText())
								.lineLimit(1)
								.font(.title)
								.transition(.opacity)

							Text(selectedPieChart == .count ? "transactions" : "in and out")
								.contentTransition(.numericText())
								.font(.caption)
								.lineLimit(1)
								.foregroundStyle(.secondary)
								.transition(.opacity)
						}
					}
					.position(x: frame.midX, y: frame.midY)
					.animation(.easeInOut, value: selectedSlice)
					.animation(.easeInOut, value: selectedPieChart)
				}
			}
			.chartLegend(.hidden)
			.animation(.easeInOut, value: selectedPieChart)
			.padding(.horizontal)
			.padding(.bottom, 32)

			FlowLayout {
				ForEach(Importance.allCases) { importance in
					Label(importance.title, systemImage: importance.symbol)
						.foregroundStyle(importance.colour)
						.padding(.horizontal, 5)
						.if(selectedSlice != nil) { view in
							view
								.opacity(importance.title == selectedSlice!.id.title ? 1 : 0.3)
						}
				}
			}
			.scenePadding(.horizontal)
			.padding(.bottom, 32)
		}
		#if os(iOS)
		.enableInjection()
		#endif
	}

	#if DEBUG && os(iOS)
		@ObserveInjection var forceRedraw
	#endif
}
