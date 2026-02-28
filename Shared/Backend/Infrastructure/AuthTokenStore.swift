import Foundation
import Security

enum AuthTokenStore {
	private static let account = "userToken"
	private static var service: String { "money.auth.\(AppConfig.appGroupSuiteName)" }

	static func readToken() -> String? {
		let query: [String: Any] = [
			kSecClass as String: kSecClassGenericPassword,
			kSecAttrService as String: service,
			kSecAttrAccount as String: account,
			kSecReturnData as String: true,
			kSecMatchLimit as String: kSecMatchLimitOne,
		]

		var result: CFTypeRef?
		let status = SecItemCopyMatching(query as CFDictionary, &result)
		guard status == errSecSuccess,
		      let data = result as? Data,
		      let token = String(data: data, encoding: .utf8)
		else {
			return nil
		}

		return token
	}

	static func saveToken(_ token: String?) {
		guard let token else {
			clearToken()
			return
		}

		guard let data = token.data(using: .utf8) else { return }

		let query: [String: Any] = [
			kSecClass as String: kSecClassGenericPassword,
			kSecAttrService as String: service,
			kSecAttrAccount as String: account,
		]

		let attributes: [String: Any] = [
			kSecValueData as String: data,
		]

		if SecItemCopyMatching(query as CFDictionary, nil) == errSecSuccess {
			SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
		} else {
			var create = query
			create[kSecValueData as String] = data
			SecItemAdd(create as CFDictionary, nil)
		}
	}

	static func clearToken() {
		let query: [String: Any] = [
			kSecClass as String: kSecClassGenericPassword,
			kSecAttrService as String: service,
			kSecAttrAccount as String: account,
		]
		SecItemDelete(query as CFDictionary)
	}
}
