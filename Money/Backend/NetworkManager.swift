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

	private init() {
		token = Defaults[.userToken]
		email = Defaults[.userEmail]
		firstName = Defaults[.userFirstName]
	}

	func fetchTransactions() async throws -> [TransactionDTO] {
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

		return try decoder.decode([TransactionDTO].self, from: data)
	}

	func login(email: String, password: String) async throws {
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
			let message =
				(try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["error"] as? String
					?? "Login failed (\(httpResponse.statusCode))"

			throw NSError(domain: "", code: httpResponse.statusCode,
			              userInfo: [NSLocalizedDescriptionKey: message])
		}

		let decoded = try JSONDecoder().decode(UserLoginResponse.self, from: data)

		Task {
			// SO THAT THE SUCCESS ANIMATIONS PLAYS NICELY
			try await Task.sleep(nanoseconds: 1_000_000_000)
			token = decoded.token
		}
		self.email = decoded.user.email
		firstName = decoded.user.firstName
	}

	func signup(firstName: String, email: String, password: String) async throws {
		let url = URL(string: "https://money.adonis.pt/users/signup")!
		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")

		let body = [
			"firstName": firstName,
			"email": email,
			"password": password,
		]
		request.httpBody = try JSONEncoder().encode(body)

		let (data, response) = try await URLSession.shared.data(for: request)

		guard let httpResponse = response as? HTTPURLResponse else {
			throw URLError(.badServerResponse)
		}

		guard (200 ... 299).contains(httpResponse.statusCode) else {
			let message =
				(try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["error"] as? String
					?? "Signup failed (\(httpResponse.statusCode))"

			throw NSError(domain: "", code: httpResponse.statusCode,
			              userInfo: [NSLocalizedDescriptionKey: message])
		}

		let decoded = try JSONDecoder().decode(UserLoginResponse.self, from: data)

		Task {
			// SO THAT THE SUCCESS ANIMATIONS PLAYS NICELY
			try await Task.sleep(nanoseconds: 1_000_000_000)
			token = decoded.token
		}
		self.email = decoded.user.email
		self.firstName = decoded.user.firstName
	}

	func createTransaction(
		change: Double,
		title: String,
		description: String,
		importance: Importance
	) async throws -> [TransactionDTO] {
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
		change: Double? = nil,
		title: String? = nil,
		description: String? = nil,
		importance: Importance? = nil
	) async throws -> TransactionDTO {
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
		return try decoder.decode(TransactionDTO.self, from: data)
	}

	func deleteTransactions(ids: [UUID]) async throws -> [TransactionDTO] {
		guard let token = token else {
			throw NSError(
				domain: "",
				code: 401,
				userInfo: [NSLocalizedDescriptionKey: "Not authenticated"]
			)
		}

		let url = URL(string: "https://money.adonis.pt/transactions/deleteMultiple")!
		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

		let body: [String: Any] = [
			"ids": ids.map { $0.uuidString },
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
					default: message = "\(httpResponse.statusCode)"
				}
			}
			throw NSError(
				domain: "",
				code: httpResponse.statusCode,
				userInfo: [NSLocalizedDescriptionKey: message]
			)
		}

		return try await fetchTransactions()
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

	func deleteCurrentUser() async throws {
		guard let token else {
			throw NSError(domain: "", code: 401,
			              userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
		}

		let url = URL(string: "https://money.adonis.pt/users/me")!
		var request = URLRequest(url: url)
		request.httpMethod = "DELETE"
		request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

		let (_, response) = try await URLSession.shared.data(for: request)

		guard let httpResponse = response as? HTTPURLResponse,
		      (200 ... 299).contains(httpResponse.statusCode)
		else {
			throw NSError(domain: "", code: 0,
			              userInfo: [NSLocalizedDescriptionKey: "Failed to delete user"])
		}

		self.token = nil
		email = nil
		firstName = nil
	}
}
