//
//  if.swift
//  Money
//
//  Created by Adon Omeri on 22/1/2026.
//

import SwiftUI

extension View {
    @ViewBuilder
    func `if`(
        _ condition: Bool,
        transform: (Self) -> some View
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
