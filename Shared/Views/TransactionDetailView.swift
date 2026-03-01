
import SwiftUI

struct TransactionDetailView: View {
	@EnvironmentObject var networkManager: NetworkManager
	@Environment(TransactionRepository.self) var transactionRepo
	@Environment(\.colorScheme) var colorScheme

	@Environment(\.dismiss) private var dismiss

	@State private var title = ""
	@State private var description = ""
	@State private var amount: Double = 50
	@State private var isPositive = true
	@State private var importance: Importance = .dayJob

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
				if let change = transaction?.change {
					isPositive = change > 0.0
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
								importance == transaction!.importance) ||
							change == 0.0
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
		#if os(iOS)
		.enableInjection()
		#endif
	}

	#if DEBUG && os(iOS)
		@ObserveInjection var forceRedraw
	#endif

	@ViewBuilder
	var picker: some View {
		Picker("", selection: $isPositive) {
			Image(systemName: "plus.circle.fill").tag(true)
			Image(systemName: "minus.circle.fill").tag(false)
		}
		.onChange(of: isPositive) { updateChange() }
		#if os(iOS)
			.pickerStyle(.segmented)
			.controlSize(.extraLarge)
			.font(.largeTitle)
		#else
			.pickerStyle(.wheel)
			.font(.title2)
			.defaultWheelPickerItemHeight(30)
			.frame(height: 60)
		#endif
	}

	@ViewBuilder
	var textField: some View {
		TextField("Amount", value: $amount, format: .currency(code: "AUD"))
			.multilineTextAlignment(.trailing)
			.focused($focusedField, equals: .amount)
			.onSubmit { focusedField = nil }
			.onChange(of: amount) { updateChange() }
		#if os(iOS)
			.frame(maxWidth: 150)
			.padding(5)
			.controlSize(.extraLarge)
			.foregroundStyle(.white)
			.font(.title)
			.glassEffect(.clear.tint(isPositive ? .green : .red).interactive(), in: Capsule())
			.keyboardType(.decimalPad)
		#else
			.font(.title)
			.foregroundStyle(isPositive ? .green : .red)
			.frame(height: 20)
			.padding(.horizontal)
		#endif
			.animation(.easeInOut, value: isPositive)
	}

	var iPhoneHeader: some View {
		HStack {
			picker
			Spacer()
			textField
		}
		.padding(.horizontal)
		.padding(.top)
	}

	@ViewBuilder
	var form: some View {
		#if os(iOS)
			iPhoneHeader
		#endif

		List {
			if !isiPhone() {
				Section {
					picker
						.listRowBackground(Color.clear)
				}
				Section {
					textField
						.listRowBackground(Color.clear)
				}
			}

			Section {
				TextField("Title", text: $title)
					.focused($focusedField, equals: .title)
					.onSubmit { focusedField = .description }
				#if os(iOS)
					.listRowBackground(Color(uiColor: .quaternarySystemFill))
				#endif

				TextField("Description", text: $description)
					.focused($focusedField, equals: .description)
					.onSubmit { focusedField = .amount }
				#if os(iOS)
					.listRowBackground(Color(uiColor: .quaternarySystemFill))
				#endif

				ValuePicker("Importance", selection: $importance) {
					HStack {
						Image(systemName: importance.symbol)
						Text(importance.title)
							.fontDesign(.monospaced)
							.padding(.trailing, 10)
						Image(systemName: "chevron.up.chevron.down")
					}
				} content: {
					ForEach(isPositive ? Importance.positive : Importance.negative) { item in
						Label(item.title, systemImage: item.symbol)
							.pickerTag(item)
					}
				}
				.onChange(of: isPositive) {
					if isPositive {
						if Importance.negative.contains(importance) {
							importance = Importance.positive.randomElement()!
						}
					} else {
						if Importance.positive.contains(importance) {
							importance = Importance.negative.randomElement()!
						}
					}
				}
				#if os(iOS)
				.listRowBackground(Color(uiColor: .quaternarySystemFill))
				#endif
			}
			if let dateCreated = transaction?.dateCreated {
				Section("Created") {
					Text(dateCreated, format: .dateTime.minute().hour().day().month().year())
					#if os(iOS)
						.listRowBackground(Color(uiColor: .quaternarySystemFill))
					#endif
				}
			}
			if let dateUpdated = transaction?.dateUpdated {
				if dateUpdated != transaction?.dateCreated {
					Section("Updated") {
						Text(dateUpdated, format: .dateTime.minute().hour().day().month().year())
						#if os(iOS)
							.listRowBackground(Color(uiColor: .quaternarySystemFill))
						#endif
					}
				}
			}
		}
		.scrollContentBackground(.hidden)
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

			isLoading = false
			dismiss()
		} catch {
			isLoading = false
			errorMessage = error.localizedDescription
			showError = true
		}
	}
}
