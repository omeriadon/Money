//
//  Models.swift
//  Money
//
//  Created by Adon Omeri on 18/1/2026.
//

import Charts
import Defaults
import SwiftUI

struct CurrentUser: Codable, Defaults.Serializable {
	let firstName: String
	let email: String
	let token: String
}

enum Importance: String, Codable, CaseIterable, Identifiable, Plottable {
	case essential, leisure, investment, reward, emergency, occasional

	case dayJob, passiveIncome, oneTime

	var id: String {
		rawValue
	}

	static let negative: [Importance] = [.essential, .leisure, .investment, .reward, .emergency, .occasional]

	static let positive: [Importance] = [.dayJob, .passiveIncome, .oneTime]

	var title: String {
		switch self {
			case .essential:
				"Essential"
			case .leisure:
				"Leisure"
			case .investment:
				"Investment"
			case .reward:
				"Reward"
			case .emergency:
				"Emergency"
			case .occasional:
				"Occasional"
			case .dayJob:
				"Day Job"
			case .passiveIncome:
				"Passive Income"
			case .oneTime:
				"One Time"
		}
	}

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
			case .emergency:
				"cross.case"
			case .occasional:
				"calendar"
			case .dayJob:
				"figure.walk"
			case .passiveIncome:
				"zzz"
			case .oneTime:
				"1.circle"
		}
	}

	var colour: Color {
		switch self {
			case .essential:
				.yellow
			case .leisure:
				.red
			case .investment:
				.blue
			case .reward:
				.brown
			case .emergency:
				.purple
			case .occasional:
				.orange
			case .dayJob:
				.teal
			case .passiveIncome:
				.mint
			case .oneTime:
				.blue
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
