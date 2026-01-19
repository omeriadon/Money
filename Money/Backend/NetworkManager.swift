import Combine
import Defaults
import SwiftUI

@MainActor
final class NetworkManager: ObservableObject {
	static let shared = NetworkManager()

	@Published var token: String? {
		didSet { Defaults[.userToken] = token }
	}

	@Published var email: String? {
		didSet { Defaults[.userEmail] = email }
	}

	@Published var firstName: String? {
		didSet { Defaults[.userFirstName] = firstName }
	}

	@Published var transactions: [TransactionDTO] = []

	var totalBalance: Int {
		transactions.reduce(0) { $0 + $1.change }
	}

	private init() {
		token = Defaults[.userToken]
		email = Defaults[.userEmail]
		firstName = Defaults[.userFirstName]
	}

	func fetchTransactions() async throws -> [TransactionResponse] {
		guard let token else {
			throw NSError(
				domain: "",
				code: 401,
				userInfo: [NSLocalizedDescriptionKey: "Not authenticated"]
			)
		}

		let url = URL(string: "https://money.adonis.pt/transactions")!
		var request = URLRequest(url: url)
		request.httpMethod = "GET"
		request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
		request.setValue("application/json", forHTTPHeaderField: "Accept")

		let (data, response) = try await URLSession.shared.data(for: request)

		guard let httpResponse = response as? HTTPURLResponse else {
			throw URLError(.badServerResponse)
		}

		guard (200 ... 299).contains(httpResponse.statusCode) else {
			let message: String
			if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
			   let error = json["error"] as? String
			{
				message = error
			} else {
				message = "\(httpResponse.statusCode)"
			}
			throw NSError(
				domain: "",
				code: httpResponse.statusCode,
				userInfo: [NSLocalizedDescriptionKey: message]
			)
		}

		let decoder = JSONDecoder()
		decoder.dateDecodingStrategy = .iso8601

		return try decoder.decode([TransactionResponse].self, from: data)
	}

	@MainActor
	func login(email: String, password: String) async throws -> Bool {
		let url = URL(string: "https://money.adonis.pt/users/login")!
		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")

		let body = ["email": email, "password": password]
		request.httpBody = try JSONEncoder().encode(body)

		let (data, response) = try await URLSession.shared.data(for: request)

		guard let httpResponse = response as? HTTPURLResponse else {
			throw URLError(.badServerResponse)
		}

		guard (200 ... 299).contains(httpResponse.statusCode) else {
			let message: String
			if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
			   let error = json["error"] as? String
			{
				message = error
			} else {
				switch httpResponse.statusCode {
					case 400: message = "Bad request"
					case 401: message = "Invalid credentials"
					case 404: message = "User not found"
					default: message = "\(httpResponse.statusCode)"
				}
			}
			throw NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
		}

		let decoded = try JSONDecoder().decode(UserLoginResponse.self, from: data)

		Task {
			try await Task.sleep(nanoseconds: 2_000_000_000)
			self.token = decoded.token
		}
		self.email = decoded.user.email
		firstName = decoded.user.firstName

		return true
	}

	func signup(firstName: String, email: String, password: String) async throws -> Bool {
		let url = URL(string: "https://money.adonis.pt/users/signup")!
		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")

		let body = ["firstName": firstName, "email": email, "password": password]
		request.httpBody = try JSONEncoder().encode(body)

		let (data, response) = try await URLSession.shared.data(for: request)

		guard let httpResponse = response as? HTTPURLResponse else {
			throw URLError(.badServerResponse)
		}

		guard (200 ... 299).contains(httpResponse.statusCode) else {
			let message: String
			if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
			   let error = json["error"] as? String
			{
				message = error
			} else {
				switch httpResponse.statusCode {
					case 400:
						message = "Invalid request. Check your input."
					case 409:
						message = "Account for this email already exists."
					case 500:
						message = "Server error. Try again later."
					default:
						message = "Unexpected error: \(httpResponse.statusCode)"
				}
			}
			throw NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
		}

		let decoded = try JSONDecoder().decode(UserLoginResponse.self, from: data)

		let success = true

		Task { @MainActor in
			try? await Task.sleep(nanoseconds: 1_000_000_000)
			self.token = decoded.token
			self.email = decoded.user.email
			self.firstName = decoded.user.firstName
		}

		return success
	}

	func createTransaction(
		change: Double,
		title: String,
		description: String,
		importance: Importance
	) async throws -> [TransactionResponse] {
		guard let token = token else {
			throw NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
		}

		let url = URL(string: "https://money.adonis.pt/transactions")!
		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

		let body: [String: Any] = [
			"change": change,
			"title": title,
			"description": description,
			"importance": importance.rawValue,
		]
		request.httpBody = try JSONSerialization.data(withJSONObject: body)

		let (data, response) = try await URLSession.shared.data(for: request)

		guard let httpResponse = response as? HTTPURLResponse else {
			throw URLError(.badServerResponse)
		}

		guard (200 ... 299).contains(httpResponse.statusCode) else {
			let message: String
			if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
			   let error = json["error"] as? String
			{
				message = error
			} else {
				switch httpResponse.statusCode {
					case 400: message = "Bad request"
					case 401: message = "Unauthorized"
					case 404: message = "Not found"
					case 409: message = "Conflict"
					default: message = "\(httpResponse.statusCode)"
				}
			}
			throw NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
		}

		return try await fetchTransactions()
	}

	func updateTransaction(
		id: UUID,
		change: Int? = nil,
		title: String? = nil,
		description: String? = nil,
		importance: Importance? = nil
	) async throws -> TransactionResponse {
		let url = URL(string: "https://money.adonis.pt/transactions/\(id)")!
		var request = URLRequest(url: url)
		request.httpMethod = "PATCH"
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")

		if let token = token {
			request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
		}

		var body: [String: Any] = [:]
		if let change = change { body["change"] = change }
		if let title = title { body["title"] = title }
		if let description = description { body["description"] = description }
		if let importance = importance { body["importance"] = importance.rawValue }

		request.httpBody = try JSONSerialization.data(withJSONObject: body)

		let (data, response) = try await URLSession.shared.data(for: request)

		guard let httpResponse = response as? HTTPURLResponse else {
			throw URLError(.badServerResponse)
		}

		guard (200 ... 299).contains(httpResponse.statusCode) else {
			let message: String
			if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
			   let error = json["error"] as? String
			{
				message = error
			} else {
				message = "\(httpResponse.statusCode)"
			}
			throw NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
		}

		print(data.base64EncodedString())
		let decoder = JSONDecoder()
		decoder.dateDecodingStrategy = .iso8601
		return try decoder.decode(TransactionResponse.self, from: data)
	}

	func logout() async throws {
		guard let token = token else { return }

		let url = URL(string: "https://money.adonis.pt/users/logout")!
		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

		let (_, response) = try await URLSession.shared.data(for: request)

		guard let httpResponse = response as? HTTPURLResponse,
		      (200 ... 299).contains(httpResponse.statusCode)
		else {
			throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to log out"])
		}

		self.token = nil
		email = nil
		firstName = nil
	}
}
