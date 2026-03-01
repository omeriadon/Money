import SwiftUI

struct GoalListView: View {
	private enum GoalRoute: Hashable {
		case detail(UUID)
	}

	@Environment(GoalRepository.self) var goalRepo
	@Environment(AppRouter.self) var appRouter

	@State private var isLoading = false
	@State private var showSuccess = false
	@State private var errorMessage: String?
	@State private var searchText = ""
	@State private var showAddGoal = false
	@State private var navigationPath = NavigationPath()

	@Namespace private var namespace

	private var hasNoItems: Bool {
		goalRepo.goals.isEmpty
	}

	private var hasNoSearchResults: Bool {
		!searchText.isEmpty && filteredGoals.isEmpty
	}

	private var filteredGoals: [Goal] {
		if searchText.isEmpty {
			return goalRepo.goals
		}
		return goalRepo.goals.filter { goal in
			goal.name.localizedCaseInsensitiveContains(searchText)
				|| goal.desc.localizedCaseInsensitiveContains(searchText)
		}
	}

	var body: some View {
		NavigationStack(path: $navigationPath) {
			ZStack {
				if hasNoItems {
					VStack {
						Spacer()
						ContentUnavailableView(
							"No Goals",
							systemImage: "target"
						)
						Spacer()
					}
					.transition(.blurReplace)
				} else {
					List {
						if hasNoSearchResults {
							HStack {
								Spacer()
								ContentUnavailableView(
									"No Results",
									systemImage: "magnifyingglass"
								)
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

										Text(
											abs(goal.goalAmount),
											format: .currency(code: "AUD")
										)
										.foregroundStyle(.green)
										.font(.title3)
										.lineLimit(1)
										.minimumScaleFactor(0.01)
									}
								}
								.transition(.blurReplace)
							}
							.onDelete { indexSet in
								let ids = indexSet.map { filteredGoals[$0].id }

								Task {
									do {
										try await goalRepo.delete(ids: ids)
									} catch {
										errorMessage = error.localizedDescription
									}
								}
							}
						}
					}
					.searchable(text: $searchText, prompt: isiPhone() ? "Search goals" : "Search")
					.tint(.secondary)
//					.refreshable {
//						Task {
//							await refresh()
//						}
//					}
					.animation(.easeInOut, value: filteredGoals.count)
					.transition(.blurReplace)
				}
			}
			.navigationDestination(for: GoalRoute.self) { route in
				switch route {
					case let .detail(goalID):
						if let goal = goalRepo.goals.first(where: { $0.id == goalID }) {
							GoalDetailView(isNew: false, goal: goal)
						} else {
							ContentUnavailableView("Goal Not Found", systemImage: "target")
						}
				}
			}
			.animation(.easeInOut, value: filteredGoals.isEmpty)
			.toolbar { toolbarContent }
			.toolbar {
				#if os(iOS)
					if !goalRepo.goals.isEmpty {
						ToolbarItem(placement: .topBarTrailing) {
							EditButton()
						}

						ToolbarSpacer(placement: .topBarTrailing)
					}

					ToolbarItem(placement: .topBarTrailing) {
						Button {
							showAddGoal = true
						} label: {
							Label("Add Goal", systemImage: "plus")
						}
						.buttonStyle(.glassProminent)
						.foregroundStyle(.black)
					}
					.matchedTransitionSource(id: "unique_transition_id", in: namespace)
				#endif // os(iOS)

				ToolbarItem(placement: .topBarTrailing) {
					RefreshButton(
						isLoading: $isLoading,
						showSuccess: $showSuccess
					) {
						await refresh()
					}
				}
			}
			.sheet(isPresented: $showAddGoal) {
				GoalDetailView(isNew: true)
					.presentationDragIndicator(.hidden)
				#if os(iOS)
					.navigationTransition(
						.zoom(sourceID: "unique_transition_id", in: namespace)
					)
				#endif
			}
			.task {
				await refresh()
				await handlePendingGoalRoute()
			}
			.onChange(of: appRouter.pendingGoalID) { oldValue, newValue in
				guard oldValue != newValue else { return }
				Task {
					await handlePendingGoalRoute()
				}
			}
		}
	}

	private func handlePendingGoalRoute() async {
		guard let goalID = appRouter.pendingGoalID else { return }

		await openGoal(goalID)

		if !goalRepo.goals.contains(where: { $0.id == goalID }) {
			try? await goalRepo.syncGoals()
		}

		appRouter.pendingGoalID = nil
	}

	private func openGoal(_ goalID: UUID) async {
		navigationPath = NavigationPath()
		await Task.yield()
		navigationPath.append(GoalRoute.detail(goalID))
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
