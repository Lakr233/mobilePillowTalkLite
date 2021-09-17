//
//  ScriptExecution.swift
//  mPillowTalk
//
//  Created by Lakr Aream on 5/14/21.
//

import PTFoundation
import SwiftTerm
import SwiftUI

struct ScriptExecution: View {
    init(clip: CodeClip?, serverDescriptor: String?) {
        self.clip = clip
        server = PTServerManager.shared.obtainServer(withKey: serverDescriptor ?? "")
    }

    @StateObject var windowObserver = WindowObserver()

    @State var dispatched: Bool = false

    let clip: CodeClip?
    let server: PTServerManager.Server?

    let terminal = TerminalViewWrapper()

    @State var textContent: String = ""
    @State var shouldTerminate: Bool = false
    @State var executionCompleted: Bool = false

    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                if server == nil || clip == nil {
                    Text(NSLocalizedString("UNKNOWN_ERROR", comment: "Unknown Error"))
                        .font(.system(size: 10, weight: .semibold, design: .default))
                        .multilineTextAlignment(.leading)
                } else {
                    GeometryReader { reader in
                        terminal
                            .frame(width: reader.size.width, height: reader.size.height)
                            .disabled(true)
                    }
                    .onAppear {
                        if dispatched { return }
                        dispatched = true
                        PTLog.shared.join("ScriptExecution",
                                          "execution started \(clip!.section) \(clip!.name) at \(server!.uuid) (\(server!.obtainPossibleName()))",
                                          level: .info)
                        terminal.feed(text: "Executing \(clip!.name) on \(server!.obtainPossibleName())\r\n")
                        DispatchQueue.global().async {
                            if Agent.shared.applicationProtectedScriptExecution {
                                terminal.feed(text: "\r\n[*] Authenticating device ownership with system...\r\n")
                                let authResult = Agent.shared.authenticationWithBioIDSyncAndReturnIsSuccessOrError()
                                if !authResult.0 {
                                    if let error = authResult.1 {
                                        terminal.feed(text: "[E] Authentication failed: \(error)\r\n")
                                    } else {
                                        terminal.feed(text: "[E] Authentication failed with unknown reason\r\n")
                                    }
                                    executionCompleted = true
                                    return
                                }
                                terminal.feed(text: "[*] Authentication success!\r\n")
                            }
//                            TODO:
//                            terminal.terminalView.getTerminal().getDims()
                            clip?.execAsync(fromEnvironment: ExecuteEnvironment(payload: [:], server: server?.uuid),
                                            queue: .global(),
                                            output: { str in
                                                terminal.feed(text: str)
                                            }, terminate: {
                                                shouldTerminate
                                            }, onComplete: { recipe in
                                                executionCompleted = true
                                                PTLog.shared.join("ScriptExecution",
                                                                  "execution completed \(clip!.section) \(clip!.name) at \(server!.uuid) (\(server!.obtainPossibleName()))",
                                                                  level: .info)

                                                terminal.feed(text: "\r\n\r\n------\r\n")
                                                terminal.feed(text: "Program exits with code: \(recipe.code)\r\n")
                                                if let errStr = recipe.error {
                                                    terminal.feed(text: "Error occurred during execution: \(errStr)\r\n")
                                                }
                                                var get = recipe.vars
                                                get.removeValue(forKey: "ExecExitCode")
                                                for key in get.keys where key.hasPrefix("PILLOWTALK") {
                                                    get.removeValue(forKey: key)
                                                }
                                                if get.count > 0 {
                                                    terminal.feed(text: "\r\nReturned Variable(s):\r\n\n")
                                                    for item in get {
                                                        terminal.feed(text: " > \(item.key): \(item.value)\r\n")
                                                    }
                                                }
                                                DispatchQueue.main.async {
                                                    windowObserver.window?.topMostViewController?.isModalInPresentation = false
                                                }
                                            })
                        }
                    }
                }
            }
            .background(
                HostingWindowFinder { [weak windowObserver] window in
                    windowObserver?.window = window
                    windowObserver?.window?.topMostViewController?.isModalInPresentation = true
                }
            )
            .padding()
            .navigationTitle(NSLocalizedString("EXECUTION", comment: "Execution"))
            .navigationViewStyle(StackNavigationViewStyle())
            .navigationBarItems(leading:
                Button(action: {
                    let alert = UIAlertController(title: NSLocalizedString("WARNING", comment: "Warning"),
                                                  message: NSLocalizedString("TERMINATE_EXECUTION_WARNING", comment: "Early exit may result in unknown errors."),
                                                  preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: NSLocalizedString("CANCEL", comment: "Cancel"),
                                                  style: .cancel, handler: nil))
                    alert.addAction(UIAlertAction(title: NSLocalizedString("CONFIRM", comment: "Confirm"),
                                                  style: .destructive, handler: { _ in
                                                      shouldTerminate = true
                                                      windowObserver.window?.topMostViewController?.isModalInPresentation = false
                                                  }))
                    windowObserver.window?.topMostViewController?.present(alert, animated: true, completion: nil)
                }, label: {
                    Text(NSLocalizedString("TERMINATE", comment: "Terminate"))
                })
                    .disabled(executionCompleted),
                trailing:
                Button(action: {
                    windowObserver.window?.topMostViewController?.dismiss(animated: true, completion: nil)
                }, label: {
                    Text(NSLocalizedString("CLOSE", comment: "Close"))
                })
                    .disabled(!executionCompleted))
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct ScriptExecution_Previews: PreviewProvider {
    static var previews: some View {
        ScriptExecution(clip: nil, serverDescriptor: nil)
    }
}
