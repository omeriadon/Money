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

	func login(email: String, password: String) async throws {
		let url = URL(string: "https://money.adonis.pt/users/login")!
		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")

		let body = ["email": email, "password": password]
		request.httpBody = try JSONEncoder().encode(body)

		let (data, response) = try await URLSession.shared.data(for: request)

		guard let httpResponse = response as? HTTPURLResponse,
		      httpResponse.statusCode == 200
		else {
			throw URLError(.badServerResponse)
		}

		let decoded = try JSONDecoder().decode(UserLoginResponse.self, from: data)
		token = decoded.token.value
		self.email = decoded.user.email
		firstName = decoded.user.firstName
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

		// Decode the response
		let decoded = try JSONDecoder().decode(UserLoginResponse.self, from: data)

		// Return true immediately
		let success = true

		// Update NetworkManager after 1 second
		Task { @MainActor in
			try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
			self.token = decoded.token.value
			self.email = decoded.user.email
			self.firstName = decoded.user.firstName
		}

		return success
	}
}
