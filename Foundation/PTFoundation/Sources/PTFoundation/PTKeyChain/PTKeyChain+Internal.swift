//
//  PTKeyChain+Internal.swift
//  PTFoundation
//
//  Created by Lakr Aream on 12/15/20.
//

import CommonCrypto
import Foundation

/*
 public struct AccessObject {
     let identity: String
     let plainLabel: String
     let account: String
     let key: String
     let representedObject: Data?
 }
 internal struct AccessObjectEncrypted {
     let plainIdentity: String
     let plainLabel: String
     let account: String
     let key: String
     let representedObject: String?
 }
 */

private let LabelKey: String = "LABEL:" // "AccessObjectEncrypted.plainLabel"
private let AccountKey: String = "ACCOUNT:" // "AccessObjectEncrypted.account"
private let KeyKey: String = "KEY:" // "AccessObjectEncrypted.key"
private let PayloadKey: String = "PAYLOAD:" // "AccessObjectEncrypted.storeObject" or representedObject

extension PTKeyChain {
    /// 初始化钥匙串 上执行锁
    /// - Parameters:
    ///   - toDir: 储存位置
    ///   - masterKey: 应用程序通用密钥
    /// - Returns: 错误 如果存在
    func initialization(toDir: URL, masterKey: String) -> PTFoundation.InitializationError? {
        // 处理存档
        if PTFoundation.ensureDirExists(atLocation: toDir) != nil {
            return .filePermissionDenied
        }

        // 合成文件路径
        baseLocation = toDir.appendingPathComponent(PTKeyChain.StoreBase)
        if PTFoundation.ensureDirExists(atLocation: baseLocation) != nil {
            return .filePermissionDenied
        }

        // 启动加密引擎
        guard let aes = AES(key: masterKey, iv: "-[NSFileManager fileExistsAtPath:]") else {
            PTLog.shared.join(self,
                              "failed to retrieve user candidate",
                              level: .critical)
            return .keychainInitializationFailed
        }
        masterCryptoEngine = aes
        PTLog.shared.join(self,
                          "initialized master crypto",
                          level: .info)

        // 测试数据是否有效
        if let error = decryptInitialCase() {
            return error
        }

        // 完成初始化
        PTLog.shared.join(self,
                          "Setup reported store location: \(baseLocation.path)",
                          level: .info)

        let count = reloadKeyIdentities().count
        if count > 0 {
            PTLog.shared.join(self,
                              "initialization process reported \(count) loaded key(s)",
                              level: .info)
        }

        return nil // 无错误
    }

    /// 加密数据 在储存的时候使用
    /// - Parameter object: 访问对象
    /// - Returns: 加密对象
    func encryptAccessObject(with object: AccessObject) -> AccessObjectEncrypted? {
        guard let account = masterCryptoEngine?.encrypt(string: object.account) else {
            PTLog.shared.join(self, "failed to compile encrypted data", level: .warning)
            return nil
        }
        guard let key = masterCryptoEngine?.encrypt(string: object.key) else {
            PTLog.shared.join(self, "failed to compile encrypted data", level: .warning)
            return nil
        }
        if let attach = object.representedObject {
            // 如果存在representedObject数据 则储存加密以后的base64数据
            guard let payload = masterCryptoEngine?.encrypt(data: attach) else {
                return nil
            }
            let encrypted = AccessObjectEncrypted(plainIdentity: object.identity, plainLabel: object.plainLabel, account: account, key: key, representedObject: payload)
            return encrypted
        } else {
            let encrypted = AccessObjectEncrypted(plainIdentity: object.identity, plainLabel: object.plainLabel, account: account, key: key, representedObject: nil)
            return encrypted
        }
    }

    /// 解密数据
    /// - Parameter object: 加密的访问对象
    /// - Returns: 解密后的访问对象
    func decryptAccessObject(with object: AccessObjectEncrypted) -> AccessObject? {
        guard let account = masterCryptoEngine?.decryptString(base64: object.account) else {
            return nil
        }
        guard let key = masterCryptoEngine?.decryptString(base64: object.key) else {
            return nil
        }
        if let attach = object.representedObject {
            // 如果存在representedObject数据 则解密数据
            guard let payload = masterCryptoEngine?.decrypt(base64: attach) else {
                return nil
            }
            let decrypted = AccessObject(identity: object.plainIdentity, plainLabel: object.plainLabel, account: account, key: key, representedObject: payload)
            return decrypted
        } else {
            let decrypted = AccessObject(identity: object.plainIdentity, plainLabel: object.plainLabel, account: account, key: key, representedObject: nil)
            return decrypted
        }
    }

    /// 从文件中获取数据 这个数据应该加密储存在内存中
    /// - Parameters:
    ///   - data: 文件数据
    ///   - identity: 识别码
    /// - Returns: 加密的访问对象
    func retrieveEncryptedObjectFromFile(withData data: Data, andIdentity identity: String) -> AccessObjectEncrypted? {
        // [[原文->data]->密文数据->base64EncodedData()]
        guard let str = masterCryptoEngine?.decryptString(base64: data) else {
            return nil
        }
        // 开始解析
        var begin = false
        var end = false
        var account: String?
        var plainLabel: String?
        var key: String?
        var storeObject: String?
        invoke: for item in str.components(separatedBy: "\n") {
            if item == "-----BEGIN PILLOW TALK KEY-----" {
                if begin { return nil }
                begin = true
                continue invoke
            }
            if item == "------END PILLOW TALK KEY------" {
                if !begin { return nil }
                end = true
                break invoke
            }
            // 分栏处理 用报头识别
            if item.hasPrefix(LabelKey) {
                plainLabel = String(item.dropFirst(LabelKey.count))
                continue invoke
            }
            if item.hasPrefix(AccountKey) {
                account = String(item.dropFirst(AccountKey.count))
                continue invoke
            }
            if item.hasPrefix(KeyKey) {
                key = String(item.dropFirst(KeyKey.count))
                continue invoke
            }
            if item.hasPrefix(PayloadKey) {
                storeObject = String(item.dropFirst(PayloadKey.count))
                continue invoke
            }
            if item.count < 1 { continue }
            // 没有搜索到文件结尾
            return nil
        }
        // 检查数据合法
        if !begin || !end { return nil }
        if account == nil || key == nil || plainLabel == nil { return nil }
        // 构建
        return AccessObjectEncrypted(plainIdentity: identity,
                                     plainLabel: plainLabel!,
                                     account: account!,
                                     key: key!,
                                     representedObject: storeObject)
    }

    /// 构建储存数据
    /// - Parameter object: 加密的对象
    /// - Returns: 字符串数据
    func constructObjectStoreFile(withObject object: AccessObjectEncrypted) -> Data? {
        /*
         Characters of the Base64 alphabet can be grouped into four groups:
            Uppercase letters (indices 0-25): ABCDEFGHIJKLMNOPQRSTUVWXYZ.
            Lowercase letters (indices 26-51): abcdefghijklmnopqrstuvwxyz.
            Digits (indices 52-61): 0123456789.
            Special symbols (indices 62-63): +/
         */
        var result = ""
        result += "-----BEGIN PILLOW TALK KEY-----\n"
        result += LabelKey + object.plainLabel + "\n"
        result += AccountKey + object.account + "\n"
        result += KeyKey + object.key + "\n"
        if let str = object.representedObject {
            result += PayloadKey + str + "\n"
        }
        result += "------END PILLOW TALK KEY------\n"
        // [[原文->data]->密文数据->base64EncodedData()]
        return masterCryptoEngine?.encrypt(string: result)?.data(using: .utf8)
    }

    /// 添加账户
    /// - Parameter object: 访问对象
    /// - Returns: 句柄
    func addAccountAndReturnIdentity(withObject object: AccessObject) -> String? {
        // 如果已经存在 中奖了 取消添加 因为uuid的生成并不暴露给接口
        let key = object.identity
        accessLock.lock()
        let temp = keyIdentities
        accessLock.unlock()
        if temp.contains(key) {
            PTLog.shared.join(self, "Are you ok?", level: .error)
            return nil
        }
        executionLock.lock()
        let file = baseLocation
            .appendingPathComponent(key)
            .appendingPathExtension(PTKeyChain.fileSuffix)
        guard let encrypted = encryptAccessObject(with: object) else {
            // 加密失败
            executionLock.unlock()
            return nil
        }
        let fileUrl = URL(fileURLWithPath: file.path, isDirectory: false)
        let data = constructObjectStoreFile(withObject: encrypted)
        do {
            try data?.write(to: fileUrl)
        } catch {
            executionLock.unlock()
            PTLog.shared.join(self,
                              "failed to write key file",
                              level: .error)
            return nil
        }
        executionLock.unlock()
        // 同步写入数据
        accessLock.lock()
        keyIdentities.insert(key)
        keyContainer[key] = encrypted
        accessLock.unlock()
        // 汇报
        PTLog.shared.join(self,
                          "added account by id: \(key)",
                          level: .info)
        return key
    }

    /// 测试初始化密钥是否合法
    /// - Returns: 初始化错误
    func decryptInitialCase() -> PTFoundation.InitializationError? {
        let id = "A9DE1A1E-BD33-423A-B416-7EE57D8F0266"
        let testFile = baseLocation.appendingPathComponent(".masterCrypto.tptk")
        // 如果文件存在则需要进行测试 否则需要创建测试密钥
        if FileManager.default.fileExists(atPath: testFile.path) {
            // 文件存在
            if let data = try? Data(contentsOf: testFile) {
                if let newID = masterCryptoEngine?.decryptString(base64: data) {
                    if id == newID {
                        // 成了
                        return nil
                    } else {
                        // 解密错误
                        return .keychainInitializationFailed
                    }
                } else {
                    // 解密失败
                    return .keychainInitializationFailed
                }
            } else {
                // 无法读取
                return .filePermissionDenied
            }
        } else {
            // 写入测试用例
            if let str = masterCryptoEngine?.encrypt(string: id) {
                do {
                    try str.write(toFile: testFile.path, atomically: true, encoding: .utf8)
                } catch {
                    // 写入失败
                    return .filePermissionDenied
                }
            } else {
                // 引擎丢了
                return .keychainInitializationFailed
            }
        }
        return nil
    }
}
