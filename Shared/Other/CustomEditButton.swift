//
//  CustomEditButton.swift
//  Money
//
//  Created by Adon Omeri on 8/3/2026.
//

import SwiftUI

#if !os(watchOS)
	struct CustomEditButton: View {
		@Binding var editMode: EditMode

		private var isEditing: Bool {
			editMode.isEditing
		}

		var body: some View {
			Button {
				withAnimation(.smooth) {
					editMode = isEditing ? .inactive : .active
				}
			} label: {
				Image(systemName: isEditing ? "checkmark" : "pencil")
			}
			.if(isEditing) { view in
				view.buttonStyle(.glassProminent)
			} elseApply: { view in
				view.buttonStyle(.automatic)
			}
			.animation(.smooth, value: isEditing)
		}
	}
#endif
