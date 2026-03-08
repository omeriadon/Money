//
//  ToolbarContent.swift
//  Money
//
//  Created by Adon Omeri on 20/1/2026.
//

import SwiftUI

@ToolbarContentBuilder
var toolbarContent: some ToolbarContent {
	ToolbarItem(placement: .topBarLeading) {
		Image("Logo")
			.renderingMode(.template)
			.resizable()
			.aspectRatio(contentMode: .fit)
			.foregroundStyle(.yellow.gradient)
			.scaleEffect(1.3)
	}
	#if os(iOS)
	.sharedBackgroundVisibility(.hidden)
	#endif
}
