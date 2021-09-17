//
//  PersistTerminalInstance.swift
//  mPillowTalk
//
//  Created by Lakr Aream on 5/30/21.
//

import NMSSH
import PTFoundation
import SwiftTerm
import SwiftUI

class PersistTerminalInstance: NSObject, Identifiable, TerminalViewDelegate, NMSSHChannelDelegate {
    
    let id = UUID()

    public var terminalTitle = ""
    public private(set) var terminalBuffer = ""
    public private(set) var openDate = Date()

    private var lock = NSLock()
    private var lastTerminalView: TerminalViewWrapper?
    private var ptySizeCache = CGSize()
    private var session: NMSSHSession?
    private var queue: DispatchQueue?

    // MARK: INITIAL

    func setSession(session: NMSSHSession) {
        if self.session != nil {
            #if DEBUG
                fatalError("sesson already exists")
            #else
                return
            #endif
        }
        self.session = session
    }

    func setQueue(queue: DispatchQueue) {
        if self.queue != nil {
            #if DEBUG
                fatalError("queue already exists")
            #else
                return
            #endif
        }
        self.queue = queue
    }

    func requestTerminalWrapperView() -> TerminalViewWrapper {
        lastTerminalView?.terminalView.terminalDelegate = nil
        lastTerminalView?.terminalView.removeFromSuperview()
        lastTerminalView = nil
        let lock = lock
        lock.lock()
        let view = TerminalViewWrapper()
        view.terminalView.terminalDelegate = self
        let buffer = terminalBuffer
        lastTerminalView = view
//        lock.unlock()
        // after size to be determined // not working...
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//            lock.lock()
        view.feed(text: buffer)
        lock.unlock()
//        }
        return view
    }

    func updatePtySizeIfNeeded() {
        if let terminal = lastTerminalView?.terminalView.getTerminal() {
            let cols = terminal.cols
            let rows = terminal.rows
            let now = CGSize(width: cols, height: rows)
            if now == ptySizeCache { return }
            ptySizeCache = now
            debugPrint("updating pty size for terminal: \(now)")
            queue?.async { [weak self] in
                self?.session?.channel.requestSizeWidth(UInt(cols), height: UInt(rows))
            }
        }
    }

    static func openConnection(withServer sd: PTServerManager.ServerDescriptor,
                               onComplete: @escaping (PersistTerminalInstance?) -> Void)
    {
        DispatchQueue.global().async {
            if Agent.shared.applicationProtectedScriptExecution {
                let authResult = Agent.shared.authenticationWithBioIDSyncAndReturnIsSuccessOrError()
                if !authResult.0 {
                    if let error = authResult.1 {
                        PTLog.shared.join("App",
                                          "failed to authenticate device ownership with system when requesting shell connection \(error)",
                                          level: .error)
                    } else {
                        PTLog.shared.join("App",
                                          "failed to authenticate device ownership with system when requesting shell connection",
                                          level: .error)
                    }
                    onComplete(nil)
                    return
                }
            }

            let instance = PersistTerminalInstance()
            guard let server = PTServerManager.shared.obtainServer(withKey: sd),
                  let shell = PTServerManager.shared.openShellConnection(onServer: server.uuid,
                                                                         withEnvironment: [:],
                                                                         withDelegate: instance)
                  as? PTServerSSHLinuxSelectors.PTSSHConnection
            else {
                PTLog.shared.join("SSH",
                                  "failed to case connection",
                                  level: .error)
                onComplete(nil)
                return
            }
            instance.setSession(session: shell.representedConnection)
            instance.setQueue(queue: shell.springLoadedQueue)
            instance.openDate = Date()
            instance.terminalTitle = server.obtainPossibleName()
            Agent.shared.createTerminal(withInstance: instance)
            onComplete(instance)
        }
    }

    static func openConnection(withHost _: String,
                               withPort _: UInt32,
                               withUsername _: String,
                               withPassword _: String)
    {
        fatalError("didnt impled")
    }

    static func openConnection(withHost _: String,
                               withPort _: UInt32,
                               withUsername _: String,
                               withPublicKey _: String,
                               withPrivateKey _: String,
                               withPassword _: String)
    {
        fatalError("didnt impled")
    }

    // MARK: SWIFTTERM

    func sizeChanged(source _: TerminalView, newCols: Int, newRows: Int) {
        queue?.async {
            self.session?.channel.requestSizeWidth(UInt(newCols), height: UInt(newRows))
        }
    }

    func setTerminalTitle(source _: TerminalView, title _: String) {}

    func hostCurrentDirectoryUpdate(source _: TerminalView, directory _: String?) {}

    func send(source _: TerminalView, data: ArraySlice<UInt8>) {
        queue?.async {
            try? self.session?.channel.write(Data(data))
        }
    }
    
    func requestOpenLink(source: TerminalView, link: String, params: [String : String]) {
        // TODO: MAKE IT WORK
    }

    func scrolled(source _: TerminalView, position _: Double) {}

    func feed(text: String) {
        DispatchQueue.main.async { [weak self] in
            self?.lock.lock()
            if let terminal = self?.lastTerminalView?.terminalView {
                #if DEBUG
                    debugPrint(text)
                #endif
                terminal.feed(text: text)
            }
            self?.terminalBuffer.append(text)
            self?.lock.unlock()
        }
    }
    

    // MARK: NMSSH

    @objc
    func channel(_: NMSSHChannel, didReadData message: String) {
        feed(text: message)
    }

    @objc
    func channel(_: NMSSHChannel, didReadError error: String) {
        PTLog.shared.join("SSH",
                          "read error raised from persist connection: \(error)",
                          level: .error)
    }

    @objc
    func channelShellDidClose(_: NMSSHChannel) {
        feed(text: "\r\n[*] Connection closed\r\n")
    }

    func terminate() {
        queue?.async {
            self.session?.channel.closeShell()
        }
        Agent.shared.removeTerminal(withInstance: self)
    }
}
