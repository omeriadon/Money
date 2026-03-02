//
//  ReleasePickerButton.swift
//  Money
//
//  Created by Adon Omeri on 2/3/2026.
//

import Defaults
import SwiftUI
import UIKit

struct ReleasePickerButton: View {
	let releases: [(WhatsNewRelease, [WhatsNewItem])]
	@Binding var selectedRelease: WhatsNewRelease?
	@Default(.fontDesignStyle) var appFontDesign

	var body: some View {
		_MenuTrigger(releases: releases, selectedRelease: $selectedRelease, font: appFontDesign.rawValue)
			.fixedSize()
	}
}

private final class _GlassMenuButton: UIButton {
	override func layoutSubviews() {
		super.layoutSubviews()
		layer.cornerRadius = bounds.height / 2
		layer.cornerCurve = .continuous
		subviews.first?.layer.cornerRadius = bounds.height / 2
	}
}

private struct _MenuTrigger: UIViewRepresentable {
	let releases: [(WhatsNewRelease, [WhatsNewItem])]
	@Binding var selectedRelease: WhatsNewRelease?
	let font: String

	func makeUIView(context _: Context) -> _GlassMenuButton {
		var config = UIButton.Configuration.plain()
		config.imagePadding = 6
		config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
		config.imagePlacement = .leading

		let glassEffect = UIGlassEffect()
		glassEffect.isInteractive = true
		let effectView = UIVisualEffectView(effect: glassEffect)
		effectView.clipsToBounds = true
		effectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

		let button = _GlassMenuButton(configuration: config)
		button.showsMenuAsPrimaryAction = true
		button.backgroundColor = .clear
		button.tintColor = .white
		button.clipsToBounds = true
		button.insertSubview(effectView, at: 0)

		return button
	}

	func updateUIView(_ button: _GlassMenuButton, context _: Context) {
		var config = button.configuration
		config?.image = UIImage(named: "Logo")?
			.resized(to: CGSize(width: 20, height: 20))
			.withRenderingMode(.alwaysTemplate)
		let design = AppFontDesign(rawValue: font) ?? .monospaced
		config?.attributedTitle = AttributedString(
			selectedRelease.map { "\($0.version) (\($0.build))" } ?? "Select Release",
			attributes: AttributeContainer([.font: design.uiFont()])
		)
		button.configuration = config

		let elements: [UIMenuElement] = releases.map { release, _ in
			UIAction(
				title: "\(release.version) (\(release.build))",
				image: UIImage(named: "Logo")?
					.resized(to: CGSize(width: 20, height: 20))
					.withRenderingMode(.alwaysTemplate),
				state: release == selectedRelease ? .on : .off
			) { _ in
				DispatchQueue.main.async {
					withAnimation(.easeInOut(duration: 0.18)) {
						selectedRelease = release
					}
				}
			}
		}
		button.menu = UIMenu(children: elements)
	}
}

extension UIImage {
	func resized(to size: CGSize) -> UIImage {
		let renderer = UIGraphicsImageRenderer(size: size)
		return renderer.image { _ in draw(in: CGRect(origin: .zero, size: size)) }
	}
}
