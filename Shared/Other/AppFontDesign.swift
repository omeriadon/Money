import Defaults
import SwiftUI
import UIKit

enum AppFontDesign: String, CaseIterable, Identifiable, Defaults.Serializable {
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

	func uiFont(forTextStyle textStyle: UIFont.TextStyle = .title2) -> UIFont {
		let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: textStyle)
		switch self {
			case .default:
				return UIFont(descriptor: descriptor, size: descriptor.pointSize)
			case .rounded:
				if let rounded = descriptor.withDesign(.rounded) {
					return UIFont(descriptor: rounded, size: rounded.pointSize)
				}
				return UIFont(descriptor: descriptor, size: descriptor.pointSize)
			case .monospaced:
				return UIFont.monospacedSystemFont(ofSize: descriptor.pointSize, weight: .regular)
		}
	}
}
