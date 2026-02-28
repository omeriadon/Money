//
//  WhatsNewSheetView.swift
//  Money
//
//  Created by Adon Omeri on 28/2/2026.
//

import SwiftUI

private struct WhatsNewSheetView: View {
	let release: WhatsNewRelease
	let items: [WhatsNewItem]
	let onDismiss: () -> Void

	var body: some View {
		VStack(alignment: .leading, spacing: 16) {
			Text("What's New")
				.font(.title2.bold())

			Text("Version \(release.version) (\(release.build))")
				.font(.subheadline)
				.foregroundStyle(.secondary)

			ScrollView {
				VStack(alignment: .leading, spacing: 14) {
					ForEach(items) { item in
						HStack(alignment: .top, spacing: 12) {
							Image(systemName: item.symbolName)
								.frame(width: 24)
							VStack(alignment: .leading, spacing: 4) {
								Text(item.title).font(.headline)
								Text(item.description).font(.subheadline)
							}
						}
					}
				}
			}

			Button("OK") {
				onDismiss()
			}
			.frame(maxWidth: .infinity)
			.padding(.top, 4)
		}
		.padding()
	}
}
