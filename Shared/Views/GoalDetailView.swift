#if os(iOS)
	#if canImport(ColorfulX)
		import ColorfulX
	#endif
	#if canImport(ConfettiSwiftUI)
		import ConfettiSwiftUI
	#endif
#endif
import SwiftUI

struct GoalSubmitButton: View {
	let isLoading: Bool
	let isNew: Bool

	var body: some View {
		if isLoading {
			ProgressView()
				.transition(.blurReplace)
		} else if isNew {
			Label("Add", systemImage: "plus")
				.transition(.blurReplace)
		} else {
			Label("Update", systemImage: "pencil")
				.transition(.blurReplace)
		}
	}
}

struct GoalDetailView: View {
	@Environment(\.repositories) private var repositories
	@Environment(\.dismiss) private var dismiss

	private var goalRepo: GoalRepository {
		repositories.goalRepo
	}

	@State private var name = ""
	@State private var description = ""
	@State private var goalAmount: Double = 100
	@State private var status: Goal.GoalStatus = .active
	@State private var isArchived = false
	@State private var confettiCounter = 0
	@State private var showCompletedBackground = false

	@State private var isLoading = false
	@State private var errorMessage = ""
	@State private var showError = false

	@FocusState private var focusedField: Field?

	@State var animatedGoalAmount = 0.0

	#if os(iOS) && canImport(ColorfulX)
		@State private var frameLimit: Int = 120
		@State private var renderScale: Double = 1.0
		@State private var completedColors: [Color] = [.yellow, .green, .red, .blue, .yellow]
		@State private var completedSpeed: Double = 1
		@State private var completedBias: Double = 0.01
		@State private var completedNoise: Double = 60
		@State private var completedTransition: Double = 10
	#endif

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
		#if os(iOS) && canImport(ConfettiSwiftUI)
		.confettiCannon(
			trigger: $confettiCounter,
			num: 60,
			confettis: [
				.sfSymbol(symbolName: "dollarsign.circle.fill"),
				.sfSymbol(symbolName: "target"),
				.sfSymbol(symbolName: "trophy.fill"),
				.sfSymbol(symbolName: "star.circle.fill"),
				.sfSymbol(symbolName: "checkmark.circle.fill"),
			],
			colors: [.yellow, .green, .red, .blue],
			rainHeight: 600,
			openingAngle: .degrees(30),
			closingAngle: .degrees(150),
			radius: 400
		)
		#endif // os(iOS) && canImport(ConfettiSwiftUI)
		#if os(iOS)
		.enableInjection()
		#endif
	}

	private var formContent: some View {
		VStack {
			form
		}
		.background {
			#if os(iOS) && canImport(ColorfulX)
				if showCompletedBackground {
					ColorfulView(
						color: $completedColors,
						speed: $completedSpeed,
						bias: $completedBias,
						noise: $completedNoise,
						transitionSpeed: $completedTransition,
						frameLimit: $frameLimit,
						renderScale: $renderScale
					)
					.opacity(0.8)
					.saturation(1.2)
					.transition(.opacity.animation(.easeInOut(duration: 0.35)))
					.ignoresSafeArea()
				}
			#endif
		}
		.animation(.easeInOut(duration: 0.35), value: showCompletedBackground)
		.onAppear {
			if let goal {
				name = goal.name
				description = goal.desc
				goalAmount = abs(goal.goalAmount)
				status = goal.status
				showCompletedBackground = goal.status == .completed
				isArchived = goal.isArchived
				if goal.status == .completed {
					Task {
						try? await Task.sleep(nanoseconds: 200_000_000)
						confettiCounter += 1
					}
				}
			}
		}
		.onChange(of: status) { _, newStatus in
			showCompletedBackground = newStatus == .completed
			if newStatus == .completed {
				confettiCounter += 1
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
					GoalSubmitButton(isLoading: isLoading, isNew: isNew)
				}
				.animation(.easeInOut, value: "\(isLoading)\(isNew)")
				.disabled(
					isLoading ||
						name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
						goalAmount == 0 ||
						(goal != nil &&
							name == goal!.name &&
							description == goal!.desc &&
							abs(goalAmount) == abs(goal!.goalAmount) &&
							status == goal!.status &&
							isArchived == goal!.isArchived)
				)
				.buttonStyle(.glassProminent)
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
			if !isNew {
				Section("Progress") {
					HStack {
						Text("\(Text(repositories.transactionRepo.total, format: .currency(code: "AUD").precision(.significantDigits(2))))")

						Gauge(
							value: animatedGoalAmount
						) {
							EmptyView()
						}
						.gaugeStyle(.linearCapacity)

						Text("\(Text(goalAmount, format: .currency(code: "AUD").precision(.significantDigits(2))))")
					}
					.onAppear {
						Task {
							try? await Task.sleep(nanoseconds: 200_000_000)
							withAnimation(.easeInOut(duration: 0.5)) {
								animatedGoalAmount = min(repositories.transactionRepo.total / goalAmount, 1)
							}
						}
					}
					.listRowBackground(Rectangle().fill(.thinMaterial))
				}
			}

			Section {
				TextField("Goal Name", text: $name)
					.focused($focusedField, equals: .name)
					.onSubmit { focusedField = .description }
					.listRowBackground(Rectangle().fill(.thinMaterial))

				TextField("Description", text: $description)
					.focused($focusedField, equals: .description)
					.onSubmit { focusedField = .amount }
					.listRowBackground(Rectangle().fill(.thinMaterial))

				TextField("Goal Amount", value: $goalAmount, format: .currency(code: "AUD"))
					.multilineTextAlignment(.trailing)
					.focused($focusedField, equals: .amount)
					.onSubmit { focusedField = nil }
					.onChange(of: goalAmount) {
						goalAmount = abs(goalAmount)
					}
				#if os(iOS)
					.keyboardType(.decimalPad)
				#endif
					.listRowBackground(Rectangle().fill(.thinMaterial))
			}

			Section("Status") {
				ValuePicker("Status", selection: $status) {
					HStack {
						Image(systemName: status.symbol)
						Text(status.title)
							.padding(.trailing, 10)
						Image(systemName: "chevron.up.chevron.down")
					}
				} content: {
					ForEach(Goal.GoalStatus.allCases.filter { $0 != .archived }, id: \.self) { goalStatus in
						Label(goalStatus.title, systemImage: goalStatus.symbol)
							.labelIconToTitleSpacing(12)
							.pickerTag(goalStatus)
					}
				}
				.listRowBackground(Rectangle().fill(.thinMaterial))
			}
			if !isNew {
				Section("Archive") {
					Toggle(isOn: $isArchived) {
						if isArchived {
							Label("Archived", systemImage: "archivebox.fill")
								.transition(.blurReplace)
						} else {
							Label("Archived", systemImage: "archivebox")
								.transition(.blurReplace)
						}
					}
					.animation(.easeInOut, value: isArchived)
					.listRowBackground(Rectangle().fill(.thinMaterial))
				}
			}

			if let dateCreated = goal?.dateCreated {
				Section("Created") {
					Text(dateCreated, format: .dateTime.minute().hour().day().month().year())
						.listRowBackground(Rectangle().fill(.thinMaterial))
				}
			}
			if let dateUpdated = goal?.dateUpdated {
				if dateUpdated != goal?.dateCreated {
					Section("Updated") {
						Text(dateUpdated, format: .dateTime.minute().hour().day().month().year())
							.listRowBackground(Rectangle().fill(.thinMaterial))
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
					goalAmount: cleanedAmount,
					status: status,
					isArchived: isArchived
				)
			} else if let goal {
				try await goalRepo.updateGoal(
					id: goal.id,
					name: name != goal.name ? name : nil,
					description: description != goal.desc ? description : nil,
					goalAmount: cleanedAmount != abs(goal.goalAmount) ? cleanedAmount : nil,
					status: status != goal.status ? status : nil,
					isArchived: isArchived != goal.isArchived ? isArchived : nil
				)
			}

			isLoading = false
			dismiss()
			focusedField = .none
		} catch {
			isLoading = false
			errorMessage = error.localizedDescription
			showError = true
		}
	}
}
