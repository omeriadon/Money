//
//  HomeView.swift
//  Money
//
//  Created by Adon Omeri on 22/1/2026.
//

#if os(iOS)
	import ColorfulX
	import Glur
#else
	import IrregularGradient
#endif
import Defaults
import SwiftUI

struct HomeView: View {
	@EnvironmentObject var transactionRepo: TransactionRepository

	var total: Double {
		transactionRepo.transactions.reduce(0) { $0 + $1.change }
	}

	@Default(.useNewGradient) var useNewGradient

	@State private var isLoading = false
	@State private var showSuccess = false
	@State private var errorMessage: String?
	@State private var showAddTransaction = false
	@State private var showAddGoal = false

	#if canImport(ColorfulX)
		@State private var frameLimit: Int = 120
		@State private var renderScale: Double = 1.0

		@State private var positivePreset: ColorfulPreset = .summer
		@State private var positiveSpeed: Double = 1.3
		@State private var positiveBias: Double = 0.01
		@State private var positiveNoise: Double = 20.0
		@State private var positiveTransition: Double = 10

		@State private var negativeColours: [Color] = [.red, .orange, .red, .red, .pink, .red]
		@State private var negativeSpeed: Double = 2.0
		@State private var negativeBias: Double = 0.01
		@State private var negativeNoise: Double = 20.0
		@State private var negativeTransition: Double = 10
	#endif // canImport(ColorfulX)

	var body: some View {
		NavigationStack {
			VStack {
				Text(total.formatted(.currency(code: "AUD")))
					.foregroundStyle(.white)
				#if os(iOS)
					.padding(.horizontal)
				#endif
					.font(.system(size: 300))
					.lineLimit(1)
					.minimumScaleFactor(0.01)
					.contentTransition(.numericText())
					.task {
						await refresh()
					}
			}

			.containerBackground(for: .navigation) {
				if useNewGradient {
					#if os(iOS)
						if total < 0 {
							ColorfulView(
								color: $negativeColours,
								speed: $negativeSpeed,
								bias: $negativeBias,
								noise: $negativeNoise,
								transitionSpeed: $negativeTransition,
								frameLimit: $frameLimit,
								renderScale: $renderScale
							)
						} else {
							ColorfulView(
								color: $positivePreset,
								speed: $positiveSpeed,
								bias: $positiveBias,
								noise: $positiveNoise,
								transitionSpeed: $positiveTransition,
								frameLimit: $frameLimit,
								renderScale: $renderScale
							)
						}
					#else
						if total < 0 {
							
								IrregularGradient(colors: [.red, .orange, .red, .red, .pink, .red], background: Color.clear, speed: 1, animate: true)
						} else {
							
								IrregularGradient(colors: [
									Color(red: 65 / 255, green: 71 / 255, blue: 42 / 255),
									Color(red: 232 / 255, green: 222 / 255, blue: 106 / 255),
									Color(red: 105 / 255, green: 129 / 255, blue: 70 / 255),
									Color(red: 79 / 255, green: 100 / 255, blue: 52 / 255),
									Color(red: 65 / 255, green: 71 / 255, blue: 42 / 255),
									Color(red: 232 / 255, green: 222 / 255, blue: 106 / 255),
									Color(red: 105 / 255, green: 129 / 255, blue: 70 / 255),
									Color(red: 79 / 255, green: 100 / 255, blue: 52 / 255),
									Color(red: 65 / 255, green: 71 / 255, blue: 42 / 255),
									Color(red: 232 / 255, green: 222 / 255, blue: 106 / 255),
									Color(red: 105 / 255, green: 129 / 255, blue: 70 / 255),
									Color(red: 79 / 255, green: 100 / 255, blue: 52 / 255),
									Color(red: 65 / 255, green: 71 / 255, blue: 42 / 255),
									Color(red: 232 / 255, green: 222 / 255, blue: 106 / 255),
									Color(red: 105 / 255, green: 129 / 255, blue: 70 / 255),
									Color(red: 79 / 255, green: 100 / 255, blue: 52 / 255),
								],
								background: Color.clear,
								speed: 1,
								animate: true,
								)
						}
					#endif

				} else {
					Group {
						if total < 0 {
							LinearGradient(
								colors: [.red, .red.opacity(0.4)],
								startPoint: .top,
								endPoint: .bottom
							)
						} else {
							Color.clear
						}
					}
				}
			}
			.toolbar { toolbarContent }
			.toolbar {
				if isiPhone() {
					ToolbarItem(placement: .topBarTrailing) {
						Button {
							showAddTransaction = true
						} label: {
							Label("Add Transaction", systemImage: "plus")
						}
						.buttonStyle(.glassProminent)
						.foregroundStyle(.black)
					}
				} else {
					ToolbarItem(placement: .bottomBar) {
						Button {
							showAddTransaction = true
						} label: {
							Label("Add Transaction", systemImage: "plus")
								.labelStyle(.iconOnly)
						}
						.foregroundStyle(.black)
						.tint(.yellow)
					}

					ToolbarItem(placement: .bottomBar) {
						Button {
							showAddGoal = true
						} label: {
							Label("New Goal", systemImage: "target")
								.labelStyle(.iconOnly)
						}
						.foregroundStyle(.black)
						.tint(.yellow)
					}
				}

				#if os(iOS)
					ToolbarSpacer(.fixed, placement: .topBarTrailing)
				#endif

				ToolbarItem(placement: .topBarTrailing) {
					RefreshButton(isLoading: $isLoading, showSuccess: $showSuccess) {
						await refresh()
					}
				}
			}
			.sheet(isPresented: $showAddTransaction) {
				TransactionDetailView(isNew: true)
					.presentationDragIndicator(.hidden)
			}
			.sheet(isPresented: $showAddGoal) {
				GoalDetailView(isNew: true)
					.presentationDragIndicator(.hidden)
			}
		}
	}

	private func refresh() async {
		do {
			isLoading = true
			try await transactionRepo.syncTransactions()
			showSuccess = true
			Task {
				try? await Task.sleep(for: .seconds(1))
				showSuccess = false
			}
			isLoading = false
		} catch {
			isLoading = false
			errorMessage = error.localizedDescription
		}
	}
}
