//
//  SettingView.swift
//  mPillowTalk
//
//  Created by Lakr Aream on 4/29/21.
//

import SwiftUI

#if DEBUG
    import FLEX
#endif

struct SettingView: View {
    @StateObject var windowObserver = WindowObserver()

    var body: some View {
        Group {
            ScrollView {
                VStack(spacing: 12) {
                    Section {
                        VStack(spacing: 4) {
                            Group {
                                NavigationLink(destination: SettingGeneralView()) {
                                    SettingElementView(icon: "gear",
                                                       title: NSLocalizedString("GENERAL", comment: "General"),
                                                       subTitle: NSLocalizedString("GENERAL_SETTING_TINT", comment: "Configure the main features of Pillow Talk"))
                                }
                                .buttonStyle(PlainButtonStyle())
                                Divider()
                                NavigationLink(destination: SettingAppearanceView()) {
                                    SettingElementView(icon: "paintbrush",
                                                       title: NSLocalizedString("APPERANCE", comment: "Appearance"),
                                                       subTitle: NSLocalizedString("APPERANCE_SETTING_TINT", comment: "Make the app in your taste"))
                                }
                                .buttonStyle(PlainButtonStyle())
                                Divider()
                                NavigationLink(destination: SettingMonitorView()) {
                                    SettingElementView(icon: "metronome",
                                                       title: NSLocalizedString("MONITORING", comment: "Monitoring"),
                                                       subTitle: NSLocalizedString("MONITORING_SETTING_TINT", comment: "Adjust monitoring rate and others"))
                                }
                                .buttonStyle(PlainButtonStyle())
                                Divider()
                                NavigationLink(destination: SettingAccountView()) {
                                    SettingElementView(icon: "rectangle.stack.person.crop",
                                                       title: NSLocalizedString("KEY", comment: "Key"),
                                                       subTitle: NSLocalizedString("ACCOUNTS_SETTING_TINT", comment: "Manage accounts and keys associated with your server"))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.horizontal, 8)
                        }
                        .background(Color.lightGray)
                        .cornerRadius(12)
                    }
                    Section {
                        VStack(spacing: 4) {
                            Group {
                                NavigationLink(destination: SettingDiagView()) {
                                    SettingElementView(icon: "cross.case",
                                                       title: NSLocalizedString("DIAGNOSTIC", comment: "Diagnostic"),
                                                       subTitle: NSLocalizedString("DIAGNOSTIC_SETTING_TINT", comment: "Get here if something goes wrong"))
                                }
                                .buttonStyle(PlainButtonStyle())
                                Divider()
                                NavigationLink(destination: Text("Usage")) {
                                    SettingElementView(icon: "loupe",
                                                       title: NSLocalizedString("USAGE", comment: "Usage"),
                                                       subTitle: NSLocalizedString("USAGE_SETTING_TINT", comment: "Show the usage of the app"))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.horizontal, 8)
                        }
                        .background(Color.lightGray)
                        .cornerRadius(12)
                    }
                    Section {
                        VStack(spacing: 4) {
                            Group {
                                NavigationLink(destination: Text("Experimental")) {
                                    SettingElementView(icon: "pyramid",
                                                       title: NSLocalizedString("EXPERIMENTAL", comment: "Experimental"),
                                                       subTitle: NSLocalizedString("EXPERIMENTAL_SETTING_TINT", comment: "Testing new features here"))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.horizontal, 8)
                        }
                        .background(Color.lightGray)
                        .cornerRadius(12)
                    }
                    Section {
                        VStack(spacing: 4) {
                            Group {
                                NavigationLink(destination: Text("FAQ")) {
                                    SettingElementView(icon: "questionmark.circle",
                                                       title: "FAQ",
                                                       subTitle: NSLocalizedString("FAQ_SETTING_TINT", comment: "Frequently asked questions"))
                                }
                                .buttonStyle(PlainButtonStyle())
                                Divider()
                                NavigationLink(destination: Text("Support")) {
                                    SettingElementView(icon: "highlighter",
                                                       title: NSLocalizedString("SUPPORT", comment: "Support"),
                                                       subTitle: NSLocalizedString("SUPPORT_SETTING_TINT", comment: "Contact us if you still have questions"))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.horizontal, 8)
                        }
                        .background(Color.lightGray)
                        .cornerRadius(12)
                    }

                    #if DEBUG
                        debugArea
                    #endif
                }
                .padding()
            }
        }
        .navigationTitle(NSLocalizedString("SETTINGS", comment: "Settings"))
        .background(
            HostingWindowFinder { [weak windowObserver] window in
                windowObserver?.window = window
            }
        )
    }

    #if DEBUG
        var debugArea: some View {
            VStack(alignment: .leading, spacing: 12) {
                Divider()
                Text("Developer Area")
                    .bold()
                Button {
                    FLEXManager.shared.showExplorer()
                } label: {
                    HStack {
                        Label("Show FLEX Debugger".uppercased(), systemImage: "ladybug")
                        Spacer()
                    }
                    .padding()
                    .frame(height: 40)
                    .background(
                        Color.lightGray
                    )
                    .cornerRadius(8)
                }
                Button {
                    askAndSetBootFailed(window: windowObserver.window)
                } label: {
                    HStack {
                        Label("Simulate Boot Failure".uppercased(), systemImage: "ladybug")
                        Spacer()
                    }
                    .padding()
                    .frame(height: 40)
                    .background(
                        Color.lightGray
                    )
                    .cornerRadius(8)
                }
            }
        }
    #endif
}

struct SettingView_Previews: PreviewProvider {
    static var previews: some View {
        SettingView()
            .previewLayout(.fixed(width: 800, height: 500))
    }
}
