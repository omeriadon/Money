import SwiftUI

enum AppFontDesign: String, CaseIterable, Identifiable {
	case normal
	case rounded
	case monospaced

	var id: String {
		rawValue
	}

	var title: String {
		switch self {
			case .normal: "Normal"
			case .rounded: "Rounded"
			case .monospaced: "Monospaced"
		}
	}

	var fontDesign: Font.Design {
		switch self {
			case .normal: .default
			case .rounded: .rounded
			case .monospaced: .monospaced
		}
	}
}
