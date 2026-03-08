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
										Image(systemName: "target")
										Text(goal.name)
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
									Button(role: .destructive) {
										Task {
											do { try await goalRepo.delete(ids: [goal.id]) }
											catch { errorMessage = error.localizedDescription }
										}
									} label: {
										Label("Delete", systemImage: "trash")
											.tint(.red)
									}
								} preview: {
									VStack(alignment: .leading, spacing: 12) {
										Text(goal.name)
											.font(.title)
											.padding(.bottom)

										Text(goal.goalAmount, format: .currency(code: "AUD"))
											.font(.title2.bold())
											.foregroundStyle(.yellow)

										Gauge(value: min(transactionRepo.total / goal.goalAmount, 1.0)) {
											EmptyView()
										}
										.tint(.yellow)

										Text(transactionRepo.total / abs(goal.goalAmount), format: .percent.precision(.fractionLength(0)))
											.font(.title2)
											.foregroundStyle(.yellow)
									}
									.padding()
									.fontDesign(fontDesignStyle.fontDesign)
									.frame(minWidth: 100)
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
