//
//  ValuePicker.swift
//  Money
//
//  Created by Adon Omeri on 17/2/2026.
//

import SwiftUI

public struct ValuePicker<SelectionValue: Hashable, Content: View, CurrentLabel: View>: View {
	private let title: LocalizedStringKey
	private let selection: Binding<SelectionValue>
	private let content: Content
	private let currentLabel: CurrentLabel

	public init(
		_ title: LocalizedStringKey,
		selection: Binding<SelectionValue>,
		@ViewBuilder currentLabel: () -> CurrentLabel,
		@ViewBuilder content: () -> Content
	) {
		self.title = title
		self.selection = selection
		self.currentLabel = currentLabel()
		self.content = content()
	}

	public var body: some View {
		HStack {
			Text(title)
				.foregroundStyle(.primary)
			Spacer()
			#if os(watchOS)
				NavigationLink {
					List {
						_VariadicView.Tree(ValuePickerOptions(selectedValue: selection)) {
							content
								.foregroundStyle(.secondary)
						}
					}
					.navigationTitle(title)
					.navigationBarTitleDisplayMode(.inline)
				} label: {
					currentLabel
				}
			#else
				Menu {
					_VariadicView.Tree(ValuePickerMenuOptions(selectedValue: selection)) {
						content
							.foregroundStyle(.secondary)
					}
				} label: {
					currentLabel
						.frame(maxWidth: .infinity, alignment: .trailing)
						.padding(.vertical, 2)
				}
			#endif
		}
	}
}

private struct ValuePickerMenuOptions<Value: Hashable>: _VariadicView.MultiViewRoot {
	private let selectedValue: Binding<Value>

	init(selectedValue: Binding<Value>) {
		self.selectedValue = selectedValue
	}

	func body(children: _VariadicView.Children) -> some View {
		ForEach(children) { child in
			ValuePickerMenuOption(
				selectedValue: selectedValue,
				value: child[CustomTagValueTraitKey<Value>.self]
			) {
				child
			}
		}
	}
}

private struct ValuePickerMenuOption<Content: View, Value: Hashable>: View {
	private let selectedValue: Binding<Value>
	private let value: Value?
	private let content: Content

	init(
		selectedValue: Binding<Value>,
		value: CustomTagValueTraitKey<Value>.Value,
		@ViewBuilder _ content: () -> Content
	) {
		self.selectedValue = selectedValue
		self.value = if case let .tagged(tag) = value { tag } else { nil }
		self.content = content()
	}

	var body: some View {
		Button {
			if let value { selectedValue.wrappedValue = value }
		} label: {
			HStack {
				content.tint(.primary)
				if isSelected {
					Image(systemName: "checkmark")
				}
			}
		}
	}

	private var isSelected: Bool {
		selectedValue.wrappedValue == value
	}
}

private struct ValuePickerOptions<Value: Hashable>: _VariadicView.MultiViewRoot {
	private let selectedValue: Binding<Value>

	init(selectedValue: Binding<Value>) {
		self.selectedValue = selectedValue
	}

	func body(children: _VariadicView.Children) -> some View {
		Section {
			ForEach(children) { child in
				ValuePickerOption(
					selectedValue: selectedValue,
					value: child[CustomTagValueTraitKey<Value>.self]
				) { child }
			}
		}
	}
}

private struct ValuePickerOption<Content: View, Value: Hashable>: View {
	@Environment(\.dismiss) private var dismiss
	private let selectedValue: Binding<Value>
	private let value: Value?
	private let content: Content

	init(
		selectedValue: Binding<Value>,
		value: CustomTagValueTraitKey<Value>.Value,
		@ViewBuilder _ content: () -> Content
	) {
		self.selectedValue = selectedValue
		self.value = if case let .tagged(tag) = value { tag } else { nil }
		self.content = content()
	}

	var body: some View {
		Button {
			if let value { selectedValue.wrappedValue = value }
			dismiss()
		} label: {
			HStack {
				content
					.tint(.primary)
					.frame(maxWidth: .infinity, alignment: .leading)
				if isSelected {
					Image(systemName: "checkmark")
						.foregroundStyle(.tint)
						.font(.body.weight(.semibold))
						.accessibilityHidden(true)
				}
			}
			.accessibilityElement(children: .combine)
			.accessibilityAddTraits(isSelected ? .isSelected : [])
		}
	}

	private var isSelected: Bool {
		selectedValue.wrappedValue == value
	}
}

public extension View {
	func pickerTag<V: Hashable>(_ tag: V) -> some View {
		_trait(CustomTagValueTraitKey<V>.self, .tagged(tag))
	}
}

private struct CustomTagValueTraitKey<V: Hashable>: _ViewTraitKey {
	enum Value { case untagged, tagged(V) }
	static var defaultValue: Value {
		.untagged
	}
}
