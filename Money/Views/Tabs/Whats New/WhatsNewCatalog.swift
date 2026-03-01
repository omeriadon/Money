import Foundation

struct WhatsNewItem: Identifiable, Hashable {
	let title: String
	let description: String
	let symbolName: String

	var id: String {
		"\(title)|\(symbolName)"
	}
}

enum WhatsNewReleaseCatalog {
	static let releases: [WhatsNewRelease: [WhatsNewItem]] = [
		WhatsNewRelease(version: "1.0", build: 8): [
			WhatsNewItem(
				title: "What's New ",
				description: "Every new release has a what's new page.",
				symbolName: "sparkles"
			),
			WhatsNewItem(
				title: "Goals",
				description: "Create and track goals, set with widgets.",
				symbolName: "target"
			),
			WhatsNewItem(
				title: "Font style",
				description: "You can now set the font style for iPhone and Apple Watch.",
				symbolName: "fleuron"
			),
			WhatsNewItem(
				title: "Onboarding Page",
				description: "An onboarding page shows on first launch.",
				symbolName: "hand.wave"
			),
			WhatsNewItem(
				title: "Upgraded Infrastructure",
				description: "Including more secure account management, will require a re-sign in.",
				symbolName: "person.crop.circle"
			),
			WhatsNewItem(
				title: "Watch Background",
				description: "Watch app now has an animated background, matching iPhone.",
				symbolName: "photo"
			),
			WhatsNewItem(
				title: "Widget Refinments",
				description: "Adjusted widgets to work better in all contexts.",
				symbolName: "widget.small"
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
