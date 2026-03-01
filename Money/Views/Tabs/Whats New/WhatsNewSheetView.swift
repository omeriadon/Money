//
//  WhatsNewSheetView.swift
//  Money
//
//  Created by Adon Omeri on 28/2/2026.
//

import ColorfulX
import Inject
import SwiftUI

struct WhatsNewSheetView: View {
	@ObserveInjection var inject

	let release: WhatsNewRelease
	let items: [WhatsNewItem]
	let onDismiss: () -> Void

	@State private var colourfulColors: [Color] = [.black, .yellow, .black, .yellow, .white]
	@State private var colourfulSpeed: Double = 1.8
	@State private var colourfulBias: Double = 0.015
	@State private var colourfulNoise: Double = 50.0
	@State private var colourfulTransition: Double = 10.0
	@State private var frameLimit: Int = 120
	@State private var renderScale: Double = 1.0

	var body: some View {
		NavigationStack {
			ZStack {
				ColorfulView(
					color: $colourfulColors,
					speed: $colourfulSpeed,
					bias: $colourfulBias,
					noise: $colourfulNoise,
					transitionSpeed: $colourfulTransition,
					frameLimit: $frameLimit,
					renderScale: $renderScale
				)
				.opacity(0.5)
				.saturation(1.2)

				VStack(alignment: .center, spacing: 16) {
					ScrollView {
						Spacer()
							.frame(height: 50)
						VStack(alignment: .leading, spacing: 14) {
							ForEach(items) { item in
								HStack(alignment: .center, spacing: 12) {
									Image(systemName: item.symbolName)
										.resizable()
										.scaledToFit()
										.frame(width: 40, height: 40)
										.padding(15)
										.glassEffect(.clear.interactive(), in: RoundedRectangle(cornerRadius: 20))

									VStack(alignment: .leading, spacing: 4) {
										Text(item.title).font(.headline).bold()
										Text(item.description).font(.subheadline)
									}
								}
							}
						}
						.padding()
					}
					.scrollIndicatorsFlash(onAppear: true)
					.scrollBounceBehavior(.basedOnSize)
					.safeAreaBar(edge: .bottom, alignment: .center, spacing: 10) {
						Button {
							onDismiss()
						} label: {
							Text("OK")
								.font(.title)
								.padding(.vertical, 10)
						}
						.padding()
						.buttonStyle(.glassProminent)
						.foregroundStyle(.black)
						.buttonSizing(.flexible)
						.buttonBorderShape(.buttonBorder)
						.padding()
					}
					.safeAreaBar(edge: .top, alignment: .center) {
						VStack(spacing: 15) {
							Image("Logo")
								.renderingMode(.template)
								.resizable()
								.aspectRatio(contentMode: .fit)
								.foregroundStyle(.white)
								.frame(maxWidth: 100)
								.padding(24)
								.glassEffect(.clear.interactive(), in: RoundedRectangle(cornerRadius: 35))
							Text("What's New - \(release.version) (\(release.build))")
								.font(.title2.bold())
						}
						.padding(.top, 30)
					}
				}
			}
			.interactiveDismissDisabled()
			.ignoresSafeArea()
		}
		#if os(iOS)
		.enableInjection()
		#endif
	}
}
