//
//  Color+Extension.swift
//  mPillowTalk
//
//  Created by Innei on 2021/4/25.
//

import SwiftUI

public extension Color {
    static let systemBackground = Self(.systemBackground)
    static let systemGroupedBackground = Self(.systemGroupedBackground)
    static let systemGray = Self(.systemGray)
    static let systemGray2 = Self(.systemGray2)
    static let systemGray3 = Self(.systemGray3)
    static let systemGray4 = Self(.systemGray4)
    static let systemGray5 = Self(.systemGray5)
    static let systemGray6 = Self(.systemGray6)
    static let lightGray = Self("LIGHT_GRAY")
    static var overridableAccentColor = Color("AccentColor")
}

extension UIColor {
    convenience init(rgbValue: Int) {
        self.init(
            red: CGFloat(Float((rgbValue & 0xFF0000) >> 16) / 255.0),
            green: CGFloat(Float((rgbValue & 0x00FF00) >> 8) / 255.0),
            blue: CGFloat(Float((rgbValue & 0x0000FF) >> 0) / 255.0),
            alpha: 1.0
        )
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
