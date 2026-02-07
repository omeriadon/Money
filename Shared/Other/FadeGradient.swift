//
//  FadeGradient.swift
//  Money
//
//  Created by Adon Omeri on 7/2/2026.
//

import SwiftUI

enum FadeGradient {
	static let stops: [Gradient.Stop] = {
		let steps = 30
		let maxOpacity: CGFloat = 0.8

		return (0 ... steps).map { i in
			let t = CGFloat(i) / CGFloat(steps)
			let eased = t < 0.5
				? 4 * t * t * t
				: 1 - pow(-2 * t + 2, 3) / 2
			return .init(
				color: .black.opacity(maxOpacity * (1 - eased)),
				location: t
			)
		}
	}()
}
