//
//  Logo.swift
//  Money
//
//  Created by Adon Omeri on 18/1/2026.
//

import SwiftUI

struct Logo: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.size.width
        let height = rect.size.height
        path.move(to: CGPoint(x: 0.80078 * width, y: 0.62988 * height))
        path.addLine(to: CGPoint(x: 0.19922 * width, y: 0.62988 * height))
        path.move(to: CGPoint(x: 0.63099 * width, y: 0.63026 * height))
        path.addLine(to: CGPoint(x: 0.37144 * width, y: 0.37072 * height))
        path.move(to: CGPoint(x: 0.37144 * width, y: 0.37072 * height))
        path.addLine(to: CGPoint(x: 0.63099 * width, y: 0.11117 * height))
        path.move(to: CGPoint(x: 0.37144 * width, y: 0.88981 * height))
        path.addLine(to: CGPoint(x: 0.63099 * width, y: 0.63026 * height))
        path.move(to: CGPoint(x: 0.80078 * width, y: 0.37109 * height))
        path.addLine(to: CGPoint(x: 0.19922 * width, y: 0.37109 * height))
        return path
    }
}
