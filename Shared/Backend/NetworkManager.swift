import Combine
import Defaults
import SwiftUI
import WidgetKit

@MainActor
final class NetworkManager: ObservableObject {
	static let shared = NetworkManager()

	@Published var token: String? {
		didSet {
			Defaults[.userToken] = token
			#if os(iOS)
				if let token {
					iPhoneWatchSessionManager.shared.sendAuthToken(token)
				} else {
					iPhoneWatchSessionManager.shared.sendLogout()
				}
			#endif // os(iOS)
		}
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
			let message: String = if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
			                         let error = json["error"] as? String
			{
				error
			} else {
				"\(httpResponse.statusCode)"
			}
			throw NSError(
				domain: "",
				code: httpResponse.statusCode,
				userInfo: [NSLocalizedDescriptionKey: message]
			)
		}

		let decoder = JSONDecoder()
		decoder.dateDecodingStrategy = .iso8601

		WidgetCenter.shared.reloadAllTimelines()

		return try decoder.decode([TransactionDTO].self, from: data)
	}

	func fetchGoals() async throws -> [GoalDTO] {
		guard let token else {
			throw NSError(
				domain: "",
				code: 401,
				userInfo: [NSLocalizedDescriptionKey: "Not authenticated"]
			)
		}

		let url = URL(string: "https://money.adonis.pt/goals")!
		var request = URLRequest(url: url)
		request.httpMethod = "GET"
		request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
		request.setValue("application/json", forHTTPHeaderField: "Accept")

		let (data, response) = try await URLSession.shared.data(for: request)

		guard let httpResponse = response as? HTTPURLResponse else {
			throw URLError(.badServerResponse)
		}

		guard (200 ... 299).contains(httpResponse.statusCode) else {
			let message: String = if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
			                         let error = json["error"] as? String
			{
				error
			} else {
				"\(httpResponse.statusCode)"
			}
			throw NSError(
				domain: "",
				code: httpResponse.statusCode,
				userInfo: [NSLocalizedDescriptionKey: message]
			)
		}

		let decoder = JSONDecoder()
		decoder.dateDecodingStrategy = .iso8601

		return try decoder.decode([GoalDTO].self, from: data)
	}

	#if os(iOS)
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

			token = decoded.token

			self.email = decoded.user.email
			firstName = decoded.user.firstName
		}
	#endif // os(iOS)

	#if os(iOS)

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

			token = decoded.token

			self.email = decoded.user.email
			self.firstName = decoded.user.firstName
		}
	#endif // os(iOS)

	func createTransaction(
		change: Double,
		title: String,
		description: String,
		importance: Importance
	) async throws -> [TransactionDTO] {
		guard let token else {
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
			let message: String = if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
			                         let error = json["error"] as? String
			{
				error
			} else {
				switch httpResponse.statusCode {
					case 400: "Bad request"
					case 401: "Unauthorized"
					case 404: "Not found"
					case 409: "Conflict"
					default: "\(httpResponse.statusCode)"
				}
			}
			throw NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
		}

		WidgetCenter.shared.reloadAllTimelines()

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

		if let token {
			request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
		}

		var body: [String: Any] = [:]
		if let change { body["change"] = change }
		if let title { body["title"] = title }
		if let description { body["description"] = description }
		if let importance { body["importance"] = importance.rawValue }

		request.httpBody = try JSONSerialization.data(withJSONObject: body)

		let (data, response) = try await URLSession.shared.data(for: request)

		guard let httpResponse = response as? HTTPURLResponse else {
			throw URLError(.badServerResponse)
		}

		guard (200 ... 299).contains(httpResponse.statusCode) else {
			let message: String = if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
			                         let error = json["error"] as? String
			{
				error
			} else {
				"\(httpResponse.statusCode)"
			}
			throw NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
		}

		let decoder = JSONDecoder()
		decoder.dateDecodingStrategy = .iso8601

		WidgetCenter.shared.reloadAllTimelines()

		return try decoder.decode(TransactionDTO.self, from: data)
	}

	func createGoal(
		name: String,
		description: String,
		goalAmount: Double
	) async throws -> [GoalDTO] {
		guard let token else {
			throw NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
		}

		let url = URL(string: "https://money.adonis.pt/goals")!
		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

		let body: [String: Any] = [
			"name": name,
			"description": description,
			"goalAmount": abs(goalAmount),
		]
		request.httpBody = try JSONSerialization.data(withJSONObject: body)

		let (data, response) = try await URLSession.shared.data(for: request)

		guard let httpResponse = response as? HTTPURLResponse else {
			throw URLError(.badServerResponse)
		}

		guard (200 ... 299).contains(httpResponse.statusCode) else {
			let message: String = if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
			                         let error = json["error"] as? String
			{
				error
			} else {
				switch httpResponse.statusCode {
					case 400: "Bad request"
					case 401: "Unauthorized"
					case 404: "Not found"
					case 409: "Conflict"
					default: "\(httpResponse.statusCode)"
				}
			}
			throw NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
		}

		return try await fetchGoals()
	}

	func updateGoal(
		id: UUID,
		name: String? = nil,
		description: String? = nil,
		goalAmount: Double? = nil
	) async throws -> GoalDTO {
		let url = URL(string: "https://money.adonis.pt/goals/\(id)")!
		var request = URLRequest(url: url)
		request.httpMethod = "PATCH"
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")

		if let token {
			request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
		}

		var body: [String: Any] = [:]
		if let name { body["name"] = name }
		if let description { body["description"] = description }
		if let goalAmount { body["goalAmount"] = abs(goalAmount) }

		request.httpBody = try JSONSerialization.data(withJSONObject: body)

		let (data, response) = try await URLSession.shared.data(for: request)

		guard let httpResponse = response as? HTTPURLResponse else {
			throw URLError(.badServerResponse)
		}

		guard (200 ... 299).contains(httpResponse.statusCode) else {
			let message: String = if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
			                         let error = json["error"] as? String
			{
				error
			} else {
				"\(httpResponse.statusCode)"
			}
			throw NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
		}

		let decoder = JSONDecoder()
		decoder.dateDecodingStrategy = .iso8601

		return try decoder.decode(GoalDTO.self, from: data)
	}

	func deleteTransactions(ids: [UUID]) async throws -> [TransactionDTO] {
		guard let token else {
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
			"ids": ids.map(\.uuidString),
		]
		request.httpBody = try JSONSerialization.data(withJSONObject: body)

		let (data, response) = try await URLSession.shared.data(for: request)

		guard let httpResponse = response as? HTTPURLResponse else {
			throw URLError(.badServerResponse)
		}

		guard (200 ... 299).contains(httpResponse.statusCode) else {
			let message: String = if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
			                         let error = json["error"] as? String
			{
				error
			} else {
				switch httpResponse.statusCode {
					case 400: "Bad request"
					case 401: "Unauthorized"
					default: "\(httpResponse.statusCode)"
				}
			}
			throw NSError(
				domain: "",
				code: httpResponse.statusCode,
				userInfo: [NSLocalizedDescriptionKey: message]
			)
		}

		WidgetCenter.shared.reloadAllTimelines()

		return try await fetchTransactions()
	}

	func deleteGoals(ids: [UUID]) async throws -> [GoalDTO] {
		guard let token else {
			throw NSError(
				domain: "",
				code: 401,
				userInfo: [NSLocalizedDescriptionKey: "Not authenticated"]
			)
		}

		let url = URL(string: "https://money.adonis.pt/goals/deleteMultiple")!
		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

		let body: [String: Any] = [
			"ids": ids.map(\.uuidString),
		]
		request.httpBody = try JSONSerialization.data(withJSONObject: body)

		let (data, response) = try await URLSession.shared.data(for: request)

		guard let httpResponse = response as? HTTPURLResponse else {
			throw URLError(.badServerResponse)
		}

		guard (200 ... 299).contains(httpResponse.statusCode) else {
			let message: String = if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
			                         let error = json["error"] as? String
			{
				error
			} else {
				switch httpResponse.statusCode {
					case 400: "Bad request"
					case 401: "Unauthorized"
					default: "\(httpResponse.statusCode)"
				}
			}
			throw NSError(
				domain: "",
				code: httpResponse.statusCode,
				userInfo: [NSLocalizedDescriptionKey: message]
			)
		}

		return try await fetchGoals()
	}

	#if os(iOS)

		func logout() async throws {
			guard let token else { return }

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
	#endif // os(iOS)

	#if os(iOS)

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
	#endif // os(iOS)

	#if os(iOS)
		func updateCurrentUser(firstName: String?, email: String?, password: String?) async throws -> UserDTO {
			guard let token else {
				throw NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
			}

			let url = URL(string: "https://money.adonis.pt/users/me")!
			var request = URLRequest(url: url)
			request.httpMethod = "PATCH"
			request.setValue("application/json", forHTTPHeaderField: "Content-Type")
			request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

			var body: [String: Any] = [:]
			if let firstName { body["firstName"] = firstName }
			if let email { body["email"] = email }
			if let password { body["password"] = password }

			request.httpBody = try JSONSerialization.data(withJSONObject: body)

			let (data, response) = try await URLSession.shared.data(for: request)

			guard let httpResponse = response as? HTTPURLResponse else {
				throw URLError(.badServerResponse)
			}

			guard (200 ... 299).contains(httpResponse.statusCode) else {
				let message: String = if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
				                         let error = json["error"] as? String
				{
					error
				} else {
					"\(httpResponse.statusCode)"
				}
				throw NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
			}

			let decoder = JSONDecoder()
			return try decoder.decode(UserDTO.self, from: data)
		}
	#endif // os(iOS)

	func refreshCurrentUser() async {
		guard let token else { return }

		let url = URL(string: "https://money.adonis.pt/users/me")!
		var request = URLRequest(url: url)
		request.httpMethod = "GET"
		request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
		request.setValue("application/json", forHTTPHeaderField: "Accept")

		do {
			let (data, response) = try await URLSession.shared.data(for: request)
			guard let httpResponse = response as? HTTPURLResponse,
			      (200 ... 299).contains(httpResponse.statusCode)
			else { return }

			let decoder = JSONDecoder()
			let user = try decoder.decode(UserDTO.self, from: data)
			email = user.email
			firstName = user.firstName
		} catch {
			print("Failed to refresh user:", error.localizedDescription)
		}
	}
}
