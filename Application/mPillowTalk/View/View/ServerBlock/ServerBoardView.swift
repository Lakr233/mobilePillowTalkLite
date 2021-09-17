//
//  ServerView.swift
//  mPillowTalk
//
//  Created by Lakr Aream on 4/19/21.
//

import PTFoundation
import SwiftUI

struct ServerBoardView: View {
    @ObservedObject var agent = Agent.shared

    let LSTitleTint = NSLocalizedString("SERVER_STATUS", comment: "Server Status")

    var head: some View {
        HStack {
            Image(systemName: "square.stack.3d.down.forward.fill")
            if agent.serverDescriptorsSorted == agent.serverDescriptorsSortedSupervised {
                Text(LSTitleTint.uppercased())
                    .bold()
            } else {
                HStack(alignment: .bottom) {
                    Text(LSTitleTint.uppercased())
                        .font(.system(size: 16, weight: .bold, design: .default))
                    Text("\(agent.serverDescriptorsSortedSupervised.count)/\(agent.serverDescriptorsSorted.count)")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                }
            }
            Spacer()
            Group {
                Button(action: {
                    DispatchQueue.global().async {
                        for server in PTServerManager.shared.obtainServerList() {
                            PTServerManager.shared.updateServerSupervisionInfoNow(withKey: server.uuid)
                        }
                    }
                }, label: {
                    Text(NSLocalizedString("REFRESH_NOW", comment: "Refresh Now"))
                        .font(.system(size: 14, weight: .regular, design: .default))
                        .foregroundColor(.overridableAccentColor)
                })
            }
            .font(.system(size: 18, weight: .regular, design: .default))
            .foregroundColor(.overridableAccentColor)
        }
        .font(.system(size: 15, weight: .regular, design: .default))
    }

    var body: some View {
        VStack {
            head
            Divider()
            if agent.serverDescriptorsSortedSupervised.count < 1 {
                NoServerGuider()
            } else {
                container
            }
        }.background(
            // BUG FIX DONT REMOVE IT
            // Unable to present. Please file a bug.
            NavigationLink(destination: Text(""), label: { Text("") })
                .opacity(0)
                .disabled(true)
        )
    }

    var container: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 300))]) {
            ForEach(agent.serverDescriptorsSortedSupervised, id: \.self) { serverDescriptor in
                ServerBlockView(serverDescriptor: serverDescriptor)
                    .frame(height: 140)
            }
        }
    }
}

struct ServerBoardView_Previews: PreviewProvider {
    static var previews: some View {
        ServerBoardView()
            .previewLayout(.fixed(width: 600, height: 400))
    }
}
