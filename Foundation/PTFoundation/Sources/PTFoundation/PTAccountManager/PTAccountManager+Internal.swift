//
//  PTAccountManager.swift
//  PTFoundation
//
//  Created by Lakr Aream on 12/15/20.
//

import Foundation

extension PTAccountManager {
    /// 初始化 不上锁 交给 Foundation 去限制
    /// - Parameters:
    ///   - toDir: 储存位置
    /// - Returns: 错误 如果存在
    func initialization(toDir: URL) -> PTFoundation.InitializationError? {
        // 检查并初始化文件储存
        if PTFoundation.ensureDirExists(atLocation: toDir) != nil {
            return .filePermissionDenied
        }

        baseLocation = toDir.appendingPathComponent(PTAccountManager.StoreBase)
        if PTFoundation.ensureDirExists(atLocation: baseLocation) != nil {
            return .filePermissionDenied
        }

        let build = reloadAccountsFromFile()
        PTLog.shared.join(self,
                          "initialization process reported \(build.count) loaded accounts(s)",
                          level: .info)

        return nil
    }

    /// 保存账号到本地 如果存在就覆盖 从 create 调用
    /// - Parameter account: 账号对象
    func synchronizeObjects() {
        syncThrottle.throttle {
            self.executionLock.lock()
            let capture = self.accounts
            self.executionLock.unlock()
            self.syncLock.lock()
            do {
                let fileNames = try FileManager.default.contentsOfDirectory(atPath: self.baseLocation.path)
                for fileNameRaw in fileNames {
                    let fileName = fileNameRaw.hasSuffix("plist")
                        ? String(fileNameRaw.dropLast(".plist".count))
                        : fileNameRaw
                    if !capture.keys.contains(fileName) {
                        try FileManager.default.removeItem(at: self.baseLocation.appendingPathComponent(fileNameRaw))
                    }
                }
            } catch {
                PTLog.shared.join(self,
                                  "failed to synchronize account list",
                                  level: .critical)
                PTFoundation.runtimeErrorCall(.filePermissionDenied)
            }
            // 更新储存数据
            for (_, account) in capture {
                let url = self.baseLocation.appendingPathComponent(account.uuid)
                let store = AccountStore(fromAccount: account)
                do {
                    let data = try PTFoundation.plistEncoder.encode(store)
                    try data.write(to: url.appendingPathExtension("plist"), options: .atomic)
                } catch {
                    // 处理失败了 多半情况下是文件劈叉了 代码有单元测试
                    PTLog.shared.join(self,
                                      "failed to compile/synchronize account data",
                                      level: .critical)
                    PTFoundation.runtimeErrorCall(.filePermissionDenied)
                }
            }
            self.syncLock.unlock()
            PTLog.shared.join(self, "configuration sync completed", level: .info)
        }
    }

    /// 重新加载账户 上执行锁访问锁
    /// - Returns: 账户句柄
    func reloadAccountsFromFile() -> [AccountHandler] {
        var accountContainer = [String: Account]()

        executionLock.lock()
        let fileNames = try? FileManager.default.contentsOfDirectory(atPath: baseLocation.path)
        fileNames?.forEach { name in
            let url = baseLocation
                .appendingPathComponent(name) // already had .plist
            guard let data = try? Data(contentsOf: url) else {
                PTLog.shared.join(self,
                                  "failed to load account at \(url.path), removing it!",
                                  level: .warning)
                // 没有获取到数据 文件不合法或损坏
                try? FileManager.default.removeItem(at: url)
                return
            }
            do {
                let object = try PTFoundation.plistDecoder.decode(AccountStore.self, from: data)
                // 然后获取对象
                if let compiledObject = object.retrieveAccountObject() {
                    accountContainer[object.identity] = compiledObject
                }
            } catch {
                // 没有获取到数据 文件不合法或损坏
                PTLog.shared.join(self,
                                  "bad data reported from account store, removing! \(url.path)",
                                  level: .warning)
                try? FileManager.default.removeItem(at: url)
            }
        }

        accounts = accountContainer

        executionLock.unlock()

        return [String](accountContainer.keys)
    }
}
