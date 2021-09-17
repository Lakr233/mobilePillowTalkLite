//
//  NoServerGuider.swift
//  mPillowTalk
//
//  Created by Lakr Aream on 5/17/21.
//

import SwiftUI

struct NoServerGuider: View {
    let LSOperationAddServer = NSLocalizedString("ADD_SERVER", comment: "Add Server")
    let LSOperationTransfer = NSLocalizedString("TRANSFER_SERVER", comment: "Transfer Config")

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 300))]) {
            NavigationLink(destination: AddServerView()) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .foregroundColor(.lightGray)
                    HStack {
                        Image(systemName: "plus.viewfinder")
                        Text(LSOperationAddServer)
                    }
                }
            }
            .frame(height: 100)
            NavigationLink(
                destination: Group {
                    PairDeviceView()
                        .navigationTitle(LSOperationTransfer)
                        .navigationBarTitleDisplayMode(.inline)
                },
                label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .foregroundColor(.lightGray)
                        HStack {
                            Image(systemName: "paperplane")
                            Text(LSOperationTransfer)
                        }
                    }
                }
            )
            .frame(height: 100)
        }
    }
}

struct NoServerGuider_Previews: PreviewProvider {
    static var previews: some View {
        NoServerGuider()
    }
}
