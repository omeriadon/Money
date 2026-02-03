//
//  FlowLayout.swift
//  Money
//
//  Created by Adon Omeri on 3/2/2026.
//

import SwiftUI

struct FlowLayout: Layout {
	var spacing: CGFloat = 8

	func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache _: inout ()) -> CGSize {
		let maxWidth = proposal.width ?? .infinity
		var x: CGFloat = 0
		var y: CGFloat = 0
		var rowHeight: CGFloat = 0

		for subview in subviews {
			let size = subview.sizeThatFits(.unspecified)
			if x + size.width > maxWidth {
				x = 0
				y += rowHeight + spacing
				rowHeight = 0
			}
			x += size.width + spacing
			rowHeight = max(rowHeight, size.height)
		}

		return CGSize(width: maxWidth, height: y + rowHeight)
	}

	func placeSubviews(in bounds: CGRect, proposal _: ProposedViewSize, subviews: Subviews, cache _: inout ()) {
		var row: [Subviews.Element] = []
		var rowWidth: CGFloat = 0
		var y: CGFloat = bounds.minY
		var rowHeight: CGFloat = 0
		let maxWidth = bounds.width

		for subview in subviews {
			let size = subview.sizeThatFits(.unspecified)
			if rowWidth + size.width + CGFloat(row.count) * spacing > maxWidth {
				// center current row
				let offsetX = (maxWidth - rowWidth - CGFloat(row.count - 1) * spacing) / 2
				var x = bounds.minX + offsetX
				for s in row {
					let sSize = s.sizeThatFits(.unspecified)
					s.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(sSize))
					x += sSize.width + spacing
				}
				// reset for next row
				row = []
				rowWidth = 0
				y += rowHeight + spacing
				rowHeight = 0
			}
			row.append(subview)
			rowWidth += size.width
			rowHeight = max(rowHeight, size.height)
		}

		// place last row
		if !row.isEmpty {
			let offsetX = (maxWidth - rowWidth - CGFloat(row.count - 1) * spacing) / 2
			var x = bounds.minX + offsetX
			for s in row {
				let sSize = s.sizeThatFits(.unspecified)
				s.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(sSize))
				x += sSize.width + spacing
			}
		}
	}
}
