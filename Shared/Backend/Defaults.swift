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
	static let transactions = Key<[Transaction]>("transactions", default: [])
}
