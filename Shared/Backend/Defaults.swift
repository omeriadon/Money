//
//  Defaults.swift
//  Money
//
//  Created by Adon Omeri on 18/1/2026.
//

import Defaults
import Foundation

extension Defaults.Keys {
	static let userEmail = Key<String?>("userEmail", default: nil)
	static let userFirstName = Key<String?>("userFirstName", default: nil)
	static let hasSeenIntroSplash = Key<Bool>("hasSeenIntroSplash", default: false)

	private static let appGroupSuite = UserDefaults(suiteName: AppConfig.appGroupSuiteName)!

	static let transactions = Key<[Transaction]>("transactions", default: [], suite: appGroupSuite)
	static let goals = Key<[Goal]>("goals", default: [], suite: appGroupSuite)

	static let useNewGradient = Key<Bool>("useNewGradient", default: true)
	static let showAnalyseTab = Key<Bool>("showAnalyseTab", default: true)
	static let showGoalsTab = Key<Bool>("showGoalsTab", default: true)
	static let useMonospacedFont = Key<Bool>("useMonospacedFont", default: true)
	static let fontDesignStyle = Key<String>("fontDesignStyle", default: "monospaced")
}
