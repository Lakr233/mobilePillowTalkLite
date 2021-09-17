//
//  PersistTerminalView.swift
//  mPillowTalk
//
//  Created by Lakr Aream on 5/30/21.
//

import SwiftUI

struct PersistTerminalView: View {
    let instance: PersistTerminalInstance

    @StateObject var windowObserver = WindowObserver()
    @Environment(\.presentationMode) var presentationMode

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    @State var terminalWrapper: TerminalViewWrapper? = nil

    var body: some View {
        Group {
            if terminalWrapper == nil {
                ProgressView()
                    .onAppear {
                        terminalWrapper = instance.requestTerminalWrapperView()
                    }
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
        .onReceive(timer, perform: { _ in
            instance.updatePtySizeIfNeeded()
            if terminalWrapper?.terminalView.window == nil {
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
                instance.terminate()
                dismiss()
            } label: {
                Text(NSLocalizedString("TERMINATE", comment: "Terminate"))
            }
        })
    }

    func dismiss() {
        DispatchQueue.main.async {
            windowObserver.window?.topMostViewController?.dismiss(animated: true, completion: nil)
            presentationMode.wrappedValue.dismiss()
        }
    }
}
