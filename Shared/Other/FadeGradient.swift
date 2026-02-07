//
//  FadeGradient.swift
//  Money
//
//  Created by Adon Omeri on 7/2/2026.
//

import SwiftUI

enum FadeGradient {
	static let stops: [Gradient.Stop] = {
		let start: CGFloat = 0.5
		let steps = 20
		let gamma: CGFloat = 1

		return (0 ... steps).map { i in
			let t = CGFloat(i) / CGFloat(steps)
			let curved = pow(1 - t, gamma)
			return .init(
				color: .black.opacity(0.8 * curved),
				location: start + t * (1 - start)
			)
		}
	}()
}
