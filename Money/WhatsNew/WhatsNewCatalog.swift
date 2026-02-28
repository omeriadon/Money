import Foundation

struct WhatsNewItem: Identifiable, Hashable {
	let title: String
	let description: String
	let symbolName: String

	var id: String { "\(title)|\(symbolName)" }
}

enum WhatsNewReleaseCatalog {
	static let releases: [WhatsNewRelease: [WhatsNewItem]] = [
		WhatsNewRelease(version: "1.0", build: 1): [
			WhatsNewItem(
				title: "App Launch",
				description: "Welcome to the first beta release of Money.",
				symbolName: "sparkles"
			),
			WhatsNewItem(
				title: "Goals + Analytics",
				description: "Track goals and view your spending trends.",
				symbolName: "target"
			),
		],
	]

	static var sortedReleases: [WhatsNewRelease] {
		releases.keys.sorted()
	}

	static var currentRelease: WhatsNewRelease? {
		guard let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
		      let buildString = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String,
		      let build = Int(buildString)
		else {
			return nil
		}

		return WhatsNewRelease(version: version, build: build)
	}

	static func items(for release: WhatsNewRelease) -> [WhatsNewItem]? {
		releases[release]
	}

	static func previousRelease(before release: WhatsNewRelease) -> WhatsNewRelease? {
		sortedReleases.last(where: { $0 < release })
	}

	static func rollbackSeenState(from currentState: WhatsNewSeenState) -> WhatsNewSeenState {
		guard let currentRelease else { return .resetRequested }

		if let previous = previousRelease(before: currentRelease) {
			return .release(previous)
		}

		if case let .release(shownRelease) = currentState, shownRelease < currentRelease {
			return .release(shownRelease)
		}

		return .resetRequested
	}
}
