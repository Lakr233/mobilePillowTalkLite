//
//  ServerListItem.swift
//  mPillowTalk
//
//  Created by Lakr Aream on 2021/5/30.
//

import PTFoundation
import SwiftUI

struct ServerListItem: View {
    @State var server: PTServerManager.Server
    @State var editViewShouldActive: Bool = false

    @StateObject var windowObserver = WindowObserver()

    var body: some View {
        ZStack {
            NavigationLink(destination: Group {
                DetailedServerView(serverDescriptor: server.uuid)
                    .navigationTitle(server.obtainPossibleName())
            }, label: {
                Color.lightGray
            })
            VStack {
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(server.obtainPossibleName())
                                .font(.system(size: 16, weight: .semibold, design: .default))
                            NavigationLink(destination: AssociatedTerminalView(serverDescriptor: server.uuid)) {
                                Text("ssh \(server.obtainPossibleUsername() ?? "undefined")@\(server.host) -p \(String(server.port))")
                                    .font(.system(size: 12, weight: .regular, design: .default))
                                    .background(Color.black.opacity(0.001))
                            }
                        }
                        Spacer()
                        NavigationLink(
                            destination: AddServerView(passedData: .init(modifyServer: server.uuid)),
                            isActive: $editViewShouldActive,
                            label: {
                                Image(systemName: "highlighter")
                                    .font(.system(size: 22, weight: .light, design: .rounded))
                                    .background(Color.black.opacity(0.001))
                            }
                        )
                    }
                }
                Divider()
                HStack {
                    Text(server.uuid)
                    if PTServerManager.shared.isServerSupervised(withKey: server.uuid) {
                        Image(systemName: "binoculars.fill")
                    } else {
                        Image(systemName: "bookmark.slash.fill")
                    }
                    Spacer()
                    Text(NSLocalizedString("HODE_FOR_MORE", comment: "Hold for more").uppercased())
                }
                .font(.system(size: 8, weight: .regular, design: .monospaced))
                .opacity(0.2)
            }
            .padding()
        }
        .contextMenu(ContextMenu(menuItems: {
            Section {
                Button {
                    UIPasteboard.general.string = server.obtainPossibleName()
                    let alert = UIAlertController(title: NSLocalizedString("COPIED", comment: "Copied"),
                                                  message: NSLocalizedString("COPY_NAME_ALERT", comment: "Copied server name."),
                                                  preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: NSLocalizedString("DONE", comment: "Done"),
                                                  style: .default,
                                                  handler: nil))
                    windowObserver.window?.topMostViewController?.present(alert, animated: true, completion: nil)
                } label: {
                    Image(systemName: "at.circle.fill")
                    Text(NSLocalizedString("COPY_NAME", comment: "Copy Name"))
                }
                Button {
                    UIPasteboard.general.string = "ssh \(server.obtainPossibleUsername() ?? "undefined")@\(server.host) -p \(String(server.port))"
                    let alert = UIAlertController(title: NSLocalizedString("COPIED", comment: "Copied"),
                                                  message: NSLocalizedString("COPIED_SSH_COMMAND_ALERT", comment: "Copied SSH command."),
                                                  preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: NSLocalizedString("DONE", comment: "Done"),
                                                  style: .default,
                                                  handler: nil))
                    windowObserver.window?.topMostViewController?.present(alert, animated: true, completion: nil)
                } label: {
                    Image(systemName: "greaterthan.circle.fill")
                    Text(NSLocalizedString("COPY_SSH_COMMAND", comment: "Copy SSH Command"))
                }
            }
            if !PTServerManager.shared.isServerSupervised(withKey: server.uuid) {
                Section {
                    Button {
                        PTServerManager.shared.superviseOnServer(withKey: server.uuid,
                                                                 interval: Agent.shared.supervisionInterval)
                    } label: {
                        Image(systemName: "binoculars.fill")
                        Text(NSLocalizedString("UNHIDE", comment: "Unhide"))
                    }
                }
            }
            Section {
                Button {
                    editViewShouldActive.toggle()
                } label: {
                    Image(systemName: "pencil.circle.fill")
                    Text(NSLocalizedString("EDIT", comment: "Edit"))
                }
                Button {
                    let alert = UIAlertController(title: NSLocalizedString("WARNING", comment: "Warning"),
                                                  message:
                                                  String(format: NSLocalizedString("ARE_YOU_SURE_DELETE_SERVER", comment: "Are you sure you want to delete %@?"), server.obtainPossibleName()),
                                                  preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: NSLocalizedString("CANCEL", comment: "Cancel"),
                                                  style: .cancel,
                                                  handler: nil))
                    alert.addAction(UIAlertAction(title: NSLocalizedString("CONTINUE", comment: "Continue"),
                                                  style: .destructive,
                                                  handler: { _ in
                                                      PTServerManager.shared.removeServerFromRegisteredList(withKey: server.uuid)
                                                  }))
                    windowObserver.window?.topMostViewController?.present(alert, animated: true, completion: nil)
                } label: {
                    Image(systemName: "trash.fill")
                    Text(NSLocalizedString("DELETE", comment: "Delete"))
                }
            }
        }))
        .cornerRadius(8)
        .background(
            HostingWindowFinder { [weak windowObserver] window in
                windowObserver?.window = window
            }
        )
    }
}
