//
//  TerminalLoader.swift
//  mPillowTalk
//
//  Created by Lakr Aream on 5/28/21.
//

import PTFoundation
import SwiftUI

struct TerminalLoader: View {
    @ObservedObject var agent = Agent.shared
    @StateObject var windowObserver = WindowObserver()

    @State var loadingItem: [String: Bool] = [:]
    @State var terminateAllSheet: Bool = false

    var body: some View {
        Group {
            if agent.terminalInstance.count < 1, agent.serverSectionsSorted.count < 1 {
                ZStack {
                    VStack {
                        Image(systemName: "questionmark.folder.fill")
                            .font(.system(size: 66, weight: .semibold, design: .default))
                        Spacer().frame(height: 20)
                        Text(NSLocalizedString("NO_SESSION_CAN_OPEN", comment: "No session can be opened, please add a server first!"))
                            .font(.system(size: 22, weight: .semibold, design: .default))
                    }
                    .padding()
                }
                .navigationTitle(NSLocalizedString("REMOTE_LOGIN", comment: "Remote Login"))
            } else {
                ScrollView {
                    VStack(alignment: .leading) {
                        if agent.terminalInstance.count < 1 {
                            if agent.serverDescriptorsSorted.count < 1 {
                                Text("").hidden()
                            } else {
                                Text(NSLocalizedString("NO_SESSION_OPENED", comment: "No Session Opened"))
                                    .font(.system(size: 18, weight: .semibold, design: .default))
                                Divider()
                            }
                        } else {
                            Text(NSLocalizedString("SESSIONS", comment: "Sessions"))
                                .font(.system(size: 18, weight: .semibold, design: .default))
                            Divider()
                            ForEach(agent.terminalInstance, id: \.id) { instance in
                                PersistTerminalInstanceView(instanceRef: instance)
                            }
                            Divider()
                        }
                        if agent.serverSectionsSorted.count > 0 {
                            Spacer().frame(height: 20)
                            Text(NSLocalizedString("OPEN_SESSION_FROM_SERVER", comment: "Open Session From Server"))
                                .font(.system(size: 18, weight: .semibold, design: .default))
                            Divider()
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))]) {
                                ForEach(agent.serverDescriptorsSorted, id: \.self) { sd in
                                    TerminalFromServerView(descriprot: sd, isLoading: loadingItem[sd, default: false])
                                        .onTapGesture {
                                            if loadingItem[sd, default: false] {
                                                return
                                            }
                                            withAnimation(.interactiveSpring()) {
                                                loadingItem[sd, default: false] = true
                                                PersistTerminalInstance.openConnection(withServer: sd, onComplete: { instance in
                                                    DispatchQueue.main.async {
                                                        loadingItem[sd, default: false] = false
                                                        if instance == nil {
                                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                                                // wait bio auth to close it's window
                                                                let alert = UIAlertController(title: NSLocalizedString("ERROR", comment: "Error"),
                                                                                              message: NSLocalizedString("CONNECT_FAILED", comment: "Failed to open session for shell, please try again later."),
                                                                                              preferredStyle: .alert)
                                                                alert.addAction(UIAlertAction(title: NSLocalizedString("DONE", comment: "Done"),
                                                                                              style: .default,
                                                                                              handler: nil))
                                                                windowObserver.window?.topMostViewController?.present(alert, animated: true, completion: nil)
                                                            }
                                                        }
                                                    }
                                                })
                                            }
                                        }
                                }
                            }
                            Divider()
                        }
                    }
                    .padding()
                }
            }
        }
        .background(
            HostingWindowFinder { [weak windowObserver] window in
                windowObserver?.window = window
            }
        )
        .navigationBarItems(trailing: Group {
            Button(action: {
                terminateAllSheet.toggle()
            }, label: {
                Text(NSLocalizedString("TERMINATE_ALL", comment: "Terminate All"))
            })
                .opacity(agent.terminalInstance.count > 0 ? 1 : 0)
        })
        .alert(isPresented: $terminateAllSheet, content: {
            Alert(title: Text(NSLocalizedString("TERMINATE_ALL", comment: "Terminate All")),
                  message: Text(NSLocalizedString("TERMINATE_ALL_TINT", comment: "Are you sure you want to terminate all session?")),
                  primaryButton: .cancel(Text(NSLocalizedString("CANCEL", comment: "Cancel")), action: {}),
                  secondaryButton: .destructive(Text(NSLocalizedString("CONTINUE", comment: "Continue")), action: {
                      let get = agent.terminalInstance
                      get.forEach { instance in
                          instance.terminate()
                      }
                  }))
        })
        .navigationTitle(NSLocalizedString("REMOTE_LOGIN", comment: "Remote Login"))
    }
}

struct TerminalLoader_Previews: PreviewProvider {
    static var previews: some View {
        TerminalLoader()
    }
}
