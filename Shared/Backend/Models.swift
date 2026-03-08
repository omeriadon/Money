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
	// Expense (negative) categories
	case essential // renamed: Groceries
	case leisure // renamed: Dining
	case investment // renamed: Auto + Transport
	case reward // renamed: Entertainment
	case occasional

	// Income (positive) categories
	case dayJob // renamed: Job
	case passiveIncome // renamed: Passive
	case oneTime

	var id: String {
		rawValue
	}

	static let negative: [Importance] = [.essential, .leisure, .investment, .reward, .occasional]

	static let positive: [Importance] = [.dayJob, .passiveIncome, .oneTime]

	var title: String {
		switch self {
			case .essential:
				"Groceries"
			case .leisure:
				"Dining"
			case .investment:
				"Auto + Transport"
			case .reward:
				"Entertainment"
			case .occasional:
				"Occasional"
			case .dayJob:
				"Job"
			case .passiveIncome:
				"Passive"
			case .oneTime:
				"One Time"
		}
	}

	var symbol: String {
		switch self {
			case .essential:
				"cart"
			case .leisure:
				"fork.knife"
			case .investment:
				"car"
			case .reward:
				"tv"
			case .occasional:
				"calendar"
			case .dayJob:
				"briefcase"
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

final class Transaction: Equatable, Identifiable, Codable, Defaults.Serializable {
	static func == (lhs: Transaction, rhs: Transaction) -> Bool {
		lhs.id == rhs.id
	}

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

final class Goal: Equatable, Identifiable, Codable, Defaults.Serializable {
	enum GoalStatus: String, Codable, CaseIterable, Defaults.Serializable {
		case active
		case paused
		case completed
		case archived

		var title: String {
			switch self {
				case .active:
					"Active"
				case .paused:
					"Paused"
				case .completed:
					"Completed"
				case .archived:
					"Archived"
			}
		}

		var symbol: String {
			switch self {
				case .active:
					"play.circle"
				case .paused:
					"pause.circle"
				case .completed:
					"checkmark.circle.fill"
				case .archived:
					"archivebox"
			}
		}
	}

	private enum CodingKeys: String, CodingKey {
		case id
		case name
		case desc
		case goalAmount
		case dateCreated
		case dateUpdated
		case status
	}

	static func == (lhs: Goal, rhs: Goal) -> Bool {
		lhs.id == rhs.id
	}

	var id: UUID
	var name: String
	var desc: String
	var goalAmount: Double
	var status: GoalStatus
	var dateCreated: Date
	var dateUpdated: Date

	init(
		id: UUID = UUID(),
		name: String,
		desc: String,
		goalAmount: Double,
		status: GoalStatus = .active,
		dateCreated: Date = Date(),
		dateUpdated: Date = Date()
	) {
		self.id = id
		self.name = name
		self.desc = desc
		self.goalAmount = goalAmount
		self.status = status
		self.dateCreated = dateCreated
		self.dateUpdated = dateUpdated
	}

	convenience init(from dto: GoalDTO) {
		self.init(
			id: dto.id,
			name: dto.name,
			desc: dto.description,
			goalAmount: dto.goalAmount,
			status: dto.status ?? .active,
			dateCreated: dto.dateCreated,
			dateUpdated: dto.dateUpdated
		)
	}

	func update(from dto: GoalDTO) {
		name = dto.name
		desc = dto.description
		goalAmount = dto.goalAmount
		status = dto.status ?? .active
		dateCreated = dto.dateCreated
		dateUpdated = dto.dateUpdated
	}

	required init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		id = try container.decode(UUID.self, forKey: .id)
		name = try container.decode(String.self, forKey: .name)
		desc = try container.decode(String.self, forKey: .desc)
		goalAmount = try container.decode(Double.self, forKey: .goalAmount)
		status = try container.decodeIfPresent(GoalStatus.self, forKey: .status) ?? .active
		dateCreated = try container.decode(Date.self, forKey: .dateCreated)
		dateUpdated = try container.decode(Date.self, forKey: .dateUpdated)
	}

	func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(id, forKey: .id)
		try container.encode(name, forKey: .name)
		try container.encode(desc, forKey: .desc)
		try container.encode(goalAmount, forKey: .goalAmount)
		try container.encode(status, forKey: .status)
		try container.encode(dateCreated, forKey: .dateCreated)
		try container.encode(dateUpdated, forKey: .dateUpdated)
	}
}
