//
//  FontStylePickerButton.swift
//  Money
//
//  Created by Adon Omeri on 2/3/2026.
//

import Defaults
import SwiftUI
import UIKit

struct FontStylePickerButton: View {
	@Default(.fontDesignStyle) var fontDesignStyle

	var body: some View {
		_FontStyleTrigger(selected: $fontDesignStyle)
	}
}

private final class _GlassFontButton: UIButton {
	override func layoutSubviews() {
		super.layoutSubviews()
		layer.cornerRadius = 10
		layer.cornerCurve = .continuous
		subviews.first?.layer.cornerRadius = 10
	}
}

private struct _FontStyleTrigger: UIViewRepresentable {
	@Binding var selected: AppFontDesign

	func makeUIView(context _: Context) -> _GlassFontButton {
		var config = UIButton.Configuration.plain()
		config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
		let button = _GlassFontButton(configuration: config)
		button.showsMenuAsPrimaryAction = true
		button.backgroundColor = .clear
		button.tintColor = .label
		button.clipsToBounds = true
		return button
	}

	func updateUIView(_ button: _GlassFontButton, context _: Context) {
		let font = selected.uiFont(forTextStyle: .body)

		let chevronAttachment = NSTextAttachment()
		let chevronConfig = UIImage.SymbolConfiguration(textStyle: .body, scale: .medium)
		chevronAttachment.image = UIImage(systemName: "chevron.up.chevron.down", withConfiguration: chevronConfig)?
			.withTintColor(.systemYellow, renderingMode: .alwaysOriginal)

		let titleString = NSMutableAttributedString(string: selected.title + " ", attributes: [.font: font])
		titleString.append(NSAttributedString(attachment: chevronAttachment))

		var config = button.configuration
		config?.image = nil
		config?.attributedTitle = AttributedString(titleString)
		config?.baseForegroundColor = .systemYellow
		config?.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
		button.configuration = config
		button.contentHorizontalAlignment = .trailing

		let elements: [UIMenuElement] = AppFontDesign.allCases.compactMap { style in
			UIMenu.customViewElement {
				FontStyleMenuItemView(style: style, isSelected: style == selected)
			} primaryActionHandler: {
				DispatchQueue.main.async {
					selected = style
				}
			}
		}
		button.menu = UIMenu(children: elements)
	}
}
