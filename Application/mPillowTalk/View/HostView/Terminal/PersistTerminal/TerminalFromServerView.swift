//
//  TerminalFromServerView.swift
//  mPillowTalk
//
//  Created by Lakr Aream on 5/31/21.
//

import PTFoundation
import SwiftUI

struct TerminalFromServerView: View {
    let descriprot: String
    let isLoading: Bool

    var body: some View {
        ZStack {
            VStack(alignment: .leading) {
                Text(obtainServerTitle(id: descriprot))
                    .font(.system(size: 16, weight: .semibold, design: .default))
                Text(obtainServerSubtitle(id: descriprot))
                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                    .opacity(0.5)
                Spacer().frame(height: 18)
                HStack(alignment: .bottom) {
                    Group {
                        if obtainServerAccountType(id: descriprot) == .secureShellWithPassword {
                            HStack(spacing: 2) {
                                Image(systemName: "textbox")
                                Text(NSLocalizedString("LOGIN_WITH_PASSWORD", comment: "Login With Password"))
                            }
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundColor(.overridableAccentColor)
                        } else if obtainServerAccountType(id: descriprot) == .secureShellWithKey {
                            HStack(spacing: 2) {
                                Image(systemName: "key")
                                Text(NSLocalizedString("LOGIN_WITH_KEY", comment: "Login With Key"))
                            }
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundColor(.overridableAccentColor)
                        } else {
                            Text("???")
                        }
                    }
                    Spacer()
                    Group {
                        Text(NSLocalizedString("TAP_TO_OPEN", comment: "Tap to Open"))
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .opacity(0.5)
                    }
                }
            }
            .padding()
            .background(Color.lightGray)
            Rectangle()
                .foregroundColor(Color.black)
                .opacity(0.2)
                .overlay(ProgressView())
                .opacity(isLoading ? 1 : 0)
        }
        .frame(height: 100)
        .cornerRadius(12)
    }

    func obtainServerTitle(id: String) -> String {
        let server = PTServerManager.shared.obtainServer(withKey: id)
        return server?.obtainPossibleName() ?? "Unknown"
    }

    func obtainServerSubtitle(id: String) -> String {
        let server = PTServerManager.shared.obtainServer(withKey: id)
        return "\(server?.host ?? "Unknown Host"):\(String(server?.port ?? 0))"
    }

    func obtainServerAccountType(id: String) -> PTAccountManager.AccountType {
        let server = PTServerManager.shared.obtainServer(withKey: id)
        let account = PTAccountManager.shared.retrieveAccountWith(key: server?.accountDescriptor ?? "")
        return account?.type ?? .secureShellWithPassword
    }
}
