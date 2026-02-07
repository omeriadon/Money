//
//  StatisticsCardsView.swift
//  Money
//
//  Created by Adon Omeri on 7/2/2026.
//

import SwiftUI

struct StatCardData: Identifiable {
	let id = UUID()
	let title: String
	let value: String
	let icon: String
	let color: Color
}

struct StatisticsCardsView: View {
	@EnvironmentObject var transactionRepo: TransactionRepository

	var totalGained: Double {
		transactionRepo.transactions
			.filter { $0.change > 0 }
			.reduce(0) { $0 + $1.change }
	}

	var totalSpent: Double {
		abs(transactionRepo.transactions
			.filter { $0.change < 0 }
			.reduce(0) { $0 + $1.change })
	}

	var averageGain: Double {
		let gains = transactionRepo.transactions.filter { $0.change > 0 }
		guard !gains.isEmpty else { return 0 }
		return gains.reduce(0) { $0 + $1.change } / Double(gains.count)
	}

	var averageLoss: Double {
		let losses = transactionRepo.transactions.filter { $0.change < 0 }
		guard !losses.isEmpty else { return 0 }
		return abs(losses.reduce(0) { $0 + $1.change } / Double(losses.count))
	}

	var highestGain: Double {
		transactionRepo.transactions
			.filter { $0.change > 0 }
			.max(by: { $0.change < $1.change })?.change ?? 0
	}

	var highestLoss: Double {
		abs(transactionRepo.transactions
			.filter { $0.change < 0 }
			.min(by: { $0.change < $1.change })?.change ?? 0)
	}

	var dailyAverage: Double {
		guard !transactionRepo.transactions.isEmpty else { return 0 }
		let dates = transactionRepo.transactions.map(\.dateCreated)
		guard let earliest = dates.min(), let latest = dates.max() else { return 0 }
		let days = max(1, Calendar.current.dateComponents([.day], from: earliest, to: latest).day ?? 1)
		return transactionRepo.transactions.reduce(0) { $0 + $1.change } / Double(days)
	}

	var gainsCount: Int {
		transactionRepo.transactions.filter { $0.change > 0 }.count
	}

	var lossesCount: Int {
		transactionRepo.transactions.filter { $0.change < 0 }.count
	}

	var biggestTransaction: Double {
		transactionRepo.transactions
			.map { abs($0.change) }
			.max() ?? 0
	}

	var statCards: [StatCardData] {
		[
			StatCardData(
				title: "Total Gained",
				value: totalGained.formatted(.currency(code: "AUD")),
				icon: "arrow.up.circle.fill",
				color: .green
			),
			StatCardData(
				title: "Total Spent",
				value: totalSpent.formatted(.currency(code: "AUD")),
				icon: "arrow.down.circle.fill",
				color: .red
			),
			StatCardData(
				title: "Average Gain",
				value: averageGain.formatted(.currency(code: "AUD")),
				icon: "chart.line.uptrend.xyaxis.circle.fill",
				color: .green
			),
			StatCardData(
				title: "Average Loss",
				value: averageLoss.formatted(.currency(code: "AUD")),
				icon: "chart.line.downtrend.xyaxis.circle.fill",
				color: .red
			),
			StatCardData(
				title: "Highest Gain",
				value: highestGain.formatted(.currency(code: "AUD")),
				icon: "arrow.up.right.circle.fill",
				color: .green
			),
			StatCardData(
				title: "Highest Loss",
				value: highestLoss.formatted(.currency(code: "AUD")),
				icon: "arrow.down.right.circle.fill",
				color: .red
			),
			StatCardData(
				title: "Daily Average",
				value: dailyAverage.formatted(.currency(code: "AUD")),
				icon: "calendar.circle.fill",
				color: dailyAverage >= 0 ? .green : .red
			),
			StatCardData(
				title: "Biggest Transaction",
				value: biggestTransaction.formatted(.currency(code: "AUD")),
				icon: "star.circle.fill",
				color: .orange
			),
			StatCardData(
				title: "Total Gains",
				value: "\(gainsCount)",
				icon: "arrow.up.circle.fill",
				color: .green
			),
			StatCardData(
				title: "Total Losses",
				value: "\(lossesCount)",
				icon: "arrow.down.circle.fill",
				color: .red
			),
		]
	}

	let rowCount = 5
	let spacing: CGFloat = 16
	let padding: CGFloat = 16
	let bottomPadding: CGFloat = 30

	var body: some View {
		Grid(horizontalSpacing: spacing, verticalSpacing: spacing) {
			ForEach(0 ..< rowCount, id: \.self) { row in
				GridRow {
					ForEach(0 ..< 2) { col in
						let index = row * 2 + col
						if index < statCards.count {
							let card = statCards[index]
							StatCard(
								title: card.title,
								value: card.value,
								icon: card.icon,
								color: card.color
							)
						}
					}
				}
				.containerRelativeFrame(.vertical) { height, _ in
					let totalVerticalPadding = (padding * 2) + bottomPadding
					let totalSpacing = spacing * CGFloat(rowCount - 1)
					let availableHeight = height - totalVerticalPadding - totalSpacing
					return availableHeight / CGFloat(rowCount)
				}
			}
		}
		.padding(padding)
		.padding(.bottom, bottomPadding)
	}
}

struct StatCard: View {
	let title: String
	let value: String
	let icon: String
	let color: Color

	var body: some View {
		VStack(alignment: .leading, spacing: 8) {
			HStack {
				Image(systemName: icon)
					.font(.title2)
					.foregroundStyle(color)
				Spacer()
			}

			Spacer()

			Text(title)
				.font(.caption)
				.foregroundStyle(.secondary)
				.lineLimit(1)

			Text(value)
				.font(.title3.bold())
				.foregroundStyle(.primary)
				.lineLimit(1)
				.minimumScaleFactor(0.5)
		}
		.padding()
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		#if os(iOS)
			.glassEffect(.clear.tint(color.opacity(0.3)).interactive(), in: RoundedRectangle(cornerRadius: 16))
		#else
			.background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
		#endif
	}
}
