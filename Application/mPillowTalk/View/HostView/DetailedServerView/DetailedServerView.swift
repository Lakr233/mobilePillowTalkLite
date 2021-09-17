//
//  DetailedServerView.swift
//  mPillowTalk
//
//  Created by Lakr Aream on 5/1/21.
//

import PTFoundation
import SwiftUI

struct DetailedServerView: View {
    let serverDescriptor: PTServerManager.ServerDescriptor

    init(serverDescriptor: PTServerManager.ServerDescriptor) {
        self.serverDescriptor = serverDescriptor
    }

    @State var timestamp: TimeInterval? = nil
    @State var info: PTServerManager.ServerInfo? = nil

    @State var presentTerminal: Bool = false
    @State var shouldOpenScript: Bool = false

    let SectionHeaderFont = Font.system(size: 18, weight: .semibold, design: .default)
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        Group {
            if timestamp == nil || info == nil {
                ScrollView {
                    VStack(alignment: .leading) {
                        Text("🤷‍♂️")
                        Divider().opacity(0)
                        Text(NSLocalizedString("NO_DATA_AVAILABLE_PLEASE_TRY_AGAIN_LATER", comment: "No data available for this server, please try again later."))
                            .font(.system(size: 14, weight: .semibold, design: .default))
                        Divider().opacity(0)
                        ServerStatusBlockView(descriptor: "", isPlaceHolder: true)
                    }
                    .padding()
                }
            } else {
                ScrollView {
                    VStack {
                        DetailedDataElementView(timestamp: timestamp!, dataSource: info!, server: serverDescriptor)
                            .animation(.interactiveSpring())
                        Divider()
                        NavigationLink(destination: DetailedServerHistoryView(serverDescriptor: serverDescriptor)) {
                            HStack {
                                Image(systemName: "text.magnifyingglass")
                                Text(NSLocalizedString("HISTORY", comment: "History"))
                                Spacer()
                            }
                            .font(.system(size: 14, weight: .semibold, design: .default))
                            .padding()
                            .background(
                                Color
                                    .lightGray
                                    .frame(height: 40)
                                    .cornerRadius(8)
                            )
                        }
                    }
                    .padding()
                }
            }
        }
        .background(Group {
            VStack {
                NavigationLink(
                    destination: AssociatedTerminalView(serverDescriptor: serverDescriptor),
                    isActive: $presentTerminal,
                    label: {
                        Text("").hidden()
                    }
                )
                NavigationLink(
                    destination: Group {
                        ScrollView {
                            ScriptCollectionView(withInServer: serverDescriptor)
                                .padding()
                        }
                        .navigationTitle(NSLocalizedString("SIDEBAR_CODE_CLIP", comment: "Script"))
                    },
                    isActive: $shouldOpenScript,
                    label: {
                        Text("").opacity(0)
                    }
                )
            }
            .frame(width: 0, height: 0)
        })
        .onAppear {
            updateData()
        }
        .onReceive(timer) { _ in
            updateData()
        }
        .navigationBarItems(leading: Group {
            // placeholder
        }, trailing: HStack {
            Button(action: {
                presentTerminal = true
            }, label: {
                Image(systemName: "terminal")
            })
            Button(action: {
                shouldOpenScript.toggle()
            }, label: {
                Image(systemName: "paperplane")
            })
        })
    }

    func updateData() {
        if let get = PTServerManager.shared.obtainServerStatus(withKey: serverDescriptor),
           let ts = get.previousUpdate?.timeIntervalSince1970,
           let data = get.information
        {
            timestamp = ts
            info = data
        }
    }
}

struct DetailedServerView_Previews: PreviewProvider {
    static var previews: some View {
        DetailedServerView(serverDescriptor: "")
            .previewLayout(.fixed(width: 400, height: 1000))
    }
}
