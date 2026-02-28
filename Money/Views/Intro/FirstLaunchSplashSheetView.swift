//
//  FirstLaunchSplashSheetView.swift
//  Money
//
//  Created by GitHub Copilot on 27/2/2026.
//

import ColorfulX
import Defaults
import SwiftUI

struct FirstLaunchSplashSheetView: View {
	@Environment(\.dismiss) private var dismiss

	@Default(.hasSeenIntroSplash) var hasSeenIntroSplash
	@State private var colourfulColors: [Color] = [.black, .yellow, .black, .yellow, .white]
	@State private var colourfulSpeed: Double = 1.8
	@State private var colourfulBias: Double = 0.015
	@State private var colourfulNoise: Double = 50.0
	@State private var colourfulTransition: Double = 10.0
	@State private var frameLimit: Int = 120
	@State private var renderScale: Double = 1.0

	var body: some View {
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
			.ignoresSafeArea()

			VStack(spacing: 24) {
				Spacer()

				Image("Logo")
					.renderingMode(.template)
					.resizable()
					.aspectRatio(contentMode: .fit)
					.foregroundStyle(.white)
					.frame(maxWidth: 260)
					.padding(24)
					.glassEffect(.clear.interactive(), in: RoundedRectangle(cornerRadius: 70))
					.padding(.bottom, 20)

				VStack(spacing: 10) {
					Text("Welcome to Money")
						.font(.largeTitle.bold())

					Text("Track every dollar with a clean, fast, and focused experience.")
						.font(.headline)
						.multilineTextAlignment(.center)
				}
				.padding(.horizontal, 24)
				.foregroundStyle(.white)

				Spacer()

				Button {
					hasSeenIntroSplash = true
					dismiss()
				} label: {
					Label("Go", systemImage: "arrow.right")
						.font(.title)
						.padding(.vertical, 14)
						.frame(maxWidth: .infinity)
				}
				.buttonStyle(.glassProminent)
				.tint(.yellow)
				.foregroundStyle(.black)
				.padding(.horizontal, 28)
			}
		}
		.interactiveDismissDisabled()
		.presentationDetents([.large])
		.presentationDragIndicator(.hidden)
		#if os(iOS)
			.enableInjection()
		#endif
	}

	#if DEBUG && os(iOS)
		@ObserveInjection var forceRedraw
	#endif
}
