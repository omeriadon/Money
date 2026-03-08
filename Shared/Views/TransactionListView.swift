//
//  TransactionListView.swift
//  Money
//
//  Created by Adon Omeri on 22/1/2026.
//
#if canImport(Glur)
	import Glur
#endif
import SwiftUI

struct TransactionListView: View {
	@Environment(\.repositories) private var repositories
	@Environment(AppRouter.self) var appRouter

	private var transactionRepo: TransactionRepository {
		repositories.transactionRepo
	}

	@State private var isLoading = false
	@State private var showSuccess = false
	@State private var errorMessage: String?
	@State private var searchText = ""
	@State private var showAddTransaction = false

	@Namespace private var namespace
	@State private var keyboardVisible = false

	private var filteredTransactions: [Transaction] {
		if searchText.isEmpty { return transactionRepo.transactions }
		return transactionRepo.transactions.filter {
			$0.title.localizedCaseInsensitiveContains(searchText)
		}
	}

	var body: some View {
		NavigationStack(path: Bindable(appRouter).transactionPath) {
			ZStack {
				List {
					if filteredTransactions.isEmpty {
						HStack {
							Spacer()
							ContentUnavailableView(
								searchText.isEmpty ? "No Transactions" : "No Results",
								systemImage: searchText.isEmpty ? "camera.metering.none" : "magnifyingglass"
							)
							Spacer()
						}
						.listRowBackground(Color.clear)
						.transition(.blurReplace)
					} else {
						ForEach(filteredTransactions) { transaction in
							NavigationLink(value: TransactionRoute.detail(transaction.id)) {
								HStack {
									Text(transaction.title)
									Image(systemName: transaction.importance.symbol)
									Spacer()
									Text(transaction.change, format: .currency(code: "AUD"))
										.foregroundStyle(transaction.change > 0 ? .green : .red)
										.font(.title3)
										.lineLimit(1)
										.minimumScaleFactor(0.01)
								}
							}
							.transition(.blurReplace)
						}
						.onDelete { indexSet in
							let ids = indexSet.map { filteredTransactions[$0].id }
							Task {
								do { try await transactionRepo.delete(ids: ids) }
								catch { errorMessage = error.localizedDescription }
							}
						}
					}
				}
				.searchable(text: $searchText, prompt: isiPhone() ? "Search transactions" : "Search")
				.tint(.secondary)
				.refreshable { Task { await refresh() } }
				.animation(.easeInOut, value: filteredTransactions.count)
				.transition(.blurReplace)
			}
			.navigationDestination(for: TransactionRoute.self) { route in
				switch route {
					case let .detail(id):
						if let transaction = transactionRepo.transactions.first(where: { $0.id == id }) {
							TransactionDetailView(isNew: false, transaction: transaction)
						} else {
							ContentUnavailableView("Transaction Not Found", systemImage: "magnifyingglass")
						}
				}
			}
			.sheet(isPresented: $showAddTransaction) {
				TransactionDetailView(isNew: true)
					.presentationDetents([.medium])
					.presentationDragIndicator(.hidden)
				#if os(iOS)
					.navigationTransition(.zoom(sourceID: "unique_transition_id", in: namespace))
				#endif
			}
			.animation(.easeInOut, value: filteredTransactions.isEmpty)
			.toolbar { toolbarContent }
			.toolbar {
				#if os(iOS)
					ToolbarItem(placement: .topBarTrailing) {
						Button { showAddTransaction = true } label: {
							Label("Add Transaction", systemImage: "plus")
						}
						.buttonStyle(.glassProminent)
						.foregroundStyle(.black)
					}
					.matchedTransitionSource(id: "unique_transition_id", in: namespace)

					if !transactionRepo.transactions.isEmpty {
						ToolbarItem(placement: .topBarTrailing) { CustomEditButton() }
						ToolbarSpacer(placement: .topBarTrailing)
					}
				#endif

				ToolbarItem(placement: .topBarTrailing) {
					RefreshButton(isLoading: $isLoading, showSuccess: $showSuccess) {
						await refresh()
					}
				}
			}
			.animation(.easeInOut, value: keyboardVisible)
		}
		#if os(iOS)
		.overlay(alignment: .top) {
			if keyboardVisible {
				ZStack {
					VariableBlurView(maxBlurRadius: 1.2, direction: .blurredTopClearBottom)
					LinearGradient(
						gradient: Gradient(stops: FadeGradient.stops),
						startPoint: .top,
						endPoint: .bottom
					)
				}
				.frame(height: 100)
				.ignoresSafeArea()
			}
		}
		.onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
			keyboardVisible = true
		}
		.onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
			keyboardVisible = false
		}
		#endif
		#if os(iOS)
		.enableInjection()
		#endif
	}

	#if DEBUG && os(iOS)
		@ObserveInjection var forceRedraw
	#endif

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
