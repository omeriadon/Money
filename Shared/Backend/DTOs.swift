import Foundation

struct UserSignupDTO: Codable, Equatable {
	var firstName: String
	var email: String
	var password: String
}

struct UserLoginDTO: Codable, Equatable {
	var email: String
	var password: String
}

struct TransactionDTO: Codable, Identifiable {
	let id: UUID
	let change: Double
	let title: String
	let description: String
	let importance: Importance
	let userID: UUID
	let dateCreated: Date
	let dateUpdated: Date
}

struct GoalDTO: Codable, Identifiable {
	let id: UUID
	let name: String
	let description: String
	let goalAmount: Double
	let status: Goal.GoalStatus?
	let userID: UUID
	let dateCreated: Date
	let dateUpdated: Date
}

struct UserLoginResponse: Codable {
	let token: String
	let user: UserDTO
}

struct UserDTO: Codable {
	let id: UUID?
	let firstName: String
	let email: String
}
