//
//  Defaults.swift
//  Money
//
//  Created by Adon Omeri on 18/1/2026.
//

import Defaults
import Foundation

struct WhatsNewRelease: Codable, Hashable, Defaults.Serializable, Comparable {
	let version: String
	let build: Int

	static func < (lhs: WhatsNewRelease, rhs: WhatsNewRelease) -> Bool {
		let lhsParts = lhs.version.split(separator: ".").map { Int($0) ?? 0 }
		let rhsParts = rhs.version.split(separator: ".").map { Int($0) ?? 0 }
		let maxCount = max(lhsParts.count, rhsParts.count)

		for index in 0 ..< maxCount {
			let l = index < lhsParts.count ? lhsParts[index] : 0
			let r = index < rhsParts.count ? rhsParts[index] : 0
			if l != r { return l < r }
		}

		return lhs.build < rhs.build
	}
}

enum WhatsNewSeenState: Codable, Defaults.Serializable, Equatable {
	case unseen
	case release(WhatsNewRelease)
	case resetRequested
}

extension Defaults.Keys {
	static let userEmail = Key<String?>("userEmail", default: nil)
	static let userFirstName = Key<String?>("userFirstName", default: nil)
	static let hasSeenIntroSplash = Key<Bool>("hasSeenIntroSplash", default: false)
	static let whatsNewSeenState = Key<WhatsNewSeenState>("whatsNewSeenState", default: .unseen)

	private static let appGroupSuite = UserDefaults(suiteName: AppConfig.appGroupSuiteName)!

	static let transactions = Key<[Transaction]>("transactions", default: [], suite: appGroupSuite)
	static let goals = Key<[Goal]>("goals", default: [], suite: appGroupSuite)

	static let useNewGradient = Key<Bool>("useNewGradient", default: true)
	static let showAnalyseTab = Key<Bool>("showAnalyseTab", default: true)
	static let showGoalsTab = Key<Bool>("showGoalsTab", default: true)
	static let useMonospacedFont = Key<Bool>("useMonospacedFont", default: true)
	static let fontDesignStyle = Key<String>("fontDesignStyle", default: "monospaced")
}
