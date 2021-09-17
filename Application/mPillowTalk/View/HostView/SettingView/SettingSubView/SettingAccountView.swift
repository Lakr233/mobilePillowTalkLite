//
//  SettingAccountView.swift
//  mPillowTalk
//
//  Created by Lakr Aream on 5/30/21.
//

import PTFoundation
import SwiftUI

struct SettingAccountView: View {
    @State var serverKeyItems: [KeyItem] = []
    @State var appKeyItems: [KeyItem] = []

    struct KeyItem: Identifiable, Hashable {
        var id: String {
            privateKey + publicKey
        }

        var privateKey: String
        var publicKey: String

        init(privateKey: String, publicKey: String) {
            self.privateKey = privateKey
            self.publicKey = publicKey
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text(NSLocalizedString("KEY_FROM_SERVER", comment: "Key From Server"))
                    .font(.system(size: 18, weight: .semibold, design: .default))
                Divider()
                if serverKeyItems.count > 0 {
                    ForEach(serverKeyItems, id: \.id) { item in
                        NavigationLink(
                            destination: KeyView(privateKey: item.privateKey, publicKey: item.publicKey),
                            label: {
                                VStack {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text("SSH RSA Private Key")
                                                .font(.system(size: 16, weight: .semibold, design: .default))
                                            Text(item.privateKey)
                                                .font(.system(size: 14, weight: .regular, design: .monospaced))
                                                .frame(maxHeight: 80)
                                        }
                                        Spacer()
                                        Image(systemName: "arrow.forward")
                                    }
                                    Divider()
                                }
                            }
                        )
                        .buttonStyle(PlainButtonStyle())
                    }
                } else {
                    VStack(alignment: .leading) {
                        Text(NSLocalizedString("NO_KEY_FOUND", comment: "No Key Found"))
                            .font(.system(size: 16, weight: .semibold, design: .default))
                        Divider().opacity(0)
                    }
                    .padding(.top, 10)
                }
//                Spacer()
//                    .frame(height: 20)
//                Text(NSLocalizedString("KEY_FROM_APP_SOTRAGE", comment: "Key From App Storage"))
//                    .font(.system(size: 18, weight: .semibold, design: .default))
//                if appKeyItems.count > 0 {
//                    ForEach(appKeyItems, id: \.id) { item in
//                        NavigationLink(
//                            destination: KeyView(privateKey: item.privateKey, publicKey: item.publicKey),
//                            label: {
//                                VStack {
//                                    HStack {
//                                        VStack(alignment: .leading) {
//                                            Text("SSH RSA")
//                                                .font(.system(size: 16, weight: .semibold, design: .default))
//                                            Text(item.privateKey)
//                                                .font(.system(size: 14, weight: .regular, design: .monospaced))
//                                                .frame(maxHeight: 80)
//                                        }
//                                        Spacer()
//                                        Image(systemName: "arrow.forward")
//                                    }
//                                    Divider()
//                                }
//                            }
//                        )
//                        .buttonStyle(PlainButtonStyle())
//                    }
//                } else {
//                    VStack(alignment: .leading) {
//                        Text(NSLocalizedString("NO_KEY_FOUND", comment: "No Key Found"))
//                            .font(.system(size: 16, weight: .semibold, design: .default))
//                        Divider().opacity(0)
//                    }
//                    .padding(.top, 10)
//                }
//                Divider()
                HStack {
                    Spacer()
                    Text(String(format: NSLocalizedString("%d_KEYS_IN_TOTAL", comment: "%d key(s) in total"), serverKeyItems.count + appKeyItems.count))
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    Spacer()
                }
            }
            .padding()
        }
        .navigationTitle(NSLocalizedString("KEY", comment: "Key"))
        .onAppear {
            updateKeyItems()
        }
    }

    func updateKeyItems() {
        let accounts = PTAccountManager
            .shared
            .obtainAccountKeyList()
            .map { str in
                PTAccountManager.shared.retrieveAccountWith(key: str)
            }
            .filter { item in
                guard let obj = item else {
                    return false
                }
                return obj.type == .secureShellWithKey
            }
            .map { account in
                account?.obtainDecryptedObject()
            }
        var items = Set<KeyItem>()
        for account in accounts {
            if let data = account?.representedObject,
               let str = String(data: data, encoding: .utf8)
            {
                items.insert(KeyItem(privateKey: str, publicKey: ""))
            }
        }
        serverKeyItems = items.sorted { $0.privateKey < $1.privateKey }
    }
}
