//
//  ReleaseMenuItemView.swift
//  Money
//
//  Created by Adon Omeri on 2/3/2026.
//

import UIKit

final class ReleaseMenuItemView: UIView {
	init(release: WhatsNewRelease, isSelected: Bool, font: UIFont) {
		super.init(frame: .zero)

		let logo = UIImageView()
		logo.image = UIImage(named: "Logo")?.resized(to: CGSize(width: 20, height: 20)).withRenderingMode(.alwaysTemplate)
		logo.tintColor = .label
		logo.contentMode = .scaleAspectFit
		logo.setContentHuggingPriority(.required, for: .horizontal)

		let label = UILabel()
		label.text = "\(release.version) (\(release.build))"
		label.font = UIFont(descriptor: font.fontDescriptor, size: UIFont.preferredFont(forTextStyle: .body).pointSize)

		let checkmark = UIImageView()
		checkmark.image = UIImage(systemName: "checkmark", withConfiguration: UIImage.SymbolConfiguration(weight: .semibold))
		checkmark.tintColor = .label
		checkmark.contentMode = .scaleAspectFit
		checkmark.alpha = isSelected ? 1 : 0
		checkmark.setContentHuggingPriority(.required, for: .horizontal)

		let stack = UIStackView(arrangedSubviews: [logo, label, UIView(), checkmark])
		stack.axis = .horizontal
		stack.spacing = 10
		stack.alignment = .center
		stack.translatesAutoresizingMaskIntoConstraints = false

		addSubview(stack)
		NSLayoutConstraint.activate([
			stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
			stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
			stack.topAnchor.constraint(equalTo: topAnchor, constant: 11),
			stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -11),
			checkmark.widthAnchor.constraint(equalToConstant: 16),
			checkmark.heightAnchor.constraint(equalToConstant: 16),
		])
	}

	@available(*, unavailable)
	required init?(coder _: NSCoder) {
		fatalError()
	}
}
