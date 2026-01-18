//
//  DismissKeyboard.swift
//  Money
//
//  Created by Adon Omeri on 18/1/2026.
//

import SwiftUI

extension View {
    func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
