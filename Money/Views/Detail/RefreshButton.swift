//
//  RefreshButton.swift
//  Money
//
//  Created by Adon Omeri on 19/1/2026.
//

import SwiftUI

struct RefreshButton: View {
	@Binding var isLoading: Bool
	@Binding var showSuccess: Bool
	let action: () async -> Void

	private var iconName: String {
		if isLoading {
			return "arrow.triangle.2.circlepath"
		}
		if showSuccess {
			return "checkmark"
		}
		return "arrow.triangle.2.circlepath"
	}

	var body: some View {
		
		Button {
			Task { await action() }
		} label: {
			Image(systemName: iconName)
				.contentTransition(.symbolEffect(.replace))
		}
		.animation(.easeInOut, value: "\(isLoading)\(showSuccess)")
		.disabled(isLoading)
	}
}
