//
//  ReleasePickerButton.swift
//  Money
//
//  Created by Adon Omeri on 2/3/2026.
//

import SwiftUI
import UIKit

struct ReleasePickerButton: View {
	let releases: [(WhatsNewRelease, [WhatsNewItem])]
	@Binding var selectedRelease: WhatsNewRelease?

	var body: some View {
		_ReleasePickerUIButton(releases: releases, selectedRelease: $selectedRelease)
			.glassEffect(.regular.interactive(), in: .capsule)
	}
}

private struct _ReleasePickerUIButton: UIViewRepresentable {
	let releases: [(WhatsNewRelease, [WhatsNewItem])]
	@Binding var selectedRelease: WhatsNewRelease?

	func makeUIView(context _: Context) -> UIButton {
		var config = UIButton.Configuration.plain()
		config.imagePadding = 6
		config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
		config.imagePlacement = .leading
		let button = UIButton(configuration: config)
		button.showsMenuAsPrimaryAction = true
		button.backgroundColor = .clear
		return button
	}

	func updateUIView(_ button: UIButton, context _: Context) {
		var config = button.configuration
		config?.image = UIImage(named: "Logo")?
			.resized(to: CGSize(width: 20, height: 20))
			.withRenderingMode(.alwaysTemplate)
		config?.baseForegroundColor = .white
		config?.attributedTitle = AttributedString(
			selectedRelease.map { "\($0.version) (\($0.build))" } ?? "Select Release",
			attributes: AttributeContainer([.font: UIFont.preferredFont(forTextStyle: .title2)])
		)
		button.configuration = config
		button.tintColor = .white

		let elements: [UIMenuElement] = releases.map { release, _ in
			UIAction(
				title: "\(release.version) (\(release.build))",
				image: UIImage(named: "Logo")?.withRenderingMode(.alwaysTemplate),
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
