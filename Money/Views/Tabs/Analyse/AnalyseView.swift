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
	var id: Date {
		date
	}
}

struct ImportanceSlice: Identifiable, Equatable {
	let id: Importance
	let value: Double
	let color: Color
}

struct AnalyseView: View {
	@Environment(TransactionRepository.self) var transactionRepo

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
		#if os(iOS)
		.enableInjection()
		#endif
	}

	#if DEBUG && os(iOS)
		@ObserveInjection var forceRedraw
	#endif

	@ViewBuilder
	private func tabView(for tab: AnalyseTabItem) -> some View {
		switch tab {
			case .tot:
				TotalOverTimeView()
					.environment(transactionRepo)
			case .dt:
				DifferentTypesView()
					.environment(transactionRepo)
			case .stats:
				StatisticsCardsView()
					.environment(transactionRepo)
		}
	}

	enum AnalyseTabItem: String, Identifiable, CaseIterable {
		var id: String {
			rawValue
		}

		case tot
		case dt
		case stats
	}
}

struct BalanceHeader: View {
	let selected: BalancePoint?
	let currentBalance: Double
	let transactions: [Transaction]

	private var selectedDayTransactions: [Transaction] {
		guard let selected else { return [] }
		return transactions.filter { Calendar.current.isDate($0.dateCreated, inSameDayAs: selected.date) }
	}

	var body: some View {
		HStack {
			Text(selected != nil ?
				selected!.balance.formatted(.currency(code: "AUD")) :
				currentBalance.formatted(.currency(code: "AUD")))
				.contentTransition(.numericText())
				.font(.largeTitle.bold())
				.foregroundStyle((selected?.balance ?? currentBalance) >= 0 ? .green : .red)

			Spacer()

			VStack(alignment: .trailing) {
				Text(selected != nil ? "\(selected!.date, style: .date)" : "Current")
					.contentTransition(.numericText())
					.font(.caption)
					.foregroundStyle(.secondary)

				Text(!selectedDayTransactions.isEmpty ?
					"\(selectedDayTransactions.count) transaction\(selectedDayTransactions.count == 1 ? "" : "s")" :
					"")
					.contentTransition(.numericText())
					.font(.caption)
					.foregroundStyle(!selectedDayTransactions.isEmpty ? .secondary : .primary)
					.transition(.opacity)
			}
		}
		.padding(.horizontal)
		.animation(.easeInOut, value: selected?.date)
		#if os(iOS)
			.enableInjection()
		#endif
	}

	#if DEBUG && os(iOS)
		@ObserveInjection var forceRedraw
	#endif
}

enum TypeOfPieChart: String, CaseIterable, Identifiable {
	var id: String {
		rawValue
	}

	case count = "Amount of Transactions"
	case total = "Total Transaction Cost"
}

enum TimeRange: String, CaseIterable, Identifiable {
	var id: String {
		rawValue
	}

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
