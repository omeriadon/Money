import SwiftUI

struct GoalDetailView: View {
	@Environment(GoalRepository.self) var goalRepo
	@Environment(\.dismiss) private var dismiss

	@State private var name = ""
	@State private var description = ""
	@State private var goalAmount: Double = 100

	@State private var isLoading = false
	@State private var errorMessage = ""
	@State private var showError = false

	@FocusState private var focusedField: Field?

	let isNew: Bool
	let goal: Goal?

	enum Field: Hashable {
		case name, description, amount
	}

	init(isNew: Bool, goal: Goal? = nil) {
		self.isNew = isNew
		self.goal = goal
	}

	var body: some View {
		Group {
			if isNew {
				NavigationStack {
					formContent
				}
			} else {
				formContent
			}
		}
		#if os(iOS)
		.enableInjection()
		#endif
	}

	private var formContent: some View {
		VStack {
			form
		}
		.onAppear {
			if let goal {
				name = goal.name
				description = goal.desc
				goalAmount = abs(goal.goalAmount)
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
					Task { await submitGoal() }
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
						name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
						goalAmount == 0 ||
						(goal != nil &&
							name == goal!.name &&
							description == goal!.desc &&
							abs(goalAmount) == abs(goal!.goalAmount))
				)
				.buttonStyle(.glassProminent)
				.buttonBorderShape(.circle)
			}
		}
		.alert(isPresented: $showError) {
			Alert(
				title: Text(isNew ? "Error Adding Goal" : "Error Updating Goal"),
				message: Text(errorMessage),
				dismissButton: .default(Text("OK"))
			)
		}
	}

	#if DEBUG && os(iOS)
		@ObserveInjection var forceRedraw
	#endif

	private var form: some View {
		List {
			Section {
				TextField("Goal Name", text: $name)
					.focused($focusedField, equals: .name)
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

				TextField("Goal Amount", value: $goalAmount, format: .currency(code: "AUD"))
					.multilineTextAlignment(.trailing)
					.focused($focusedField, equals: .amount)
					.onSubmit { focusedField = nil }
					.onChange(of: goalAmount) {
						goalAmount = abs(goalAmount)
					}
				#if os(iOS)
					.listRowBackground(Color(uiColor: .quaternarySystemFill))
					.keyboardType(.decimalPad)
				#endif
			}

			if let dateCreated = goal?.dateCreated {
				Section("Created") {
					Text(dateCreated, format: .dateTime.minute().hour().day().month().year())
					#if os(iOS)
						.listRowBackground(Color(uiColor: .quaternarySystemFill))
					#endif
				}
			}
			if let dateUpdated = goal?.dateUpdated {
				if dateUpdated != goal?.dateCreated {
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

	private func submitGoal() async {
		isLoading = true
		errorMessage = ""
		let cleanedAmount = abs(goalAmount)

		do {
			if isNew {
				try await goalRepo.createGoal(
					name: name,
					description: description,
					goalAmount: cleanedAmount
				)
			} else if let goal {
				try await goalRepo.updateGoal(
					id: goal.id,
					name: name != goal.name ? name : nil,
					description: description != goal.desc ? description : nil,
					goalAmount: cleanedAmount != abs(goal.goalAmount) ? cleanedAmount : nil
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
