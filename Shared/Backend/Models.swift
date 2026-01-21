//
//  Models.swift
//  Money
//
//  Created by Adon Omeri on 18/1/2026.
//

import Defaults
import Foundation

struct CurrentUser: Codable, Defaults.Serializable {
	let firstName: String
	let email: String
	let token: String
}

enum Importance: String, Codable, CaseIterable, Identifiable {
	case essential, leisure, investment, reward, emergent, occasional

	var id: String { rawValue }

	var symbol: String {
		switch self {
			case .essential:
				"carrot"
			case .leisure:
				"scooter"
			case .investment:
				"banknote"
			case .reward:
				"star"
			case .emergent:
				"cross.case"
			case .occasional:
				"calendar"
		}
	}
}

final class Transaction: Identifiable, Codable, Defaults.Serializable {
	var id: UUID
	var change: Double
	var title: String
	var desc: String
	var importance: Importance
	var dateCreated: Date
	var dateUpdated: Date

	init(
		id: UUID = UUID(),
		change: Double,
		title: String,
		desc: String,
		importance: Importance,
		dateCreated: Date = Date(),
		dateUpdated: Date = Date()
	) {
		self.id = id
		self.change = change
		self.title = title
		self.desc = desc
		self.importance = importance
		self.dateCreated = dateCreated
		self.dateUpdated = dateUpdated
	}

	convenience init(from dto: TransactionDTO) {
		self.init(
			id: dto.id,
			change: dto.change,
			title: dto.title,
			desc: dto.description,
			importance: dto.importance,
			dateCreated: dto.dateCreated
		)
	}

	func update(from dto: TransactionDTO) {
		change = dto.change
		title = dto.title
		desc = dto.description
		importance = dto.importance
		dateCreated = dto.dateCreated
	}
}
