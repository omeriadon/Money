//
//  OpenTabIntent.swift
//  Money
//
//  Created by Adon Omeri on 1/3/2026.
//

import AppIntents
import Defaults

enum OpenTabIntentEnum: String, AppEnum {
	case home = "Home"
	case goals = "Goals"
	case analyse = "Analyse"
	case settings = "Settings"
	case search = "Search"

	static var typeDisplayRepresentation: TypeDisplayRepresentation = "Tab"
	static var caseDisplayRepresentations: [OpenTabIntentEnum: DisplayRepresentation] = [
		.home: DisplayRepresentation(title: "Home", image: .init(systemName: "house")),
		.goals: DisplayRepresentation(title: "Goals", image: .init(systemName: "target")),
		.analyse: DisplayRepresentation(title: "Analyse", image: .init(systemName: "chart.xyaxis.line")),
		.settings: DisplayRepresentation(title: "Settings", image: .init(systemName: "gearshape")),
		.search: DisplayRepresentation(title: "Search", image: .init(systemName: "mail.stack")),
	]
}

struct TabOptionsProvider: DynamicOptionsProvider {
	func results() async throws -> [OpenTabIntentEnum] {
		var tabs: [OpenTabIntentEnum] = [.home, .settings, .search]
		if Defaults[.showGoalsTab] { tabs.append(.goals) }
		if Defaults[.showAnalyseTab] { tabs.append(.analyse) }
		return tabs
	}
}

struct OpenTabIntent: AppIntent {
	static var title: LocalizedStringResource = "Open Tab"
	static var supportedModes: IntentModes = .foreground(.immediate)

	@Parameter(title: "Tab", optionsProvider: TabOptionsProvider())
	var tab: OpenTabIntentEnum

	@MainActor
	func perform() async throws -> some IntentResult {
		Defaults[.tab] = tab.rawValue
		return .result()
	}
}
