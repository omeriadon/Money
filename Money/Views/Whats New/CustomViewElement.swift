import UIKit

extension UIMenu {
	static func customViewElement(
		_ viewProvider: @escaping ViewProvider,
		primaryActionHandler: Handler? = nil
	) -> UIMenuElement? {
		guard let elementClass = NSClassFromString("UICustomViewMenuElement") as? NSObject.Type else { return nil }

		let createSelector = NSSelectorFromString("elementWithViewProvider:")
		guard elementClass.responds(to: createSelector) else { return nil }

		let result = elementClass.perform(createSelector, with: viewProvider)
		guard let element = result?.takeUnretainedValue() as? UIMenuElement else { return nil }

		if let handler = primaryActionHandler {
			let handlerSelector = NSSelectorFromString("setPrimaryActionHandler:")
			if element.responds(to: handlerSelector) {
				element.perform(handlerSelector, with: handler)
			}
		}

		return element
	}

	typealias ViewProvider = @convention(block) () -> UIView
	typealias Handler = @convention(block) () -> Void
}
