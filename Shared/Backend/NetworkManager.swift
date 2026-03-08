import Combine
import Defaults
import Foundation
import WidgetKit

private struct APIErrorPayload: Decodable {
	let error: String?
}

enum APIError: LocalizedError {
	case unauthenticated
	case invalidResponse
	case invalidRequestBody
	case server(statusCode: Int, message: String)

	var errorDescription: String? {
		switch self {
			case .unauthenticated:
				"Not authenticated"
			case .invalidResponse:
				"Invalid server response"
			case .invalidRequestBody:
				"Invalid request body"
			case let .server(_, message):
				message
		}
	}
}

@MainActor
final class NetworkManager: ObservableObject {
	static let shared = NetworkManager()

	private let encoder = JSONEncoder()
	private let decoder: JSONDecoder = {
		let decoder = JSONDecoder()
		decoder.dateDecodingStrategy = .iso8601
		return decoder
	}()

	@Published var token: String? {
		didSet {
			AuthTokenStore.saveToken(token)
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
		token = AuthTokenStore.readToken()
		email = Defaults[.userEmail]
		firstName = Defaults[.userFirstName]
	}

	func fetchTransactions() async throws -> [TransactionDTO] {
		let request = try makeRequest(path: "/transactions", method: "GET", requiresAuth: true)
		let data = try await perform(request)
		WidgetCenter.shared.reloadAllTimelines()
		return try decode([TransactionDTO].self, from: data)
	}

	func fetchGoals() async throws -> [GoalDTO] {
		let request = try makeRequest(path: "/goals", method: "GET", requiresAuth: true)
		let data = try await perform(request)
		return try decode([GoalDTO].self, from: data)
	}

	#if os(iOS)
		func login(email: String, password: String) async throws {
			let body = try encoder.encode(UserLoginDTO(email: email, password: password))
			let request = try makeRequest(
				path: "/users/login",
				method: "POST",
				requiresAuth: false,
				body: body
			)

			let data = try await perform(request)
			let decoded = try decode(UserLoginResponse.self, from: data)
			setAuthenticatedUser(from: decoded)
		}
	#endif // os(iOS)

	#if os(iOS)
		func signup(firstName: String, email: String, password: String) async throws {
			let body = try encoder.encode(UserSignupDTO(firstName: firstName, email: email, password: password))
			let request = try makeRequest(
				path: "/users/signup",
				method: "POST",
				requiresAuth: false,
				body: body
			)

			let data = try await perform(request)
			let decoded = try decode(UserLoginResponse.self, from: data)
			setAuthenticatedUser(from: decoded)
		}
	#endif // os(iOS)

	func createTransaction(
		change: Double,
		title: String,
		description: String,
		importance: Importance
	) async throws -> [TransactionDTO] {
		let body: [String: Any] = [
			"change": change,
			"title": title,
			"description": description,
			"importance": importance.rawValue,
		]

		let request = try makeRequest(
			path: "/transactions",
			method: "POST",
			requiresAuth: true,
			body: encode(body)
		)

		_ = try await perform(request)
		return try await fetchTransactions()
	}

	func updateTransaction(
		id: UUID,
		change: Double? = nil,
		title: String? = nil,
		description: String? = nil,
		importance: Importance? = nil
	) async throws -> TransactionDTO {
		var body: [String: Any] = [:]
		if let change { body["change"] = change }
		if let title { body["title"] = title }
		if let description { body["description"] = description }
		if let importance { body["importance"] = importance.rawValue }
		guard !body.isEmpty else { throw APIError.invalidRequestBody }

		let request = try makeRequest(
			path: "/transactions/\(id.uuidString)",
			method: "PATCH",
			requiresAuth: true,
			body: encode(body)
		)

		let data = try await perform(request)
		WidgetCenter.shared.reloadAllTimelines()
		return try decode(TransactionDTO.self, from: data)
	}

	func createGoal(
		name: String,
		description: String,
		goalAmount: Double,
		status: Goal.GoalStatus = .active,
		isArchived: Bool = false
	) async throws -> [GoalDTO] {
		let body: [String: Any] = [
			"name": name,
			"description": description,
			"goalAmount": abs(goalAmount),
			"status": status.rawValue,
			"isArchived": isArchived,
		]

		let request = try makeRequest(
			path: "/goals",
			method: "POST",
			requiresAuth: true,
			body: encode(body)
		)

		_ = try await perform(request)
		return try await fetchGoals()
	}

	func updateGoal(
		id: UUID,
		name: String? = nil,
		description: String? = nil,
		goalAmount: Double? = nil,
		status: Goal.GoalStatus? = nil,
		isArchived: Bool? = nil
	) async throws -> GoalDTO {
		var body: [String: Any] = [:]
		if let name { body["name"] = name }
		if let description { body["description"] = description }
		if let goalAmount { body["goalAmount"] = abs(goalAmount) }
		if let status { body["status"] = status.rawValue }
		if let isArchived { body["isArchived"] = isArchived }
		guard !body.isEmpty else { throw APIError.invalidRequestBody }

		let request = try makeRequest(
			path: "/goals/\(id.uuidString)",
			method: "PATCH",
			requiresAuth: true,
			body: encode(body)
		)

		let data = try await perform(request)
		return try decode(GoalDTO.self, from: data)
	}

	func deleteTransactions(ids: [UUID]) async throws -> [TransactionDTO] {
		let body: [String: Any] = ["ids": ids.map(\.uuidString)]
		let request = try makeRequest(
			path: "/transactions/deleteMultiple",
			method: "POST",
			requiresAuth: true,
			body: encode(body)
		)

		_ = try await perform(request)
		WidgetCenter.shared.reloadAllTimelines()
		return try await fetchTransactions()
	}

	func deleteGoals(ids: [UUID]) async throws -> [GoalDTO] {
		let body: [String: Any] = ["ids": ids.map(\.uuidString)]
		let request = try makeRequest(
			path: "/goals/deleteMultiple",
			method: "POST",
			requiresAuth: true,
			body: encode(body)
		)

		_ = try await perform(request)
		return try await fetchGoals()
	}

	#if os(iOS)
		func logout() async throws {
			guard token != nil else { return }
			let request = try makeRequest(path: "/users/logout", method: "POST", requiresAuth: true)
			_ = try await perform(request)
			clearAuthenticatedUser()
		}
	#endif // os(iOS)

	#if os(iOS)
		func deleteCurrentUser() async throws {
			let request = try makeRequest(path: "/users/me", method: "DELETE", requiresAuth: true)
			_ = try await perform(request)
			clearAuthenticatedUser()
		}
	#endif // os(iOS)

	#if os(iOS)
		func updateCurrentUser(firstName: String?, email: String?, password: String?) async throws -> UserDTO {
			var body: [String: Any] = [:]
			if let firstName { body["firstName"] = firstName }
			if let email { body["email"] = email }
			if let password { body["password"] = password }
			guard !body.isEmpty else { throw APIError.invalidRequestBody }

			let request = try makeRequest(
				path: "/users/me",
				method: "PATCH",
				requiresAuth: true,
				body: encode(body)
			)

			let data = try await perform(request)
			return try decode(UserDTO.self, from: data)
		}
	#endif // os(iOS)

	func refreshCurrentUser() async {
		guard token != nil else { return }

		do {
			let request = try makeRequest(path: "/users/me", method: "GET", requiresAuth: true)
			let data = try await perform(request)
			let user = try decode(UserDTO.self, from: data)
			email = user.email
			firstName = user.firstName
		} catch {
			return
		}
	}

	private func makeRequest(
		path: String,
		method: String,
		requiresAuth: Bool,
		body: Data? = nil
	) throws -> URLRequest {
		let base = AppConfig.apiBaseURL.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
		guard let url = URL(string: "\(base)\(path)") else {
			throw APIError.invalidResponse
		}

		var request = URLRequest(url: url)
		request.httpMethod = method
		request.setValue("application/json", forHTTPHeaderField: "Accept")
		if let body {
			request.httpBody = body
			request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		}

		if requiresAuth {
			guard let token else { throw APIError.unauthenticated }
			request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
		}

		return request
	}

	private func perform(_ request: URLRequest) async throws -> Data {
		let (data, response) = try await URLSession.shared.data(for: request)
		guard let httpResponse = response as? HTTPURLResponse else {
			throw APIError.invalidResponse
		}

		guard (200 ... 299).contains(httpResponse.statusCode) else {
			let fallbackMessage = "Request failed (\(httpResponse.statusCode))"
			let message = parseErrorMessage(from: data) ?? fallbackMessage
			throw APIError.server(statusCode: httpResponse.statusCode, message: message)
		}

		return data
	}

	private func parseErrorMessage(from data: Data) -> String? {
		if let decoded = try? decoder.decode(APIErrorPayload.self, from: data),
		   let message = decoded.error,
		   !message.isEmpty
		{
			return message
		}

		if let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
		   let message = object["error"] as? String,
		   !message.isEmpty
		{
			return message
		}

		return nil
	}

	private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
		try decoder.decode(type, from: data)
	}

	private func encode(_ body: [String: Any]) throws -> Data {
		try JSONSerialization.data(withJSONObject: body)
	}

	private func setAuthenticatedUser(from response: UserLoginResponse) {
		token = response.token
		email = response.user.email
		firstName = response.user.firstName
	}

	private func clearAuthenticatedUser() {
		token = nil
		email = nil
		firstName = nil
	}
}
