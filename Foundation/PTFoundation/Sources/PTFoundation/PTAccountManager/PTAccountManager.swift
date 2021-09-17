//
//  PTAccountManager.swift
//  PTFoundation
//
//  Created by Lakr Aream on 12/13/20.
//

import Foundation

/*

 PTAccountManager
 是连接KeyChain和ServerManager的桥梁
 账号对应账号储存 使用相同的ID

 */

public final class PTAccountManager {
    // MARK: 结构体定义

    public typealias AccountHandler = String

    /// 用户结构体暴露的接口
    public struct Account {
        /// 用户名
        public let uuid: String
        /// 账户类型
        public let type: AccountType
        /// 方法集 用于获取扩展的接口
        public let selectors: PTServerAllocationSelectors

        // MARK: INTERNAL

        /// 不允许外部初始化该结构体
        internal init(type: AccountType,
                      function: PTServerAllocationSelectors,
                      keychainIdentity identity: String)
        {
            uuid = identity
            self.type = type
            selectors = function
        }

        /// 内部转换方法
        internal func obtainAccountStoreObject() -> AccountStore {
            AccountStore(fromAccount: self)
        }

        // MARK: PUBLIC

        /// 解密数据结构体 暴露接口
        public struct DecryptedObject {
            public let identity: String
            public let plainLabel: String
            public let account: String
            public let key: String
            public let representedObject: Data?
        }

        /// 获取解密的数据
        /// DecryptedObject 类似于 PTKeyChain.AccessObject
        /// 但 PTKeyChain.AccessObject 后者申明了 internal
        public func obtainDecryptedObject() -> DecryptedObject? {
            guard let decrypted = PTKeyChain.shared.retrieveAccount(byKey: uuid) else {
                return nil
            }
            return DecryptedObject(identity: decrypted.identity,
                                   plainLabel: decrypted.plainLabel,
                                   account: decrypted.account,
                                   key: decrypted.key,
                                   representedObject: decrypted.representedObject)
        }
    }

    /// 储存使用的对象 需要额外注意 Codable
    internal struct AccountStore: Codable {
        /// 变量映射
        let identity: String
        let type: String
        let selectors: String

        /// 初始化
        internal init(fromAccount object: Account) {
            identity = object.uuid
            type = object.type.rawValue
            selectors = object.selectors.obtainIdentity()
        }

        /// 内部方法转换
        internal func retrieveAccountObject() -> Account? {
            // 获取账户类型
            guard let typeCase = AccountType(rawValue: type) else {
                return nil
            }
            // 获取方法集
            var selectorsObject: PTServerAllocationSelectors?
            for fs in PTServerAllocationSelectors.allSets {
                if fs.obtainIdentity() == selectors {
                    selectorsObject = fs
                    break
                }
            }
            // 没找到方法集
            guard let fSet = selectorsObject else {
                return nil
            }
            // 合成
            return Account(type: typeCase, function: fSet, keychainIdentity: identity)
        }
    }

    /// 账户类型
    public enum AccountType: String, Codable {
        /// SSH 密码登录
        case secureShellWithPassword
        /// SSH 密钥登录 但是这里要注意并非所有密钥都需要密码
        case secureShellWithKey
    }

    // MARK: 类成员属性

    /// 单例
    public static let shared = PTAccountManager()
    private init() {}

    /// 储存位置定义
    internal static let StoreBase = "Accounts"
    internal var baseLocation = PTFoundation.uninitiatedURL

    /// 锁 全部改成手动上锁
    internal var executionLock = NSLock()
    internal var syncLock = NSLock()

    /// 同步数据的节流阀
    internal let syncThrottle = PTThrottle(minimumDelay: 1,
                                            queue: DispatchQueue.global(qos: .background))

    /// 属性变量
    internal var accounts: [String: Account] = [:]
}
