import Foundation

struct UserLoginResponse: Codable {
    let user: UserDTO
    let token: TokenDTO
}

struct TokenDTO: Codable {
    let value: String
}

struct UserDTO: Codable {
    let id: UUID?
    let firstName: String
    let email: String
}

struct UserSignupDTO: Codable, Equatable {
    var firstName: String
    var email: String
    var password: String
}

struct UserLoginDTO: Codable, Equatable {
    var email: String
    var password: String
}

struct TransactionDTO: Codable {
    let id: UUID?
    let change: Int
    let title: String
    let description: String
    let importance: String
    let userID: UUID
    let dateCreated: Date?
    let dateUpdated: Date?
}
