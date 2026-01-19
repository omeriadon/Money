import SwiftData
import SwiftUI

struct TransactionDetailView: View {
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

	let isNew: Bool
	let transaction: Transaction?

	enum Field: Hashable {
		case title, description, amount
	}

	init(isNew: Bool, transaction: Transaction? = nil) {
		self.isNew = isNew
		self.transaction = transaction
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
			.onAppear {
				if let t = transaction {
					title = t.title
					description = t.desc
					change = Double(t.change)
					isPositive = t.change >= 0
					amount = abs(Double(t.change))
					importance = t.importance
				}
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
							Label(isNew ? "Add" : "Update", systemImage: isNew ? "plus" : "pencil")
						}
					}
					.disabled(
						isLoading ||
							title.isEmpty ||
							change == (transaction != nil ? Double(transaction!.change) : 0)
					)
					.buttonStyle(.glassProminent)
				}
			}
			.alert(isPresented: $showError) {
				Alert(
					title: Text(isNew ? "Error Adding Transaction" : "Error Updating Transaction"),
					message: Text(errorMessage),
					dismissButton: .default(Text("OK"))
				)
			}
		}
	}

	// MARK: - Form

	@ViewBuilder
	var form: some View {
		HStack {
			Picker("", selection: $isPositive) {
				Image(systemName: "plus.circle.fill").tag(true)
				Image(systemName: "minus.circle.fill").tag(false)
			}
			.pickerStyle(.segmented)
			.controlSize(.extraLarge)
			.font(.largeTitle)
			.onChange(of: isPositive) { updateChange() }

			Spacer()

			TextField("Amount", value: $amount, format: .currency(code: "AUD"))
				.keyboardType(.numberPad)
				.multilineTextAlignment(.trailing)
				.focused($focusedField, equals: .amount)
				.onSubmit { focusedField = nil }
				.onChange(of: amount) { updateChange() }
				.frame(maxWidth: 150)
				.padding(5)
				.glassEffect(.clear.tint(isPositive ? .green : .red).interactive(), in: RoundedRectangle(cornerRadius: 30))
				.animation(.easeInOut, value: isPositive)
				.font(.title)
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

	func submitTransaction() async {
		isLoading = true
		errorMessage = ""
		let finalChange = isPositive ? amount : -amount

		do {
			if isNew {
				_ = try await networkManager.createTransaction(
					change: finalChange,
					title: title,
					description: description,
					importance: importance
				)
			} else if let t = transaction {
				let oldChange = Double(t.change)
				let newChange = Int(finalChange)
				_ = try await networkManager.updateTransaction(
					id: t.id,
					change: newChange != Int(oldChange) ? newChange : nil,
					title: title != t.title ? title : nil,
					description: description != (t.desc) ? description : nil,
					importance: importance != t.importance ? importance : nil
				)
			}

			isLoading = false
			dismiss()
		} catch {
			isLoading = false
			errorMessage = error.localizedDescription
			showError = true
		}
	}
}
