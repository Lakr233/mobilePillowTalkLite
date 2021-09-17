//
//  KeyView.swift
//  mPillowTalk
//
//  Created by Lakr Aream on 2021/5/30.
//

import SwiftUI

struct KeyView: View {
    let privateKey: String
    let publicKey: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                if privateKey.count > 0 {
                    HStack {
                        Text(NSLocalizedString("PRIVATE_KEY", comment: "Private Key"))
                            .font(.system(size: 18, weight: .semibold, design: .default))
                        Spacer()
                        Button(action: {
                            UIPasteboard.general.string = privateKey
                        }, label: {
                            Text(NSLocalizedString("COPY", comment: "Copy"))
                                .font(.system(size: 14, weight: .regular, design: .default))
                        })
                    }
                    Divider()
                    Text(privateKey)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                }
                Spacer()
                    .frame(height: 20)
                if publicKey.count > 0 {
                    HStack {
                        Text(NSLocalizedString("PUBLIC_KEY", comment: "Public Key"))
                            .font(.system(size: 18, weight: .semibold, design: .default))
                        Spacer()
                        Button(action: {
                            UIPasteboard.general.string = publicKey
                        }, label: {
                            Text(NSLocalizedString("COPY", comment: "Copy"))
                                .font(.system(size: 14, weight: .regular, design: .default))
                        })
                    }
                    Divider()
                    Text(publicKey)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                }
                if privateKey.count < 1, publicKey.count < 1 {
                    Text(NSLocalizedString("RESOURCE_BROKEN", comment: "Resource Broken"))
                        .padding()
                }
            }
            .padding()
        }
        .navigationTitle(NSLocalizedString("KEY", comment: "Key"))
    }
}

struct KeyView_Previews: PreviewProvider {
    static var previews: some View {
        KeyView(privateKey: "", publicKey: "")
            .previewLayout(.fixed(width: 400, height: 800))
    }
}
