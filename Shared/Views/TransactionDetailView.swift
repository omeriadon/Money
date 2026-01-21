
import SwiftUI

struct TransactionDetailView: View {
	@EnvironmentObject var networkManager: NetworkManager
	@EnvironmentObject var transactionRepo: TransactionRepository

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
				if isNew {
					ToolbarItem(placement: .topBarLeading) {
						Button(role: .cancel) { dismiss() }
					}
				}

				ToolbarItem(placement: .topBarTrailing) {
					Button {
						Task { await submitTransaction() }
					} label: {
						if isLoading {
							ProgressView()
						} else {
							Label(isNew ? "Add" : "Update", systemImage: isNew ? "plus" : "pencil")
								.labelStyle(.iconOnly)
						}
					}
					.disabled(
						isLoading ||
							title.isEmpty ||
							(transaction != nil &&
								title == transaction!.title &&
								description == transaction!.desc &&
								change == transaction!.change &&
								importance == transaction!.importance)
					)
					.buttonStyle(.glassProminent)
					.buttonBorderShape(.circle)
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

	@ViewBuilder
	var form: some View {
		HStack(alignment: .center) {
			Picker("", selection: $isPositive) {
				Image(systemName: "plus.circle.fill").tag(true)
				Image(systemName: "minus.circle.fill").tag(false)
			}
			.onChange(of: isPositive) { updateChange() }
			#if os(iOS)
				.pickerStyle(.segmented)
				.controlSize(.large)
				.font(.largeTitle)

			#else
				.pickerStyle(.inline)
				.font(.title2)
				.controlSize(.mini)
				.defaultWheelPickerItemHeight(40)
			#endif

			Spacer()

			TextField("Amount", value: $amount, format: .currency(code: "AUD"))
				.multilineTextAlignment(.trailing)
				.focused($focusedField, equals: .amount)
				.onSubmit { focusedField = nil }
				.onChange(of: amount) { updateChange() }
				.animation(.easeInOut, value: isPositive)
			#if os(iOS)
				.frame(maxWidth: 150)
				.padding(5)
				.font(.title)
				.glassEffect(.clear.tint(isPositive ? .green : .red).interactive(), in: RoundedRectangle(cornerRadius: 30))
				.keyboardType(.numberPad)
			#else
				.foregroundStyle(isPositive ? .green : .red)
				.frame(height: 30)
				.controlSize(.mini)
			#endif
		}
		#if os(iOS)
		.padding(.horizontal)
		.padding(.top)
		#else
		.frame(height: 50)
		#endif

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
							.fontDesign(.monospaced)
							.tag(importance)
					}
				}
				.foregroundStyle(.primary)
				.tint(.primary)
				#if os(iOS)
					.pickerStyle(.menu)
				#endif
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
				try await transactionRepo.createTransaction(
					change: finalChange,
					title: title,
					description: description,
					importance: importance
				)
			} else if let t = transaction {
				let oldChange = t.change
				let newChange = finalChange
				try await transactionRepo.updateTransaction(
					id: t.id,
					change: (newChange != oldChange) ? newChange : nil,
					title: title != t.title ? title : nil,
					description: description != t.desc ? description : nil,
					importance: importance != t.importance ? importance : nil
				)
			}

			// sync local array with remote
			try await transactionRepo.syncTransactions()

			isLoading = false
			dismiss()
		} catch {
			isLoading = false
			errorMessage = error.localizedDescription
			showError = true
		}
	}
}
