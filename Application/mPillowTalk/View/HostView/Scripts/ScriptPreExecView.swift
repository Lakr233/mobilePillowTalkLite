//
//  ScriptPreExecView.swift
//  mPillowTalk
//
//  Created by Lakr Aream on 5/14/21.
//

import PTFoundation
import SwiftUI

private var lastSelection: String = ""

struct ScriptPreExecView: View {
    let clip: CodeClip?

    init(clip: CodeClip?) {
        self.clip = clip
        servers = PTServerManager.shared
            .obtainServerList()
            .sorted { "\($0.host):\(String($0.port))" < "\($1.host):\(String($1.port))" }
        var find: Int?
        if lastSelection.count > 0,
           servers.map(\.uuid).contains(lastSelection)
        {
            for (idx, obj) in servers.enumerated() {
                if obj.uuid == lastSelection {
                    find = idx
                    break
                }
            }
        }
        if let find = find {
            selection = find
        } else {
            selection = 0
        }
    }

    let servers: [PTServerManager.Server]

    @State var selection: Int
    @State var canExecute = false
    @StateObject var windowObserver = WindowObserver()

    var body: some View {
        Form {
            Section(header: Group {
                if servers.count > 0,
                   selection >= 0,
                   selection < servers.count
                {
                    Text(
                        String(format:
                            NSLocalizedString("WILL_EXECUTE_ON_SERVER_WITH_NAME", comment: "Will execute clip on server: %@"),
                            String(servers[selection].obtainPossibleName()))
                    )
                } else {
                    Text(NSLocalizedString("EXECUTE_CODE_CLIP_REQUIRE_TARGET",
                                           comment: "Execute this clip requires a target."))
                }
            }, footer: Group {
                VStack(alignment: .leading) {
                    Divider()
                        .opacity(0)
                    Divider()
                    Text(clip?.code ?? NSLocalizedString("UNKNOWN_ERROR", comment: "Unknown Error"))
                        .font(.system(size: 8, weight: .semibold, design: .monospaced))
                    Divider()
                        .opacity(0)
                }
            }) {
                if servers.count < 1 {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                        Text(NSLocalizedString("NOT_AVAILABLE", comment: "Not Available"))
                    }
                } else {
                    Picker(selection: $selection,
                           label: HStack {
                               Image(systemName: "server.rack")
                               Text(NSLocalizedString("TARGET_MACHINE", comment: "Target Machine"))
                           }) {
                        ForEach(0 ..< servers.count, id: \.self) { i in
                            Text("\(servers[i].host):\(String(servers[i].port))")
                                .font(.system(size: 14, weight: .regular, design: .monospaced))
                                .tag(i)
                        }
                    }
                    .onReceive([selection].publisher.first(), perform: { _ in debugPrint("Set default selection to \(servers[selection].obtainPossibleName())")
                        lastSelection = servers[selection].uuid
                    })
                }
            }
            Section {
                Button(action: {
                    let view = ScriptExecution(clip: clip, serverDescriptor: servers[selection].uuid)
                    let controller = UIHostingController(rootView: view)
                    (controller as UIViewController).modalPresentationStyle = .formSheet
                    (controller as UIViewController).preferredContentSize = CGSize(width: 800, height: 600)
                    windowObserver.window?.topMostViewController?.present(controller, animated: true, completion: {})
                }, label: {
                    HStack {
                        Image(systemName: "paperplane.fill")
                        Text(NSLocalizedString("EXECUTE", comment: "Execute"))
                    }
                    .foregroundColor(.overridableAccentColor)
                })
                    .disabled(servers.count < 1)
            }
            .background(
                HostingWindowFinder { [weak windowObserver] window in
                    windowObserver?.window = window
                }
            )
        }
        .navigationTitle(NSLocalizedString("SELECT_TARGET", comment: "Select Target"))
    }
}

struct ScriptPreExecView_Previews: PreviewProvider {
    static var previews: some View {
        ScriptPreExecView(clip: nil)
            .previewLayout(.fixed(width: 600, height: 1000))
    }
}
