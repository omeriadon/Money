import SwiftUI

enum AppFontDesign: String, CaseIterable, Identifiable {
	case `default`
	case rounded
	case monospaced

	var id: String {
		rawValue
	}

	var title: String {
		switch self {
			case .default: "Default"
			case .rounded: "Rounded"
			case .monospaced: "Monospaced"
		}
	}

	var fontDesign: Font.Design {
		switch self {
			case .default: .default
			case .rounded: .rounded
			case .monospaced: .monospaced
		}
	}
}
