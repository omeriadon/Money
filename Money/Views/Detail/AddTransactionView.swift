import SwiftData
import SwiftUI

struct AddTransactionView: View {
	@EnvironmentObject var networkManager: NetworkManager
	@Environment(\.modelContext) private var modelContext
	@Environment(\.dismiss) private var dismiss

	let positive: Bool

	@State private var title = ""
	@State private var description = ""
	@State private var amount: Double = 50
	@State private var isPositive: Bool
	@State private var importance: Importance = .essential

	@State private var change: Double = 0
	@State private var isLoading = false
	@State private var errorMessage = ""
	@State private var showError = false

	init(positive: Bool) {
		self.positive = positive
		_isPositive = State(initialValue: positive)
		_amount = State(initialValue: 50)
		_change = State(initialValue: positive ? 50 : -50)
	}

	var currencyFormatter: NumberFormatter {
		let formatter = NumberFormatter()
		formatter.numberStyle = .currency
		formatter.currencyCode = "AUD"
		return formatter
	}

	var body: some View {
		NavigationStack {
			form
				.alert("Error Adding Transaction", isPresented: $showError) {
					Button("OK", role: .cancel) {}
				} message: {
					Text(errorMessage)
				}
				.scrollContentBackground(.hidden)
				.background(
					Rectangle()
						.fill(change >= 0 ? Color.green.opacity(0.3) : Color.red.opacity(0.3))
						.animation(.easeInOut, value: change)
						.ignoresSafeArea()
				)
				.toolbar {
					ToolbarItem(placement: .topBarTrailing) {
						Button(role: .close) { dismiss() }
					}
				}
				.safeAreaBar(edge: .bottom, alignment: .center, spacing: 30) {
					Button {
						updateChange()
						Task { await submitTransaction() }
					} label: {
						if isLoading {
							ProgressView()
						} else {
							Text("Add Transaction")
								.padding(.vertical, 10)
								.padding(.horizontal, 15)
								.foregroundStyle((isLoading || title.isEmpty || change == 0) ? .black : .primary)
						}
					}
					.disabled(isLoading || title.isEmpty || change == 0)
					.buttonStyle(.glassProminent)
					.padding(.bottom)
					.tint(change >= 0 ? Color.green : Color.red)
				}
		}
	}

	var form: some View {
		Form {
			Section("Transaction") {
				TextField("Title", text: $title)
				TextField("Description", text: $description)

				HStack {
					Picker("", selection: $isPositive) {
						Image(systemName: "plus.circle.fill")
							.tag(true)
						Image(systemName: "minus.circle.fill")
							.tag(false)
					}
					.pickerStyle(.segmented)
					.frame(width: 100)
					.onChange(of: isPositive) {
						updateChange()
					}

					Spacer()

					TextField("Amount", value: $amount, formatter: currencyFormatter)
						.keyboardType(.numberPad)
						.multilineTextAlignment(.trailing)
						.onSubmit {
							updateChange()
						}
						.frame(maxWidth: 120)
						.padding(5)
						.glassEffect(.clear.interactive(), in: RoundedRectangle(cornerRadius: 12))
						.scrollDismissesKeyboard(.immediately)
						.font(.title3)
				}

				Picker("Importance", selection: $importance) {
					ForEach(Importance.allCases) { importance in
						Label(importance.rawValue.capitalized, systemImage: importance.symbol)
							.labelIconToTitleSpacing(50)
							.tag(importance)
							.fontDesign(.monospaced)
					}
				}
				.pickerStyle(.menu)
			}
			.listRowBackground(Rectangle().fill(.regularMaterial))
		}
	}

	private func updateChange() {
		change = isPositive ? amount : -amount
	}

	@MainActor
	func submitTransaction() async {
		isLoading = true
		errorMessage = ""

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
			showError = true
		}
	}
}
