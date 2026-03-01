//
//  ListView.swift
//  Money
//
//  Created by Adon Omeri on 22/1/2026.
//
#if canImport(Glur)
	import Glur
#endif
import SwiftUI

struct ListView: View {
	private enum TransactionRoute: Hashable {
		case detail(UUID)
	}

	@Environment(TransactionRepository.self) var transactionRepo
	@Environment(AppRouter.self) var appRouter

	@State private var isLoading = false
	@State private var showSuccess = false
	@State private var errorMessage: String?
	@State private var searchText = ""

	@State private var showAddTransaction = false
	@State private var navigationPath = NavigationPath()

	@Namespace private var namespace

	@State private var keyboardVisible = false

	private var filteredTransactions: [Transaction] {
		if searchText.isEmpty {
			return transactionRepo.transactions
		}
		return transactionRepo.transactions.filter { transaction in
			transaction.title.localizedCaseInsensitiveContains(searchText)
		}
	}

	var body: some View {
		NavigationStack(path: $navigationPath) {
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

									Text(
										transaction.change,
										format: .currency(code: "AUD")
									)
									.foregroundStyle(
										transaction.change > 0 ? .green : .red
									)
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
								do {
									try await transactionRepo.delete(ids: ids)
								} catch {
									errorMessage = error.localizedDescription
								}
							}
						}
					}
				}
				.searchable(text: $searchText, prompt: isiPhone() ? "Search transactions" : "Search")
				.tint(.secondary)
				.refreshable {
					Task {
						await refresh()
					}
				}
				.animation(.easeInOut, value: filteredTransactions.count)
				.transition(.blurReplace)
			}
			.navigationDestination(for: TransactionRoute.self) { route in
				switch route {
					case let .detail(transactionID):
						if let transaction = transactionRepo.transactions.first(where: { $0.id == transactionID }) {
							TransactionDetailView(isNew: false, transaction: transaction)
						} else {
							ContentUnavailableView("Transaction Not Found", systemImage: "magnifyingglass")
						}
				}
			}
			.sheet(isPresented: $showAddTransaction) {
				TransactionDetailView(isNew: true)
					.presentationDragIndicator(.hidden)
				#if os(iOS)
					.navigationTransition(
						.zoom(sourceID: "unique_transition_id", in: namespace)
					)
				#endif
			}
			.animation(.easeInOut, value: filteredTransactions.isEmpty)
			.toolbar { toolbarContent }
			.toolbar {
				#if os(iOS)
					ToolbarItem(placement: .topBarTrailing) {
						Button {
							showAddTransaction = true
						} label: {
							Label("Add Transaction", systemImage: "plus")
						}
						.buttonStyle(.glassProminent)
						.foregroundStyle(.black)
					}
					.matchedTransitionSource(id: "unique_transition_id", in: namespace)

					if !transactionRepo.transactions.isEmpty {
						ToolbarItem(placement: .topBarTrailing) {
							EditButton()
						}

						ToolbarSpacer(placement: .topBarTrailing)
					}
				#endif // os(iOS)

				ToolbarItem(placement: .topBarTrailing) {
					RefreshButton(
						isLoading: $isLoading,
						showSuccess: $showSuccess
					) {
						await refresh()
					}
				}
			}
			.animation(.easeInOut, value: keyboardVisible)
			.task {
				await handlePendingTransactionRoute()
			}
			.onChange(of: appRouter.pendingTransactionID) { oldValue, newValue in
				guard oldValue != newValue else { return }
				Task {
					await handlePendingTransactionRoute()
				}
			}
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
		#endif // os(iOS)
		#if os(iOS)
		.enableInjection()
		#endif
	}

	#if DEBUG && os(iOS)
		@ObserveInjection var forceRedraw
	#endif

	private func handlePendingTransactionRoute() async {
		guard let transactionID = appRouter.pendingTransactionID else { return }

		await openTransaction(transactionID)

		if !transactionRepo.transactions.contains(where: { $0.id == transactionID }) {
			try? await transactionRepo.syncTransactions()
		}

		appRouter.pendingTransactionID = nil
	}

	private func openTransaction(_ transactionID: UUID) async {
		navigationPath = NavigationPath()
		await Task.yield()
		navigationPath.append(TransactionRoute.detail(transactionID))
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
