//
//  TransactionAddView.swift
//  Money
//
//  Created by Adon Omeri on 19/1/2026.
//

import SwiftData
import SwiftUI

struct AddTransactionView: View {
	@EnvironmentObject var networkManager: NetworkManager
	@Environment(\.modelContext) private var modelContext
	@Environment(\.dismiss) private var dismiss

	let positive: Bool

	@State private var title = ""
	@State private var description = ""
	@State private var change = 0.0
	@State private var importance: Importance = .essential

	@State private var isLoading = false
	@State private var errorMessage: String?

	@State private var changeText: String = "0"

	var body: some View {
		NavigationStack {
			Form {
				Section("Transaction") {
					TextField("Title", text: $title)
					TextField("Description", text: $description)

					HStack {
						TextField("", text: $changeText)
							.contentTransition(.numericText())
							.keyboardType(.numbersAndPunctuation)
							.multilineTextAlignment(.trailing)
							.frame(width: 80)
							.onChange(of: changeText) {
								if let value = Double(changeText.replacingOccurrences(of: "+", with: "")) {
									change = value
								}
							}

						Spacer()

						Stepper("", value: $change, step: 10)
							.labelsHidden()
							.onChange(of: change) {
								changeText = String(format: "%.0f", change)
							}
					}

					Picker("Importance", selection: $importance) {
						ForEach(Importance.allCases) { importance in
							Label(importance.rawValue.capitalized, systemImage: importance.symbol).tag(importance)
								.labelIconToTitleSpacing(50)
								.tint(change >= 0 ? Color.green : Color.red)
						}
					}
					.pickerStyle(.menu)
				}
				.listRowBackground(Rectangle().fill(.regularMaterial))

				if let error = errorMessage {
					Section {
						Text(error)
							.foregroundStyle(.red)
					}
					.listRowBackground(Rectangle().fill(.regularMaterial))
				}

				Section {
					Button {
						Task { await submitTransaction() }
					} label: {
						if isLoading {
							ProgressView()
						} else {
							Text("Add Transaction")
						}
					}
					.disabled(isLoading || title.isEmpty || change == 0)
					.buttonStyle(.glassProminent)
				}
				.listRowBackground(Rectangle().fill(.regularMaterial))
			}
			.scrollContentBackground(.hidden)
			.background(
				Rectangle()
					.fill(change >= 0 ? Color.green.opacity(0.3) : Color.red.opacity(0.3))
					.animation(.easeInOut, value: change)
					.ignoresSafeArea()
			)
			.task {
				if positive {
					change = 50
				} else {
					change = -50
				}
			}
			.toolbar {
				ToolbarItem(placement: .topBarTrailing) {
					Button(role: .close) { dismiss() }
				}
			}
		}
	}

	@MainActor
	func submitTransaction() async {
		isLoading = true
		errorMessage = nil

		do {
			_ = try await networkManager.createTransaction(
				change: change,
				title: title,
				description: description,
				importance: importance
			)

			isLoading = false
			dismiss()
		} catch {
			isLoading = false
			errorMessage = error.localizedDescription
		}
	}
}
