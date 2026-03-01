import Defaults
import Foundation
import Observation

enum TransactionRoute: Hashable {
	case detail(UUID)
}

enum GoalRoute: Hashable {
	case detail(UUID)
}

@MainActor
@Observable
final class AppRouter {
	var transactionPath: [TransactionRoute] = []
	var goalPath: [GoalRoute] = []

	func handle(url: URL) {
		guard let route = AppRoute(url: url) else { return }

		switch route {
			case .home:
				Defaults[.tab] = "Home"

			case let .goals(id):
				Defaults[.tab] = "Goals"
				navigateToGoal(id)

			case .analyse:
				#if os(watchOS)
					Defaults[.tab] = "Search"
				#else
					Defaults[.tab] = "Analyse"
				#endif

			case .settings:
				#if os(watchOS)
					Defaults[.tab] = "Home"
				#else
					Defaults[.tab] = "Settings"
				#endif

			case let .transactions(id):
				Defaults[.tab] = "Search"
				navigateToTransaction(id)
		}
	}

	func navigateToTransaction(_ id: UUID?) {
		let desired: [TransactionRoute] = id.map { [.detail($0)] } ?? []
		guard transactionPath != desired else { return }

		let crossType = !goalPath.isEmpty
		goalPath = []

		Task {
			// Cross-type: tab switch needs to settle first
			// Same-type with existing detail: pop animation needs to finish before pushing
			if crossType {
				#if os(watchOS)
					try? await Task.sleep(for: .milliseconds(150))
				#endif
			} else if !transactionPath.isEmpty {
				transactionPath = []
				try? await Task.sleep(for: .milliseconds(200))
			}
			transactionPath = desired
		}
	}

	func navigateToGoal(_ id: UUID?) {
		let desired: [GoalRoute] = id.map { [.detail($0)] } ?? []
		guard goalPath != desired else { return }

		let crossType = !transactionPath.isEmpty
		transactionPath = []

		Task {
			if crossType {
				#if os(watchOS)
					try? await Task.sleep(for: .milliseconds(150))
				#endif
			} else if !goalPath.isEmpty {
				goalPath = []
				try? await Task.sleep(for: .milliseconds(200))
			}
			goalPath = desired
		}
	}
}

// MARK: - URL Parsing

private enum AppRoute {
	case home
	case goals(UUID?)
	case analyse
	case settings
	case transactions(UUID?)

	init?(url: URL) {
		guard let scheme = url.scheme?.lowercased(), scheme == "money" else { return nil }

		let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
		let queryItems = components?.queryItems ?? []

		var segments: [String] = []
		if let host = url.host?.lowercased(), !host.isEmpty {
			segments.append(host)
		}
		segments += url.path.split(separator: "/").map { $0.lowercased() }

		guard var first = segments.first else { return nil }
		if first.hasPrefix(".") { first.removeFirst() }

		let routeID = Self.extractUUID(from: segments, queryItems: queryItems)

		switch first {
			case "home": self = .home
			case "goal", "goals": self = .goals(routeID)
			case "analyse", "analyze": self = .analyse
			case "settings": self = .settings
			case "transactions", "transaction", "search": self = .transactions(routeID)
			default: return nil
		}
	}

	private static func extractUUID(from segments: [String], queryItems: [URLQueryItem]) -> UUID? {
		if segments.count > 1, let uuid = UUID(uuidString: segments[1]) { return uuid }
		if let value = queryItems.first(where: { $0.name.lowercased() == "id" })?.value,
		   let uuid = UUID(uuidString: value) { return uuid }
		return nil
	}
}
