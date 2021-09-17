//
//  Appearance.swift
//  mPillowTalk (Development)
//
//  Created by Innei on 2021/5/28.
//

import SwiftUI
import UIKit

public enum InternalColorScheme: Int {
    case auto = 0
    case light = 1
    case dark = 2

    func system() -> ColorScheme {
        switch self {
        case .auto:
            return InternalColorScheme.systemIndicator()
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }

    static func fromSystem() -> InternalColorScheme {
        let currentSystemScheme = UITraitCollection.current.userInterfaceStyle
        switch currentSystemScheme {
        case .light: return .light
        case .dark: return .dark
        default: return .auto
        }
    }

    static func systemIndicator() -> ColorScheme {
        if UITraitCollection.current.userInterfaceStyle == .light {
            return .light
        }
        return .dark
    }
}

class AppearanceStore: ObservableObject {
    static let shared = AppearanceStore()

    @AppStorage(wrappedValue: InternalColorScheme.auto.rawValue, "colorScheme")
    var storedColorScheme: Int

    @Published var colorScheme = ColorScheme.light

    init() {
        updateColorScheme()
    }

    func storeColorScheme(withValue: InternalColorScheme) {
        storedColorScheme = withValue.rawValue
        updateColorScheme()
    }

    func updateColorScheme() {
        guard let scheme = InternalColorScheme(rawValue: storedColorScheme) else {
            debugPrint("broken data found inside user default")
            storedColorScheme = InternalColorScheme.auto.rawValue
            return
        }
        if colorScheme != scheme.system() {
            DispatchQueue.main.async {
                self.colorScheme = scheme.system()
            }
        }
    }
}
