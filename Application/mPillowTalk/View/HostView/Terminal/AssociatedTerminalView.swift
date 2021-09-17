//
//  AssociatedTerminalView.swift
//  mPillowTalk
//
//  Created by Lakr Aream on 5/17/21.
//

import NMSSH
import PTFoundation
import SwiftTerm
import SwiftUI

struct AssociatedTerminalView: View {
    let serverDescriptor: PTServerManager.ServerDescriptor

    @State var openingConnection: Bool = false
    @State var instanceRef: PersistTerminalInstance? = nil
    @State var terminalWrapper: TerminalViewWrapper?
    @State var opened: Bool = false

    @StateObject var windowObserver = WindowObserver()
    @Environment(\.presentationMode) var presentationMode

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(serverDescriptor: PTServerManager.ServerDescriptor) {
        self.serverDescriptor = serverDescriptor
    }

    var body: some View {
        ZStack {
            if instanceRef == nil {
                if openingConnection {
                    ProgressView()
                } else {
                    Button(action: {
                        connect()
                    }, label: {
                        Text(NSLocalizedString("CONNECT", comment: "Connect"))
                    })
                }
            } else {
                if terminalWrapper == nil {
                    ProgressView()
                } else {
                    GeometryReader { reader in
                        terminalWrapper!
                            .padding(reader.size.width > 500 ? 15 : 0)
                            .onTapGesture {
                                if terminalWrapper!.terminalView.isFirstResponder {
                                    _ = terminalWrapper?.terminalView.resignFirstResponder()
                                } else {
                                    terminalWrapper?.terminalView.becomeFirstResponder()
                                }
                            }

                            .onAppear {
                                terminalWrapper?.terminalView.becomeFirstResponder()
                            }
                    }
                }
            }
        }
        .onAppear {
            connect()
        }
        .onReceive(timer, perform: { _ in
            instanceRef?.updatePtySizeIfNeeded()
            if instanceRef != nil, terminalWrapper?.terminalView.window == nil {
                self.dismiss()
            }
        })
        .background(
            HostingWindowFinder { [weak windowObserver] window in
                windowObserver?.window = window
            }
        )
        .navigationTitle(NSLocalizedString("SHELL", comment: "Shell"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing: Group {
            Button {
                instanceRef?.terminate()
                dismiss()
            } label: {
                Text(NSLocalizedString("TERMINATE", comment: "Terminate"))
            }
        })
    }

    func connect() {
        if opened { return }
        opened = true
        openingConnection = true
        DispatchQueue.global().async {
            PersistTerminalInstance.openConnection(withServer: serverDescriptor) { instance in
                DispatchQueue.main.async {
                    self.instanceRef = instance
                    self.terminalWrapper = instance?.requestTerminalWrapperView()
                    openingConnection = false
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
            }
        }
    }

    func dismiss() {
        DispatchQueue.main.async {
            windowObserver.window?.topMostViewController?.dismiss(animated: true, completion: nil)
            presentationMode.wrappedValue.dismiss()
        }
    }
}

struct AssociatedTerminalView_Previews: PreviewProvider {
    static var previews: some View {
        AssociatedTerminalView(serverDescriptor: "")
    }
}
