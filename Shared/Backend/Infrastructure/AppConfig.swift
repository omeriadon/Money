import Foundation

enum AppConfig {
	#if DEBUG
		static let appGroupSuiteName = "group.omeriadon.money"
	#else
		static let appGroupSuiteName = "group.omeriadon-hackclub-release.money"
	#endif

	static let apiBaseURL = URL(string: "https://money.adonis.pt")!
}
