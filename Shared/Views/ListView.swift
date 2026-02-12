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
	@EnvironmentObject var transactionRepo: TransactionRepository

	@State private var isLoading = false
	@State private var showSuccess = false
	@State private var errorMessage: String?
	@State private var searchText = ""

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
		NavigationStack {
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
							NavigationLink {
								TransactionDetailView(
									isNew: false,
									transaction: transaction
								)
							} label: {
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
				.refreshable {
					Task {
						await refresh()
					}
				}
				.animation(.easeInOut, value: filteredTransactions.count)
				.transition(.blurReplace)
			}
			.searchable(text: $searchText, prompt: isiPhone() ? "Search transactions" : "Search")
			.animation(.easeInOut, value: filteredTransactions.isEmpty)
			.toolbar { toolbarContent }
			.toolbar {
				#if os(iOS)
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
