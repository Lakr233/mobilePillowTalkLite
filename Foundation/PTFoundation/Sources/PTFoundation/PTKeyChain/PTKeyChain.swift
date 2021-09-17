//
//  PTKeyChain.swift
//  PTFoundation
//
//  Created by Lakr Aream on 12/13/20.
//

import Foundation

internal final class PTKeyChain {
    /// 文件后缀名
    internal static let fileSuffix = "ptk"
    /// 二级存档目录
    internal static let StoreBase = "Keychain"

    /// 数据对象
    internal struct AccessObject: Codable {
        let identity: String
        let plainLabel: String
        let account: String
        let key: String
        let representedObject: Data?
    }

    /// 加密的数据对象
    internal struct AccessObjectEncrypted: Codable {
        let plainIdentity: String
        let plainLabel: String
        let account: String
        let key: String
        let representedObject: String?
    }

    /// 访问结果
    internal enum AccessStatus: String {
        case success
        case permissionDenied
        case unkownError
    }

    /// 访问返回对象
    internal struct AccessResult {
        let status: AccessStatus
        let result: AccessObject
    }

    /// 公开接口
    public static let shared = PTKeyChain()

    /// 储存目录 在初始化时覆盖修改
    internal var baseLocation = PTFoundation.uninitiatedURL {
        didSet {
            if oldValue != PTFoundation.uninitiatedURL {
                debugPrint("PTKeyChain baseLocation is being modified! \(oldValue.path) -> \(baseLocation.path)")
            }
        }
    }

    /// 数据处理锁
    internal let executionLock = NSLock()
    /// 用于处理数据的加密引擎
    internal var masterCryptoEngine: AES? {
        didSet {
            if oldValue != nil {
                debugPrint("PTKeyChain masterCryptoEngine was modified!")
            }
        }
    }

    /// 访问数据的锁
    internal let accessLock = NSLock()

    /// 储存密钥的id 访问上锁
    internal var keyIdentities: Set<String> = []

    /// 密钥的实体对象 访问上锁
    /// 保存在内存中 如果没有回去本地查找
    internal var keyContainer: [String: AccessObjectEncrypted] = [:]

    /// 不允许外部初始化
    private init() {}
}
