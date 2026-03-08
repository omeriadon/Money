import Defaults
import SwiftUI

struct GoalListView: View {
	@Environment(\.repositories) private var repositories
	@Environment(AppRouter.self) var appRouter

	private var goalRepo: GoalRepository {
		repositories.goalRepo
	}

	private var transactionRepo: TransactionRepository {
		repositories.transactionRepo
	}

	@Default(.fontDesignStyle) var fontDesignStyle

	@State private var isLoading = false
	@State private var showSuccess = false
	@State private var errorMessage: String?
	@State private var showDeleteConfirmation = false
	@State private var pendingDeleteGoalID: UUID?
	@State private var searchText = ""
	@State private var showAddGoal = false

	@Namespace private var namespace

	#if os(iOS)
		@State private var editMode: EditMode = .inactive
	#endif

	private var hasNoItems: Bool {
		goalRepo.goals.isEmpty
	}

	private var hasNoSearchResults: Bool {
		!searchText.isEmpty && filteredGoals.isEmpty
	}

	private var filteredGoals: [Goal] {
		if searchText.isEmpty { return goalRepo.goals }
		return goalRepo.goals.filter {
			$0.name.localizedCaseInsensitiveContains(searchText)
				|| $0.desc.localizedCaseInsensitiveContains(searchText)
		}
	}

	private func setGoalStatus(_ goal: Goal, status: Goal.GoalStatus) {
		Task {
			do {
				try await goalRepo.setGoalStatus(id: goal.id, status: status)
			} catch {
				errorMessage = error.localizedDescription
			}
		}
	}

	private func progressForGoal(_ goal: Goal) -> Double {
		let amount = abs(goal.goalAmount)
		guard amount > 0 else { return 0 }
		return min(transactionRepo.total / amount, 1.0)
	}

	var body: some View {
		NavigationStack(path: Bindable(appRouter).goalPath) {
			ZStack {
				if hasNoItems {
					VStack {
						Spacer()
						ContentUnavailableView("No Goals", systemImage: "target")
						Spacer()
					}
					.transition(.blurReplace)
				} else {
					List {
						if hasNoSearchResults {
							HStack {
								Spacer()
								ContentUnavailableView("No Results", systemImage: "magnifyingglass")
								Spacer()
							}
							.listRowBackground(Color.clear)
						} else {
							ForEach(filteredGoals) { goal in
								NavigationLink(value: GoalRoute.detail(goal.id)) {
									HStack {
										Text(goal.name)
										Image(systemName: goal.status.symbol)
										Spacer()
										Text(abs(goal.goalAmount), format: .currency(code: "AUD"))
											.foregroundStyle(.green)
											.font(.title3)
											.lineLimit(1)
											.minimumScaleFactor(0.01)
									}
								}
								#if os(iOS)
								.contextMenu {
									Menu {
										Button {
											setGoalStatus(goal, status: .active)
										} label: {
											Label("Active", systemImage: Goal.GoalStatus.active.symbol)
										}
										.disabled(goal.status == .active)

										Button {
											setGoalStatus(goal, status: .paused)
										} label: {
											Label("Paused", systemImage: Goal.GoalStatus.paused.symbol)
										}
										.disabled(goal.status == .paused)

										Button {
											setGoalStatus(goal, status: .completed)
										} label: {
											Label("Completed", systemImage: Goal.GoalStatus.completed.symbol)
										}
										.disabled(goal.status == .completed)

										Button {
											setGoalStatus(goal, status: .archived)
										} label: {
											Label("Archived", systemImage: Goal.GoalStatus.archived.symbol)
										}
										.disabled(goal.status == .archived)
									} label: {
										Label("Status", systemImage: "flag")
									}

									Button(role: .destructive) {
										pendingDeleteGoalID = goal.id
										showDeleteConfirmation = true
									} label: {
										Label("Delete", systemImage: "trash")
											.tint(.red)
									}
								} preview: {
									VStack(alignment: .leading, spacing: 12) {
										let progress = progressForGoal(goal)
										Text(goal.name)
											.font(.title)

										Label(goal.status.title, systemImage: goal.status.symbol)
											.foregroundStyle(.secondary)
											.padding(.bottom)

										Text(goal.goalAmount, format: .currency(code: "AUD"))
											.font(.title2.bold())
											.foregroundStyle(.yellow)

										Gauge(value: progress) {
											EmptyView()
										}
										.tint(.yellow)

										Text(progress, format: .percent.precision(.fractionLength(0)))
											.font(.title2)
											.foregroundStyle(.yellow)
									}
									.padding()
									.fontDesign(fontDesignStyle.fontDesign)
									.frame(width: 160, alignment: .leading)
									.fixedSize(horizontal: true, vertical: false)
								}
								#endif
								.transition(.blurReplace)
							}
							.onDelete { indexSet in
								let ids = indexSet.map { filteredGoals[$0].id }
								Task {
									do { try await goalRepo.delete(ids: ids) }
									catch { errorMessage = error.localizedDescription }
								}
							}
						}
					}
					.searchable(text: $searchText, prompt: isiPhone() ? "Search goals" : "Search")
					.tint(.secondary)
//					.refreshable { Task { await refresh() } }
					#if os(iOS)
						.environment(\.editMode, $editMode)
					#endif
						.animation(.smooth, value: filteredGoals.count)
						.transition(.blurReplace)
				}
			}
			.navigationDestination(for: GoalRoute.self) { route in
				switch route {
					case let .detail(id):
						if let goal = goalRepo.goals.first(where: { $0.id == id }) {
							GoalDetailView(isNew: false, goal: goal)
						} else {
							ContentUnavailableView("Goal Not Found", systemImage: "target")
						}
				}
			}
			.animation(.smooth, value: filteredGoals.isEmpty)
			.toolbar { toolbarContent }
			.toolbar {
				#if os(iOS)
					if !goalRepo.goals.isEmpty {
						ToolbarItem(placement: .topBarTrailing) { CustomEditButton(editMode: $editMode) }
						ToolbarSpacer(placement: .topBarTrailing)
					}

					if !editMode.isEditing {
						ToolbarItem(placement: .topBarTrailing) {
							Button { showAddGoal = true } label: {
								Label("Add Goal", systemImage: "plus")
							}
							.buttonStyle(.glassProminent)
							.foregroundStyle(.black)
						}
						.matchedTransitionSource(id: "unique_transition_id", in: namespace)
					}
				#endif

				ToolbarItem(placement: .topBarTrailing) {
					RefreshButton(isLoading: $isLoading, showSuccess: $showSuccess) {
						await refresh()
					}
				}
			}
			.sheet(isPresented: $showAddGoal) {
				GoalDetailView(isNew: true)
					.presentationDetents([.medium])
					.presentationDragIndicator(.hidden)
				#if os(iOS)
					.navigationTransition(.zoom(sourceID: "unique_transition_id", in: namespace))
				#endif
			}
			.confirmationDialog(
				"Delete goal?",
				isPresented: $showDeleteConfirmation,
				titleVisibility: .visible
			) {
				Button("Delete", role: .destructive) {
					guard let pendingDeleteGoalID else { return }
					Task {
						do {
							try await goalRepo.delete(ids: [pendingDeleteGoalID])
							self.pendingDeleteGoalID = nil
						} catch {
							errorMessage = error.localizedDescription
						}
					}
				}
				Button("Cancel", role: .cancel) {
					pendingDeleteGoalID = nil
				}
			} message: {
				Text("This action cannot be undone.")
			}
			.task { await refresh() }
		}
	}

	private func refresh() async {
		do {
			isLoading = true
			try await goalRepo.syncGoals()
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
