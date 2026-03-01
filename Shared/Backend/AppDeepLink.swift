import Foundation

enum AppDeepLink {
	static func home() -> URL {
		make(path: "home")
	}

	static func goal(_ id: UUID? = nil) -> URL {
		make(path: "goal", id: id)
	}

	static func analyse() -> URL {
		make(path: "analyse")
	}

	static func settings() -> URL {
		make(path: "settings")
	}

	static func transactions(_ id: UUID? = nil) -> URL {
		make(path: "transactions", id: id)
	}

	private static func make(path: String, id: UUID? = nil) -> URL {
		var urlString = "money://\(path)"
		if let id {
			urlString += "/\(id.uuidString)"
		}
		return URL(string: urlString)!
	}
}
