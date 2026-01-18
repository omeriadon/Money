//
//  Models.swift
//  Money
//
//  Created by Adon Omeri on 18/1/2026.
//

import Foundation
import Defaults

struct CurrentUser: Codable, Defaults.Serializable {
	let firstName: String
	let email: String
	let token: String
}
