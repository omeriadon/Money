//
//  Defaults.swift
//  Money
//
//  Created by Adon Omeri on 18/1/2026.
//

import Defaults
import Foundation

extension Defaults.Keys {
	static let userToken = Key<String?>("userToken", default: nil)
	static let userEmail = Key<String?>("userEmail", default: nil)
	static let userFirstName = Key<String?>("userFirstName", default: nil)
	#if DEBUG
		static let transactions = Key<[Transaction]>("transactions", default: [], suite: .init(suiteName: "group.omeriadon.money")!)
	#else
		static let transactions = Key<[Transaction]>("transactions", default: [], suite: .init(suiteName: "group.omeriadon-hackclub-release.money")!)
	#endif

	static let useNewGradient = Key<Bool>("useNewGradient", default: true)
	static let showAnalyseTab = Key<Bool>("showAnalyseTab", default: true)
}
