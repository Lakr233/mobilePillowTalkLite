//
//  PTAccountManager.swift
//  PTFoundation
//
//  Created by Lakr Aream on 12/15/20.
//

import Foundation

public extension PTAccountManager {
    /// 创建账号 上执行锁 子方法可能上访问锁
    /// - Parameters:
    ///   - user: 用户
    ///   - candidate: 凭证
    ///   - attachData: 附加数据
    ///   - type: 类型
    /// - Returns: 账号句柄
    func createAccountWith(user: String,
                           candidate: String,
                           attachData: Data?,
                           type: AccountType) -> AccountHandler?
    {
        // 跑到 KeyChain 去开一个钥匙串 并拿回来识别号
        guard let kCID = PTKeyChain.shared.addAccountAndReturnIdentity(account: user,
                                                                       key: candidate,
                                                                       data: attachData,
                                                                       label: type.rawValue)
        else {
            PTLog.shared.join(self,
                              "failed to create account due to keychain error",
                              level: .warning)
            return nil
        }

        executionLock.lock()
        let previousIdentities = accounts
        executionLock.unlock()

        // 如果 KeyChain 吐出来的识别号已经存在 那就是宇宙要爆炸
        if previousIdentities.keys.contains(kCID) {
            PTLog.shared.join(self, "account identity collision, what a great luck, but the whale dead \(kCID)", level: .critical)
            PTKeyChain.shared.removeAccountBy(key: kCID)
            PTFoundation.runtimeErrorCall(.resourceBroken)
        }

        // 创建账号对象 赋能方法集
        let createdAccount: Account
        switch type {
        case .secureShellWithPassword, .secureShellWithKey:
            createdAccount = Account(type: type,
                                     function: PTServerSSHLinuxSelectors.shared,
                                     keychainIdentity: kCID)
        }

        // 本方法已经处理完成
        executionLock.lock()
        accounts[kCID] = createdAccount
        executionLock.unlock()

        synchronizeObjects()

        return kCID
    }

    /// 取回账号 上执行锁访问锁
    /// - Parameter key: 句柄
    /// - Returns: 账号对象
    func retrieveAccountWith(key: String) -> Account? {
        executionLock.lock()
        let copy = accounts[key]
        executionLock.unlock()
        return copy
    }

    /// 删除账号 上执行锁 访问锁
    /// - Parameter key: 句柄
    func removeAccount(withKey key: AccountHandler) {
        executionLock.lock()
        accounts.removeValue(forKey: key)
        executionLock.unlock()
        synchronizeObjects()
        // 清理 KeyChain
        PTKeyChain.shared.removeAccountBy(key: key)
    }

    /// 获取账户句柄列表
    /// - Returns: 列表
    func obtainAccountKeyList() -> [AccountHandler] {
        executionLock.lock()
        let copy = accounts.keys
        executionLock.unlock()
        return [AccountHandler](copy)
    }
}
