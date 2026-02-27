#if canImport(Glur)
	import Glur
#endif
import SwiftUI

struct GoalListView: View {
	@EnvironmentObject var goalRepo: GoalRepository

	@State private var isLoading = false
	@State private var showSuccess = false
	@State private var errorMessage: String?
	@State private var searchText = ""
	@State private var showAddGoal = false

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
		NavigationStack {
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
								NavigationLink {
									GoalDetailView(
										isNew: false,
										goal: goal
									)
								} label: {
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
					.searchable(text: $searchText, placement: .toolbar, prompt: isiPhone() ? "Search goals" : "Search")
//					.refreshable {
//						Task {
//							await refresh()
//						}
//					}
					.animation(.easeInOut, value: filteredGoals.count)
					.transition(.blurReplace)
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
				#endif // os(iOS)

				ToolbarItem(placement: .topBarTrailing) {
					Button {
						showAddGoal = true
					} label: {
						Label("Add Goal", systemImage: "plus")
					}
					.buttonStyle(.glassProminent)
					.foregroundStyle(.black)
				}

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
			}
			.task {
				await refresh()
			}
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
