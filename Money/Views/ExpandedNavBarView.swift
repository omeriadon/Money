import SwiftUI
import UIKit

// MARK: - View extension

extension View {
	func expandedNavBar(
		height: CGFloat = 60,
		@ViewBuilder content: () -> some View
	) -> some View {
		background(
			NavBarInjector(height: height, contentView: content())
		)
	}
}

// MARK: - UIViewControllerRepresentable (not UIViewRepresentable)

private struct NavBarInjector<C: View>: UIViewControllerRepresentable {
	let height: CGFloat
	let contentView: C

	func makeUIViewController(context _: Context) -> InjectorViewController<C> {
		InjectorViewController(height: height, contentView: contentView)
	}

	func updateUIViewController(_: InjectorViewController<C>, context _: Context) {}
}

// MARK: - The actual VC that has direct navigationItem access

final class InjectorViewController<C: View>: UIViewController {
	private let height: CGFloat
	private let contentView: C

	init(height: CGFloat, contentView: C) {
		self.height = height
		self.contentView = contentView
		super.init(nibName: nil, bundle: nil)
	}

	@available(*, unavailable)
	required init?(coder _: NSCoder) {
		fatalError()
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		view.isHidden = true
		view.backgroundColor = .clear
	}

	override func didMove(toParent parent: UIViewController?) {
		super.didMove(toParent: parent)
		// Walk up to find the hosting VC that owns the nav bar
		guard let navVC = navigationController,
		      let targetVC = navVC.topViewController,
		      let titleViewClass = NSClassFromString("_UINavigationBarTitleView") as? UIView.Type,
		      titleViewClass.responds(to: NSSelectorFromString("setHeight:"))
		else { return }

		let titleView = titleViewClass.init()
		titleView.perform(NSSelectorFromString("setHeight:"), with: height)
		titleView.perform(NSSelectorFromString("setHideStandardTitle:"), with: 1)

		let host = UIHostingController(rootView: contentView)
		host.view.backgroundColor = .clear
		host.view.translatesAutoresizingMaskIntoConstraints = false
		titleView.addSubview(host.view)

		NSLayoutConstraint.activate([
			host.view.leadingAnchor.constraint(equalTo: titleView.leadingAnchor, constant: 8),
			host.view.topAnchor.constraint(equalTo: titleView.topAnchor, constant: 8),
		])

		targetVC.navigationItem.titleView = titleView
	}
}
