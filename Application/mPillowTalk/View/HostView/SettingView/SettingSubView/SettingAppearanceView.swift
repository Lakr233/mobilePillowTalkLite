//
//  SettingAppearance.swift
//  mPillowTalk (Development)
//
//  Created by Innei on 2021/5/28.
//

import SwiftUI

struct SettingAppearanceView: View {
    @ObservedObject var appearance = AppearanceStore.shared

    let ThemeMode = [
        NSLocalizedString("FOLLOW_SYSTEM", comment: "Follow System"),
        NSLocalizedString("LIGHT_MODE", comment: "Light Mode"),
        NSLocalizedString("DARK_MODE", comment: "Dark Mode"),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                VStack {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "moon.fill")
                            Text(NSLocalizedString("THEME", comment: "theme"))
                            Spacer()
                        }
                        .font(.system(size: 18, weight: .semibold, design: .default))
                        Text(NSLocalizedString("THEME_TINT", comment: "Override app's color scheme here"))
                            .font(.system(size: 14, weight: .regular, design: .default))
                            .opacity(0.5)
                    }

                    Divider()

                    ForEach(0 ..< ThemeMode.count, id: \.self) { idx in
                        let mode = ThemeMode[idx]
                        Button(action: {
                            guard let current = InternalColorScheme(rawValue: idx) else {
                                debugPrint("bad color scheme")
                                return
                            }
                            appearance.storeColorScheme(withValue: current)
                        }) {
                            HStack {
                                Text(mode)
                                    .foregroundColor(
                                        appearance.storedColorScheme == idx
                                            ? Color.overridableAccentColor
                                            : Color.primary
                                    )
                                Spacer()
                                if appearance.storedColorScheme == idx {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.overridableAccentColor)
                                }
                            }
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .frame(height: 30)
                        }
                    }
                }
                .padding()
                .background(Color.lightGray)
                .cornerRadius(12)
            }
        }
        .padding()
        .navigationTitle(NSLocalizedString("APPERANCE", comment: "外观"))
    }
}

struct SettingAppearance_Previews: PreviewProvider {
    static var previews: some View {
        SettingAppearanceView()
            .previewLayout(.fixed(width: 300, height: 600))
    }
}
