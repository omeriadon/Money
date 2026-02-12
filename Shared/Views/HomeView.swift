//
//  HomeView.swift
//  Money
//
//  Created by Adon Omeri on 22/1/2026.
//

#if os(iOS)
	import ColorfulX
	import Glur
#endif
import Defaults
import SwiftUI

struct HomeView: View {
	@EnvironmentObject var transactionRepo: TransactionRepository

	var total: Double {
		transactionRepo.transactions.reduce(0) { $0 + $1.change }
	}

	@Default(.useNewGradient) var useNewGradient

	@State private var didSyncOnce = false
	@State private var isLoading = false
	@State private var showSuccess = false
	@State private var errorMessage: String?
	@State private var showAddTransaction = false

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
						if !didSyncOnce {
							didSyncOnce = true
							await refresh()
						}
					}
			}
			#if !os(iOS)
			.containerBackground(total < 0 ? Color.red.gradient : Color.clear.gradient, for: .tabView)
			#else
			.containerBackground(for: .navigation) {
				if useNewGradient {
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
			#endif
			.toolbar { toolbarContent }
			.toolbar {
				ToolbarItem(placement: .topBarTrailing) {
					RefreshButton(isLoading: $isLoading, showSuccess: $showSuccess) {
						await refresh()
					}
				}

				#if os(iOS)
					ToolbarSpacer(.fixed, placement: .topBarTrailing)
				#endif

				ToolbarItem(placement: isiPhone() == true ? .topBarTrailing : .bottomBar) {
					Button {
						showAddTransaction = true
					} label: {
						Label("Add Transaction", systemImage: "plus")
					}
					.buttonStyle(.glassProminent)
					.foregroundStyle(.black)
				}
			}
			.sheet(isPresented: $showAddTransaction) {
				TransactionDetailView(isNew: true)
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

struct HomeView_Previews: PreviewProvider {
	static var previews: some View {
		HomeView()
			.environmentObject(TransactionRepository(network: NetworkManager.shared))
			.monospaced()
	}
}
