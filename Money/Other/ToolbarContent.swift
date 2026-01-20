//
//  ToolbarContent.swift
//  Money
//
//  Created by Adon Omeri on 20/1/2026.
//

import SwiftUI
import PortalTransitions

@ToolbarContentBuilder
var toolbarContent: some ToolbarContent {
	ToolbarItem(placement: .topBarLeading) {
		HStack {
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
					.portal(id: "logo", .destination)
			)
			.frame(width: 35, height: 35)
		}
	}
	.sharedBackgroundVisibility(.hidden)
}
