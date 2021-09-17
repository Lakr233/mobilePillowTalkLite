//
//  PTTransfer.swift
//  PTFoundation
//
//  Created by Lakr Aream on 4/20/21.
//

import Foundation

/// Transfer 用于在设备之间转移数据
public final class PTTransfer {
    /// 单例
    public static let shared = PTTransfer()
    public static let suggestedHttpPort: UInt = 5343
    private init() {}

    /// 返回给 UI 进行处理
    public struct TransferPackage {
        public let pin: String
        public let base64: String

        fileprivate static let iv = "4E9A7CAC-6F6F-40DD-90D9-A7712431821C"

        /// 初始化转交数据
        /// - Parameter origData: 原始数据
        fileprivate init?(origData: Data) {
            let p = Int.random(in: 1000 ... 9999)
            let aesKey = "\(p)-\(p)-\(p)-\(p)-wiki.qaq.PillowTalk.Transfer"
            guard let aes = AES(key: aesKey, iv: TransferPackage.iv) else {
                PTLog.shared.join(TransferPackage.self,
                                  "crypto engine broken",
                                  level: .error)
                return nil
            }
            guard let enc = aes.encrypt(data: origData) else {
                PTLog.shared.join(TransferPackage.self,
                                  "crypto engine failed to encrypt transfer package",
                                  level: .error)
                return nil
            }

            pin = String(p)
            base64 = TransferPackage.base64URLEscaped(str: enc)
        }

        /// 获取原始数据
        /// - Returns: 原始数据
        fileprivate static func obtainOrigData(base64: String, pin: String) -> Data? {
            let p = pin
            let aesKey = "\(p)-\(p)-\(p)-\(p)-wiki.qaq.PillowTalk.Transfer"
            guard let aes = AES(key: aesKey, iv: TransferPackage.iv) else {
                PTLog.shared.join(TransferPackage.self,
                                  "crypto engine broken",
                                  level: .error)
                return nil
            }
            let realbase64 = TransferPackage.base64URLUnescaped(str: base64)
            guard let dec = aes.decrypt(base64: realbase64) else {
                PTLog.shared.join(TransferPackage.self,
                                  "crypto engine failed to decrypt transfer package",
                                  level: .error)
                return nil
            }
            return dec
        }

        /// base64-url -> base64
        /// - Parameter str: 字符串
        /// - Returns: 字符串
        fileprivate static func base64URLUnescaped(str: String) -> String {
            let replaced = str.replacingOccurrences(of: "-", with: "+")
                .replacingOccurrences(of: "_", with: "/")
            let padding = replaced.count % 4
            if padding > 0 {
                return replaced + String(repeating: "=", count: 4 - padding)
            } else {
                return replaced
            }
        }

        /// base64 -> base64-url
        /// - Parameter str: 字符串
        /// - Returns: 字符串
        fileprivate static func base64URLEscaped(str: String) -> String {
            str.replacingOccurrences(of: "+", with: "-")
                .replacingOccurrences(of: "/", with: "_")
                .replacingOccurrences(of: "=", with: "")
        }
    }

    /// 服务器传输对象 密钥不加密
    private struct ServerAccount: Codable {
        let account: PTAccountManager.AccountStore
        let key: PTKeyChain.AccessObject
    }

    /// 传输抓手+组合拳
    private struct PairPayload: Codable {
        let servers: [PTServerManager.Server: ServerAccount]
        let codeclip: [CodeClip]
        let codegroup: [CodeClipGroup]
        let checkpoint: [Checkpoint]

        // MARK: CODER

        public func encodeToData() -> Data? {
            try? PTFoundation.plistEncoder.encode(self)
        }

        public static func decodeFromData(data: Data) -> Self? {
            try? PTFoundation.plistDecoder.decode(Self.self, from: data)
        }
    }

    /// 获取传输的数据
    /// - Returns: 未加密数据
    public func obtainTransferData() -> TransferPackage? {
        let servers = PTServerManager.shared.obtainServerList()
        var push = [PTServerManager.Server: ServerAccount]()
        for each in servers {
            guard let account = PTAccountManager.shared.retrieveAccountWith(key: each.accountDescriptor) else {
                PTLog.shared.join(self,
                                  "ignoring broken resource found on server: \(each.uuid)",
                                  level: .error)
                continue
            }
            guard let key = PTKeyChain.shared.retrieveAccount(byKey: account.uuid) else {
                PTLog.shared.join(self,
                                  "ignoring broken resource found on server: \(each.uuid)",
                                  level: .error)
                continue
            }
            let sa = ServerAccount(account: account.obtainAccountStoreObject(), key: key)
            push[each] = sa
        }
        var clips = [CodeClip]()
        PTCodeClipManager.shared.obtainCodeClipList().forEach { _, collections in
            collections.forEach { _, clip in
                clips.append(clip)
            }
        }
        var groups = [CodeClipGroup]()
        PTCodeClipManager.shared.obtainCodeClipGroupList().forEach { _, collections in
            collections.forEach { _, group in
                groups.append(group)
            }
        }
        var checkpoint = [Checkpoint]()
        PTCheckpointManager.shared.obtainCheckpointList().forEach { _, collections in
            collections.forEach { _, val in
                checkpoint.append(val)
            }
        }
        guard let data = PairPayload(servers: push,
                                     codeclip: clips,
                                     codegroup: groups,
                                     checkpoint: checkpoint).encodeToData()
        else {
            PTLog.shared.join(self,
                              "broken resource found when compelling transfer data",
                              level: .error)
            return nil
        }

        return TransferPackage(origData: data)
    }

    public typealias Valid = Bool
    /// 尝试解密数据
    /// - Parameters:
    /// - Parameter base64: 加密后的转交数据
    /// - Parameter pin: 密钥
    /// - Returns: 是否有效
    public func testDecryption(base64: String, pin: String) -> Valid {
        guard let data = TransferPackage.obtainOrigData(base64: base64, pin: pin) else {
            PTLog.shared.join(self,
                              "invalid transfer package or invalid key",
                              level: .error)
            return false
        }
        guard let pairPayload = PairPayload.decodeFromData(data: data) else {
            PTLog.shared.join(self,
                              "failed to decode transfer package",
                              level: .error)
            return false
        }
        if pairPayload.servers.count < 1
            && pairPayload.codeclip.count < 1
            && pairPayload.codegroup.count < 1
            && pairPayload.checkpoint.count < 1
        {
            PTLog.shared.join(self,
                              "decoded transfer package returns nothing, canceling import",
                              level: .error)
            return false
        }
        return true
    }

    /// 应用转交数据 请在 UI 层面拦截其他接口调用 线程不安全
    /// - Parameter base64: 加密后的转交数据
    /// - Parameter pin: 密钥
    /// - Parameter fromMainThread: 切换到主线程操作
    public func applyTransferPackage(base64: String, pin: String, fromMainThread: Bool) {
        guard let data = TransferPackage.obtainOrigData(base64: base64, pin: pin) else {
            PTLog.shared.join(self,
                              "invalid transfer package or invalid key",
                              level: .error)
            return
        }
        guard let pairPayload = PairPayload.decodeFromData(data: data) else {
            PTLog.shared.join(self,
                              "failed to decode transfer package",
                              level: .error)
            return
        }
        if pairPayload.servers.count < 1
            && pairPayload.codeclip.count < 1
            && pairPayload.codegroup.count < 1
            && pairPayload.checkpoint.count < 1
        {
            PTLog.shared.join(self,
                              "decoded transfer package returns nothing, canceling import",
                              level: .error)
            return
        }

        let queue = fromMainThread ? DispatchQueue.main : DispatchQueue.global()
        let sem = DispatchSemaphore(value: 0)
        queue.async {
            PTLog.shared.join(self,
                              "starting configuration overwrite",
                              level: .info)
            for server in PTServerManager.shared.obtainServerList() {
                PTServerManager.shared.removeServerFromRegisteredList(withKey: server.uuid)
                PTAccountManager.shared.removeAccount(withKey: server.accountDescriptor)
            }
            for handler in PTAccountManager.shared.obtainAccountKeyList() {
                PTAccountManager.shared.removeAccount(withKey: handler)
            }
            PTKeyChain.shared.keyContainer = [:]
            PTKeyChain.shared.keyIdentities = []
            PTAccountManager.shared.accounts = [:]
            PTAccountManager.shared.synchronizeObjects()
            PTServerManager.shared.serverContainer = [:]
            PTServerManager.shared.synchronizeObjects()
            PTCodeClipManager.shared.clipContainer = [:]
            PTCodeClipManager.shared.groupContainer = [:]
            PTCodeClipManager.shared.synchronizeObjects()
            PTLog.shared.join(self,
                              "waiting for configuration sync",
                              level: .info)
            usleep(1_500_000)
            PTLog.shared.join(self,
                              "importing servers",
                              level: .info)
            for (server, accountObject) in pairPayload.servers {
                guard let account = accountObject.account.retrieveAccountObject() else {
                    PTLog.shared.join(self,
                                      "broken account found used by server \(server.uuid)",
                                      level: .error)
                    continue
                }
                let key = accountObject.key
                guard let _ = PTKeyChain.shared.addAccountAndReturnIdentity(withObject: key) else {
                    PTLog.shared.join(self,
                                      "broken key found used by server \(server.uuid)",
                                      level: .error)
                    continue
                }
                PTAccountManager.shared.accounts[account.uuid] = account
                PTServerManager.shared.createServer(withObject: server) { _, info -> (PTServerManager.RegistrationSolution) in
                    PTLog.shared.join(self,
                                      "server manager raised an registration interrupt, force continue \(info ?? "[Unknown Info]")",
                                      level: .warning)
                    return .continueRegistration
                }
            }
            PTAccountManager.shared.synchronizeObjects()
            for clip in pairPayload.codeclip {
                PTCodeClipManager.shared.addCodeClip(code: clip)
            }
            for group in pairPayload.codegroup {
                PTCodeClipManager.shared.addCodeClipGroup(codeGroup: group)
            }
            for checkpoint in pairPayload.checkpoint {
                PTCheckpointManager.shared.addCheckpoint(code: checkpoint)
            }
            PTLog.shared.join(self,
                              "waiting for configuration sync",
                              level: .info)
            sleep(2)
            sem.signal()
        }
        sem.wait()
        PTLog.shared.join(self,
                          "configuration overwrite completed")
    }
}
