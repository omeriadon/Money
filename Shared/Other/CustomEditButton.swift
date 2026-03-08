//
//  CustomEditButton.swift
//  Money
//
//  Created by Adon Omeri on 8/3/2026.
//

import SwiftUI

#if !os(watchOS)
	struct CustomEditButton: View {
		@Environment(\.editMode) var editMode

		private var isEditing: Bool {
			editMode?.wrappedValue.isEditing == true
		}

		var body: some View {
			Button {
				withAnimation(.smooth) {
					editMode?.wrappedValue = isEditing ? .inactive : .active
				}
			} label: {
				Image(systemName: isEditing ? "checkmark" : "pencil")
					.contentTransition(.symbolEffect(.replace))
			}
			.if(isEditing) { view in
				view.buttonStyle(.glassProminent)
			} elseApply: { view in
				view.buttonStyle(.glass)
			}
			.animation(.smooth, value: isEditing)
		}
	}
#endif
