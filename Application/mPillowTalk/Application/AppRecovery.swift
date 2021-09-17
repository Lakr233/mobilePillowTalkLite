//
//  AppRecovery.swift
//  mPillowTalk
//
//  Created by Lakr Aream on 4/17/21.
//

import SwiftUI
import UIKit

private struct AppRecoveryItemView: View {
    let LSAppRecoveryOptionButton = NSLocalizedString("APP_RECOVERY_OPTION_CONTINUE", comment: "Continue")

    var iconSystemName: String
    var title: String
    var description: String
    var action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .bottom) {
                Image(systemName: iconSystemName)
                Text(title)
                Spacer()
            }
            .font(.system(size: 22, weight: .semibold))
            Divider()
            Text(description)
                .multilineTextAlignment(.leading)
                .font(.system(size: 12, weight: .regular))
            Spacer()
            Button(action: {
                action()
            }, label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.right.circle.fill")
                            .scaleEffect(0.95)
                        Text(LSAppRecoveryOptionButton)
                    }
                    .foregroundColor(.white)
                    .font(.system(size: 17, weight: .regular))
                    .padding(6)
                }
            })
                .frame(height: 36)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .foregroundColor(.lightGray)
        )
    }
}

struct AppRecoveryView: View {
    let LSAppRecovery = NSLocalizedString("APP_RECOVERY_TITLE", comment: "App Recovery")
    let LSAppRecoveryDescription = NSLocalizedString("APP_RECOVERY_DESCRIPTION", comment: "An error occurred previously during application setup.")

    let LSAppRecoveryOptionReset = NSLocalizedString("APP_RECOVERY_OPTION_RESET", comment: "Reset Application")
    let LSAppRecoveryOptionResetDescription = NSLocalizedString("APP_RECOVERY_OPTION_RESET_DESCRIPTION", comment: "Delete all your data in this app and start fresh.")
    let LSAppRecoveryOptionReboot = NSLocalizedString("APP_RECOVERY_OPTION_REBOOT", comment: "Try Again")
    let LSAppRecoveryOptionRebootDescription = NSLocalizedString("APP_RECOVERY_OPTION_REBOOT_DESCRIPTION", comment: "Exit the app and try again. Try something else if error priests.")

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading) {
                    Text(LSAppRecoveryDescription)
                        .multilineTextAlignment(.leading)
                        .font(.system(size: 15, weight: .regular))
                    Divider()
                    NavigationLink(
                        destination: AppLogView(showCurrentLog: false),
                        label: {
                            Text(mPillowTalkApp.obtainApplicationDescription())
                                .font(.system(size: 12, weight: .regular, design: .monospaced))
                        }
                    )
                    Divider()
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 300))]) {
                        AppRecoveryItemView(iconSystemName: "trash",
                                            title: LSAppRecoveryOptionReset,
                                            description: LSAppRecoveryOptionResetDescription) {
                            if let documentLocation = mPillowTalkApp.obtainApplicationStoragePath()
                            {
                                try? FileManager.default.removeItem(atPath: documentLocation.path)
                            }
                            mPillowTalkApp.lastBootSucceed = true
                            usleep(5000)
                            UIControl().sendAction(#selector(NSXPCConnection.suspend),
                                                   to: UIApplication.shared, for: nil)
                            sleep(1)
                            exit(0)
                        }
                        AppRecoveryItemView(iconSystemName: "exclamationmark.arrow.circlepath",
                                            title: LSAppRecoveryOptionReboot,
                                            description: LSAppRecoveryOptionRebootDescription) {
                            mPillowTalkApp.lastBootSucceed = true
                            usleep(5000)
                            UIControl().sendAction(#selector(NSXPCConnection.suspend),
                                                   to: UIApplication.shared, for: nil)
                            sleep(1)
                            exit(0)
                        }
                    }
                    Divider()
                    Text(Date().description(with: .current))
                        .font(.system(size: 12, weight: .regular, design: .default))
                }
                .padding()
            }
            .navigationTitle(LSAppRecovery)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

#if DEBUG
    struct AppRecoveryView_Previews: PreviewProvider {
        static var previews: some View {
            AppRecoveryView()
                .previewLayout(.fixed(width: 666, height: 444))
        }
    }
#endif
