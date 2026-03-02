//
//  FontStyleMenuItemView.swift
//  Money
//
//  Created by Adon Omeri on 2/3/2026.
//

import UIKit

final class FontStyleMenuItemView: UIView {
	init(style: AppFontDesign, isSelected: Bool) {
		super.init(frame: .zero)

		let label = UILabel()
		label.text = style.title
		label.font = style.uiFont(forTextStyle: .body)

		let checkmark = UIImageView()
		checkmark.image = UIImage(systemName: "checkmark", withConfiguration: UIImage.SymbolConfiguration(weight: .semibold))
		checkmark.tintColor = .label
		checkmark.contentMode = .scaleAspectFit
		checkmark.alpha = isSelected ? 1 : 0
		checkmark.setContentHuggingPriority(.required, for: .horizontal)

		let stack = UIStackView(arrangedSubviews: [label, UIView(), checkmark])
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
