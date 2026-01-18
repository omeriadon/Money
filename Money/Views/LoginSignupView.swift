//
//  LoginSignupView.swift
//  Money
//
//  Created by Adon Omeri on 18/1/2026.
//

import SwiftUI

struct LoginSignupView: View {
	@EnvironmentObject var networkManager: NetworkManager
	var body: some View {
		GeometryReader { geo in
			NavigationStack {
				VStack(alignment: .center, spacing: 50) {
					Spacer()
					LinearGradient(
						colors: [Color.yellow, Color.yellow.opacity(0.8)],
						startPoint: .top,
						endPoint: .bottom
					)
					.mask(
						Image("Logo")
							.renderingMode(.template)
							.resizable()
							.aspectRatio(contentMode: .fit)
					)
					VStack(spacing: 10) {
						Text("Money")
							.font(.largeTitle.scaled(by: 2))
							.bold()
						Text("Track money simply and efficiently.")
							.multilineTextAlignment(.center)
					}

					GlassEffectContainer(spacing: 10) {
						Button {} label: {
							Text("Sign Up")
								.padding()
						}
						.buttonStyle(.glassProminent)
						.foregroundStyle(.black)

						Button {} label: {
							Text("Login")
								.padding()
						}
						.buttonStyle(.glass)
					}
					.frame(width: geo.size.width * 0.8)
					.buttonSizing(.flexible)
					.buttonBorderShape(.capsule)
				}
				.fontDesign(.monospaced)
			}
		}
	}
}

#Preview {
	LoginSignupView()
}
