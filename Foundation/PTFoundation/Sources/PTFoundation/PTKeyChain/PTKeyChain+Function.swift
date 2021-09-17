//
//  PTKeyChain+Function.swift
//  PTFoundation
//
//  Created by Lakr Aream on 12/15/20.
//

import Foundation

extension PTKeyChain {
    /// 重新加载钥匙串并刷新缓存 上执行锁和读写锁
    /// - Returns: 钥匙串id数组
    @discardableResult
    func reloadKeyIdentities() -> Set<String> {
        executionLock.lock()
        // 初始化临时储存
        var buildKeyNames: Set<String> = []
        var buildCache = [String: AccessObjectEncrypted]()
        // 读取文件名
        let subitems = try? FileManager.default.contentsOfDirectory(atPath: baseLocation.path)
        subitems?.forEach { item in
            // 检查文件名是否有效
            if !(item.hasSuffix(PTKeyChain.fileSuffix)
                && item.count > PTKeyChain.fileSuffix.count + 1)
            {
                return
            }
            // 如果文件以 . 开头有可能是属性文件或者是测试密钥 总之跳过 .masterCrypto.tptk
            if item.hasPrefix(".") { return }
            // 获取数据
            let path = baseLocation.appendingPathComponent(item)
            guard let data = try? Data(contentsOf: path) else {
                PTLog.shared.join(self,
                                  "failed to read file at \(path), ignoring",
                                  level: .warning)
                try? FileManager.default.removeItem(at: path)
                return
            }
            // 初始化密钥对象
            var kIdentity = String(item.dropLast(PTKeyChain.fileSuffix.count))
            while kIdentity.hasSuffix(".") {
                kIdentity.removeLast()
            }
            guard let object = retrieveEncryptedObjectFromFile(withData: data, andIdentity: kIdentity) else {
                PTLog.shared.join(self,
                                  "failed to compile key object with data at \(path), removing it",
                                  level: .error)
                try? FileManager.default.removeItem(at: path)
                return
            }
            // 添加到构建对象中
            buildKeyNames.insert(kIdentity)
            buildCache[kIdentity] = object
        }
        executionLock.unlock()
        // 一次只用一把锁
        accessLock.lock()
        keyIdentities = buildKeyNames
        keyContainer = buildCache
        accessLock.unlock()
        // 返回构建的密钥id表
        return buildKeyNames
    }

    /// 添加钥匙串对象并储存
    /// - Parameters:
    ///   - account: 账号
    ///   - key: 密码
    ///   - data: 附加数据
    ///   - label: 标签 不会被加密
    /// - Returns: 钥匙串对象句柄ID
    func addAccountAndReturnIdentity(account: String, key: String, data: Data?, label: String = "") -> String? {
        addAccountAndReturnIdentity(withObject: AccessObject(identity: UUID().uuidString,
                                                             plainLabel: label,
                                                             account: account,
                                                             key: key,
                                                             representedObject: data))
    }

    /// 删除钥匙串对象
    /// - Parameter key: 句柄ID
    func removeAccountBy(key: String) {
        // 二次检查
        accessLock.lock()
        let copied = keyIdentities
        accessLock.unlock()
        if !copied.contains(key) {
            return
        }

        // 接下来删除文件储存
        let path = baseLocation
            .appendingPathComponent(key)
            .appendingPathExtension(PTKeyChain.fileSuffix)
        do {
            try FileManager.default.removeItem(at: path)
        } catch {
            // 删不掉文件下次起来还会有 不如报错呢
            PTLog.shared.join(self,
                              "failed to remove item at path: \(path.path)",
                              level: .error)
            return
        }

        // 上锁 不用defer稍微快一点 避免输出到文件有些慢
        accessLock.lock()
        keyIdentities.remove(key)
        keyContainer.removeValue(forKey: key)
        accessLock.unlock()

        PTLog.shared.join(self,
                          "removed account by id: \(key)",
                          level: .info)
    }

    /// 取回账号 即用即走 解密完的数据不宜久留
    /// - Parameter key: 句柄ID
    /// - Returns: 钥匙串账号对象
    func retrieveAccount(byKey key: String) -> AccessObject? {
        // 二次检查
        do {
            accessLock.lock()
            let copied = keyIdentities
            accessLock.unlock()
            if !copied.contains(key) {
                return nil
            }
        }

        do {
            accessLock.lock()
            let copied = keyContainer
            accessLock.unlock()
            // 这里应该已经解密完成了
            if let target = copied[key],
               let dec = decryptAccessObject(with: target)
            {
                return dec
            }
        }

        // 什么？没有数据？检查漏网之鱼
        let url = baseLocation
            .appendingPathComponent(key)
            .appendingPathExtension(PTKeyChain.fileSuffix)
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }
        guard let enc = retrieveEncryptedObjectFromFile(withData: data, andIdentity: key) else {
            return nil
        }
        // ~~这就很奇怪但毕竟有数据 一定是哪里有没同步到~~
        // 初始化的时候是会完整同步一次但是可能在这期间就需要数据了
        PTLog.shared.join(self,
                          "insert new key from file with identity: \(key)",
                          level: .warning)
        accessLock.lock()
        keyIdentities.insert(key)
        keyContainer[key] = enc
        accessLock.unlock()
        return decryptAccessObject(with: enc)
    }
}
