import SwiftData
import SwiftUI

struct AddTransactionView: View {
	@EnvironmentObject var networkManager: NetworkManager
	@Environment(\.modelContext) private var modelContext
	@Environment(\.dismiss) private var dismiss

	@State private var title = ""
	@State private var description = ""
	@State private var amount: Double = 50
	@State private var isPositive = true
	@State private var importance: Importance = .essential

	@State private var change: Double = 50
	@State private var isLoading = false
	@State private var errorMessage = ""
	@State private var showError = false

	@FocusState private var focusedField: Field?

	enum Field: Hashable {
		case title, description, amount
	}

	var currencyFormatter: NumberFormatter {
		let formatter = NumberFormatter()
		formatter.numberStyle = .currency
		formatter.currencyCode = "AUD"
		formatter.maximumFractionDigits = 0
		return formatter
	}

	var body: some View {
		NavigationStack {
			VStack {
				form
			}
			.toolbar {
				ToolbarItem(placement: .topBarLeading) {
					Button(role: .cancel) { dismiss() }
				}

				ToolbarItem(placement: .topBarTrailing) {
					Button {
						Task { await submitTransaction() }
					} label: {
						if isLoading {
							ProgressView()
						} else {
							Label("Add", systemImage: "plus")
						}
					}
					.disabled(isLoading || title.isEmpty || change == 0)
					.buttonStyle(.glassProminent)
				}
			}
			.alert("Error Adding Transaction", isPresented: $showError) {
				Button("OK", role: .cancel) {}
			} message: {
				Text(errorMessage)
			}
		}
	}

	@ViewBuilder
	var form: some View {
		HStack {
			Picker("", selection: $isPositive) {
				Image(systemName: "plus.circle.fill")
					.tag(true)
				Image(systemName: "minus.circle.fill")
					.tag(false)
			}
			.pickerStyle(.segmented)
			.onChange(of: isPositive) {
				updateChange()
			}
			.controlSize(.extraLarge)
			.font(.largeTitle)

			Spacer()

			TextField("Amount", value: $amount, format: .currency(code: "AUD"))
				.keyboardType(.numberPad)
				.multilineTextAlignment(.trailing)
				.focused($focusedField, equals: .amount)
				.onSubmit {
					updateChange()
					focusedField = nil
				}
				.frame(maxWidth: 150)
				.padding(5)
				.glassEffect(.clear.tint(isPositive ? .green : .red).interactive(), in: RoundedRectangle(cornerRadius: 12))
				.animation(.easeInOut, value: isPositive)
				.font(.title)
				.onAppear {
					focusedField = .title
				}
		}
		.padding(.horizontal)
		.padding(.top)

		Form {
			Section {
				TextField("Title", text: $title)
					.focused($focusedField, equals: .title)
					.onSubmit { focusedField = .description }

				TextField("Description", text: $description)
					.focused($focusedField, equals: .description)
					.onSubmit { focusedField = .amount }

				Picker("Importance", selection: $importance) {
					ForEach(Importance.allCases) { importance in
						Label(importance.rawValue.capitalized, systemImage: importance.symbol)
							.labelIconToTitleSpacing(50)
							.fontDesign(.monospaced)
							.tag(importance)
					}
				}
				.pickerStyle(.menu)
				.foregroundStyle(.primary)
				.tint(.primary)
			}
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

#Preview {
	AddTransactionView()
		.environmentObject(NetworkManager.shared)
}
