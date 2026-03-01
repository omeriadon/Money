import AppIntents

enum TransactionImportanceIntentEnum: String, AppEnum {
	case essential
	case leisure
	case investment
	case reward
	case occasional
	case dayJob
	case passiveIncome
	case oneTime

	static var typeDisplayRepresentation: TypeDisplayRepresentation = "Category"

	static var caseDisplayRepresentations: [TransactionImportanceIntentEnum: DisplayRepresentation] = [
		.essential: DisplayRepresentation(title: "Groceries", image: .init(systemName: "cart")),
		.leisure: DisplayRepresentation(title: "Dining", image: .init(systemName: "fork.knife")),
		.investment: DisplayRepresentation(title: "Auto + Transport", image: .init(systemName: "car")),
		.reward: DisplayRepresentation(title: "Entertainment", image: .init(systemName: "tv")),
		.occasional: DisplayRepresentation(title: "Occasional", image: .init(systemName: "calendar")),
		.dayJob: DisplayRepresentation(title: "Job", image: .init(systemName: "briefcase")),
		.passiveIncome: DisplayRepresentation(title: "Passive", image: .init(systemName: "zzz")),
		.oneTime: DisplayRepresentation(title: "One Time", image: .init(systemName: "1.circle")),
	]

	var modelValue: Importance {
		switch self {
			case .essential:
				.essential
			case .leisure:
				.leisure
			case .investment:
				.investment
			case .reward:
				.reward
			case .occasional:
				.occasional
			case .dayJob:
				.dayJob
			case .passiveIncome:
				.passiveIncome
			case .oneTime:
				.oneTime
		}
	}
}

struct CreateTransactionIntent: AppIntent {
	static var title: LocalizedStringResource = "Create Transaction"
	static var supportedModes: IntentModes = .background

	@Parameter(title: "Amount")
	var amount: Double

	@Parameter(title: "Title")
	var title: String

	@Parameter(title: "Description")
	var description: String?

	@Parameter(title: "Category")
	var category: TransactionImportanceIntentEnum

	@MainActor
	func perform() async throws -> some IntentResult {
		try await TransactionRepository.shared.createTransaction(
			change: amount,
			title: title,
			description: description ?? "",
			importance: category.modelValue
		)
		return .result()
	}
}
