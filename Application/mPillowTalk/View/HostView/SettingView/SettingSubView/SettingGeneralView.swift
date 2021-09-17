//
//  SettingGeneralView.swift
//  mPillowTalk
//
//  Created by Lakr Aream on 5/18/21.
//

import LocalAuthentication
import PTFoundation
import SwiftUI

struct SettingGeneralView: View {
    var body: some View {
        Group {
            ScrollView {
                VStack(spacing: 12) {
                    VStack(spacing: 4) {
                        Image("AppIcon-macOS")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                        Divider()
                        Divider().opacity(0)
                        Text(mPillowTalkApp.obtainApplicationDescription())
                            .font(.system(size: 8, weight: .regular, design: .rounded))
                        Text("Foundation ver:\(PTFoundation.version) Api:\(PTFoundation.apiVersion)")
                            .font(.system(size: 8, weight: .regular, design: .rounded))
                    }
                    .padding()
                    .background(SplashColorView(config: .init(colors: [#colorLiteral(red: 0.9586862922, green: 0.660125792, blue: 0.8447988033, alpha: 1), #colorLiteral(red: 0.8714533448, green: 0.723166883, blue: 0.9342088699, alpha: 1), #colorLiteral(red: 0.7458761334, green: 0.7851135731, blue: 0.9899476171, alpha: 1), #colorLiteral(red: 0.4398113191, green: 0.8953480721, blue: 0.9796616435, alpha: 1), #colorLiteral(red: 0.3484552801, green: 0.933657825, blue: 0.9058339596, alpha: 1), #colorLiteral(red: 0.5567936897, green: 0.9780793786, blue: 0.6893508434, alpha: 1)],
                                                              numsersOfColorDot: 24,
                                                              effect: UIBlurEffect(style: .light)),
                                                animated: .constant(true)))
                    .cornerRadius(12)
                    Section {
                        VStack(spacing: 4) {
                            Group {
                                SettingToggleView(icon: getLAContextTypeSystemImage(),
                                                  title: NSLocalizedString("APP_PROTECTION", comment: "App Protection"),
                                                  subTitle: NSLocalizedString("APP_PROTECTION_TINT", comment: "Protect us from unauthorized operations when app become active")) {
                                    Agent.shared.applicationProtected
                                } callback: { value in
                                    if Agent.shared.applicationProtected {
                                        let authResult = Agent
                                            .shared
                                            .authenticationWithBioIDSyncAndReturnIsSuccessOrError()
                                        if !authResult.0 { return }
                                    }
                                    Agent.shared.applicationProtected = value
                                }
                                Divider()
                                SettingToggleView(icon: "terminal",
                                                  title: NSLocalizedString("APP_PROTECTION_SCRIPT", comment: "Execution Protection"),
                                                  subTitle: NSLocalizedString("APP_PROTECTION_SCRIPT_TINT", comment: "Authenticate when execute script on server")) {
                                    Agent.shared.applicationProtectedScriptExecution
                                } callback: { value in
                                    if Agent.shared.applicationProtectedScriptExecution {
                                        let authResult = Agent
                                            .shared
                                            .authenticationWithBioIDSyncAndReturnIsSuccessOrError()
                                        if !authResult.0 { return }
                                    }
                                    Agent.shared.applicationProtectedScriptExecution = value
                                }
                            }
                            .padding(.horizontal, 8)
                        }
                        .background(Color.lightGray)
                        .cornerRadius(12)
                    }
                    Section {
                        VStack(spacing: 4) {
                            Group {
                                NavigationLink(destination: PairDeviceSenderView()) {
                                    SettingElementView(icon: "qrcode.viewfinder",
                                                       title: NSLocalizedString("TRANSFER_CONFIG", comment: "Transfer Config"),
                                                       subTitle: NSLocalizedString("TRANSFER_CONFIG_TINT", comment: "Send current configuration to another device"))
                                }
                                .buttonStyle(PlainButtonStyle())
                                Divider()
                                NavigationLink(destination: PairDeviceView()) {
                                    SettingElementView(icon: "qrcode",
                                                       title: NSLocalizedString("IMPORT_CONFIG", comment: "Import Configuration"),
                                                       subTitle: NSLocalizedString("IMPORT_CONFIG_TINT", comment: "Import and overwrite configuration from another device"))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.horizontal, 8)
                        }
                        .background(Color.lightGray)
                        .cornerRadius(12)
                    }
                    Spacer()
                        .frame(height: 50)
                }
                .padding()
            }
        }
        .navigationTitle(NSLocalizedString("GENERAL", comment: "General"))
    }

    func getLAContextTypeSystemImage() -> String {
        switch LAContext().biometricType {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        default:
            return "lock.shield"
        }
    }
}

struct SettingGeneralView_Previews: PreviewProvider {
    static var previews: some View {
        SettingGeneralView()
    }
}
