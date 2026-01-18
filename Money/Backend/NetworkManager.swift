import Combine
import Defaults
import Foundation

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
}
