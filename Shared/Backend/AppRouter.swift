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
		goalPath = []
		let target = id.map { TransactionRoute.detail($0) }
		let desired: [TransactionRoute] = target.map { [$0] } ?? []
		guard transactionPath != desired else { return }
		#if os(watchOS)
			// Tab switch needs time to settle before path mutation on watchOS
			Task {
				try? await Task.sleep(for: .milliseconds(150))
				transactionPath = desired
			}
		#else
			transactionPath = desired
		#endif
	}

	func navigateToGoal(_ id: UUID?) {
		transactionPath = []
		let target = id.map { GoalRoute.detail($0) }
		let desired: [GoalRoute] = target.map { [$0] } ?? []
		guard goalPath != desired else { return }
		#if os(watchOS)
			Task {
				try? await Task.sleep(for: .milliseconds(150))
				goalPath = desired
			}
		#else
			goalPath = desired
		#endif
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
