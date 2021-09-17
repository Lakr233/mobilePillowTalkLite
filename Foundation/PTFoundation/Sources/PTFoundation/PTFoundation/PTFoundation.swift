//
//  PTFoundation.swift
//  PTFoundation
//
//  Created by Lakr Aream on a magic day.
//

import Foundation

public final class PTFoundation {
    public private(set) static var initialized: Bool = false
    
    // VESION STATIC
    public static let version = "v1.0"
    public static let apiVersion = "v1.0"

    // PLIST
    public static let jsonDecoder = JSONDecoder()
    public static let jsonEncoder = JSONEncoder()
    public static let jsonSerialization = JSONSerialization()

    // JSON
    public static let plistDecoder = PropertyListDecoder()
    public static let plistEncoder = PropertyListEncoder()
    public static let plistSerialization = PropertyListSerialization()

    // STUB
    public static let uninitiatedURL = URL(fileURLWithPath: "/BAD/URL/ACCESS")

    /// 初始化错误 遇到就崩
    public enum InitializationError: String {
        case filePermissionDenied
        case logInitializationFailed
        case keychainInitializationFailed
        case serverManagerInitializationFailed
        case serverManagerDatabaseInitializationFailed
        case accountManagerInitializationFailed
        case codeClipManagerInitializationFailed
    }

    /// 运行时错误 遇到就崩
    public enum RuntimeError: String {
        case filePermissionDenied
        case resourceBroken
        case invalidMemoryData
        case badExecutionLogic
        case unknown
    }

    /// 文件错误
    public enum FileError {
        case badFileExists
        case permissionDenied
    }

    /// 存档位置
    static var baseDir = PTFoundation.uninitiatedURL {
        didSet {
            if baseDirLock {
                fatalError("[PTFoundation] initialization was called before!")
            }
            baseDirLock = true
        }
    }

    static var baseDirLock: Bool = false

    private static var _runtimeErrorCall: ((RuntimeError) -> Void)?
    public static var runtimeErrorCall: ((RuntimeError) -> (Never)) = { capture in
        PTLog.shared.join(PTFoundation.self, "Last error thrown: \(capture)", level: .critical)
        PTLog.shared.join(PTFoundation.self, "the blue whale is dead, bye bye~", level: .critical)
        Thread.callStackSymbols.forEach { stack in
            PTLog.shared.join(PTFoundation.self, stack, level: .critical)
        }
        _runtimeErrorCall!(capture)
        #if DEBUG
            fatalError("代码整劈叉了心里没点逼数吗！")
        #else
            fatalError("Error was raised from foundation manually, please contact user support if possible!")
        #endif
    }
    
    private static var _requestingUserDefaultCall: (String) -> (Any?) = { _ in nil }
    /// 请求返回用户设置
    /// - Parameters:
    ///   - key: 键
    ///   - defaultValue: 默认值
    /// - Returns: 数据
    internal static func requestingUserDefault<T>(forKey key: PTUserDefaultKeys, defaultValue: T? = nil) -> T {
        return ((_requestingUserDefaultCall(key.rawValue) as? T) ?? defaultValue)!
    }
    
    /// 初始化Foundation组件
    /// - Parameters:
    ///   - baseDir: 可读写目录位置
    ///   - masterKey: 主钥匙串解密密钥
    ///   - onCriticalError: 初始化中不可恢复错误回掉
    ///   - requireRunLoop: 是否启用 RunLoop
    ///   - requestingUserDefault: 请求用户偏好设置 发送键 返回值
    ///   - onRuntimeCriticalError: 运行时的错误回掉
    public static func initialization(baseDir: URL, masterKey: String?,
                                      requireRunLoop: Bool,
                                      requestingUserDefault: @escaping (String) -> (Any?),
                                      onCriticalError: @escaping (InitializationError) -> (Never),
                                      onRuntimeCriticalError: @escaping (RuntimeError) -> Void)
    {
        defer {
            PTFoundation.initialized = true
        }

        PTFoundation._runtimeErrorCall = onRuntimeCriticalError
        PTFoundation._requestingUserDefaultCall = requestingUserDefault

        if PTFoundation.ensureDirExists(atLocation: baseDir) != nil {
            onCriticalError(.filePermissionDenied)
        }

        PTFoundation.baseDir = baseDir

        // 初始化 PTLog
        do {
            #if DEBUG
                let config = PTLog.PTLogConfig(location: baseDir, level: .verbose)
            #else
                let config = PTLog.PTLogConfig(location: baseDir, level: .info)
            #endif
            if let error = PTLog.shared.initialization(withConfiguration: config) {
                onCriticalError(error)
            }
            PTLog.shared.join(self, "PTFoundation")
            PTLog.shared.join(self, "Copyright © 2020 Pillow Talk Team. All rights reserved.")
            #if DEBUG
                PTLog.shared.join(self, "Debug build is restricted with NDA license, use with caution!")
            #endif
        }

        func _onCriticalError(_ error: InitializationError) -> Never {
            PTLog.shared.join(self, "foundation called abort with error: \(error)", level: .critical)
            onCriticalError(error)
        }

        // 初始化 KeyChain 如果提供了 masterKey 就跳过向系统询问钥匙串的部分
        if let masterKey = masterKey {
            if let error = PTKeyChain.shared.initialization(toDir: baseDir, masterKey: masterKey) {
                _onCriticalError(error)
            }
        } else {
            do {
                let keychainServiceID = "wiki.qaq.PillowTalk.kcAccess"
                let masterKeyID = "wiki.qaq.PillowTalk.MasterCrypto"
//                #if os(iOS) || os(watchOS) || os(tvOS)
                let keychain = Keychain(service: keychainServiceID)
//                #else
//                let keychainGroupID = "wiki.qaq.PillowTalk.kcAccess.kcAccessGroup"
//                let keychain = Keychain(service: keychainServiceID, accessGroup: keychainGroupID)
//                #endif
                var retry = 0
                var key: String?
                while retry < 3, key == nil {
                    do {
                        let master = try keychain.getString(masterKeyID)
                        if let master = master, master.count > 2 {
                            key = master
                        } else {
                            try keychain.remove(masterKeyID)
                            let new = UUID().uuidString
                            key = new
                            try keychain
                                .label("PillowTalk Master Crypto Key")
                                .comment("PillowTalk requires a master crypto key to access your encrypted data on disk andprotects your accounts")
                                .set(new, key: masterKeyID)
                        }
                    } catch {
                        PTLog.shared.join(self,
                                          "access to keychain failed, unable to retrieve master key, \(error.localizedDescription)",
                                          level: .critical)
                    }
                    retry += 1
                }
                guard let masterKey = key else {
                    _onCriticalError(.keychainInitializationFailed)
                }
                if let error = PTKeyChain.shared.initialization(toDir: baseDir, masterKey: masterKey) {
                    _onCriticalError(error)
                }
            }
        }

        // 初始化 RunLoop
        if requireRunLoop {
            PTRunLoop.shared.initlization()
        }

        // 初始化账户
        if let error = PTAccountManager.shared.initialization(toDir: baseDir) {
            PTLog.shared.join(self, "initialization interrupted via \(error)", level: .critical)
            _onCriticalError(.accountManagerInitializationFailed)
        }

        // 初始化 ServerManager
        if let error = PTServerManager.shared.initialization(toDir: baseDir, requireRunLoop: requireRunLoop) {
            PTLog.shared.join(self, "initialization interrupted via \(error)", level: .critical)
            _onCriticalError(.serverManagerInitializationFailed)
        }

        // 初始化代码片段
        if let error = PTCodeClipManager.shared.initialization(toDir: baseDir) {
            PTLog.shared.join(self, "initialization interrupted via \(error)", level: .critical)
            _onCriticalError(.codeClipManagerInitializationFailed)
        }

        // 初始化检查点
        if let error = PTCheckpointManager.shared.initialization(toDir: baseDir) {
            PTLog.shared.join(self, "initialization interrupted via \(error)", level: .critical)
            _onCriticalError(.codeClipManagerInitializationFailed)
        }
    }

    /// 保证目录存在于此
    /// - Parameter at: 位置
    /// - Returns: 返回错误 如果有
    public static func ensureDirExists(atLocation location: URL) -> FileError? {
        assert(location.path.count > 0, "Invalid location value")
        do {
            var isDir = ObjCBool(false)
            let exists = FileManager.default.fileExists(atPath: location.path, isDirectory: &isDir)
            // 文件存在 并且不是目录
            if exists, !isDir.boolValue {
                return .badFileExists
            }
            if exists, isDir.boolValue {
                return nil
            }
        }
        do {
            if !FileManager.default.fileExists(atPath: location.path) {
                try FileManager.default.createDirectory(atPath: location.path, withIntermediateDirectories: true, attributes: nil)
            }
        } catch {
            return .permissionDenied
        }
        do {
            var isDir = ObjCBool(false)
            let exists = FileManager.default.fileExists(atPath: location.path, isDirectory: &isDir)
            if !(exists && isDir.boolValue) {
                return .permissionDenied
            }
        }
        return nil
    }

    /// 退出程序前解构初始化
    public static func teardownFoundation(exitCode: Int, shouldExit: Bool) {
        PTLog.shared.join(self,
                          "application foundation starting teardown")
        PTRunLoop.shared.teardown()
        if !shouldExit {
            return
        }
        exit(Int32(exitCode))
    }

    /// 获取内置静态环境变量 通常用于指定 app 版本
    /// - Returns: 环境变量字典
    public static func obtainExecutionEnvironment() -> [String: String] {
        var ret = [String: String]()
        ret["PILLOWTALK_VERSION"] = PTFoundation.version
        ret["PILLOWTALK_API_SET"] = PTFoundation.apiVersion
        return ret
    }

//    /// 在一个方法内安全上锁多个锁 避免相互等待
//    /// - Parameter withLock: lock 数组
//    public static func acquireLocks(withLock: [NSLock]) {
//        withLock
//            .sorted(by: {
//                Unmanaged.passUnretained($0).toOpaque() < Unmanaged.passUnretained($1).toOpaque()
//            })
//            .forEach { $0.lock() }
//    }

//    /// 释放锁
//    /// - Parameter withLock: lock 数组
//    public static func releaseLocks(withLock: [NSLock]) {
//        for lock in withLock { lock.unlock() }
//    }

    public typealias NameValid = Bool
    /// 合法化文件名
    /// - Parameter name: 名称
    /// - Returns: 合法化的文件名
    public static func obtainValidNameForFile(origName name: String) -> (String, NameValid) {
        var invalidCharacters = CharacterSet(charactersIn: ":/")
        invalidCharacters.formUnion(.newlines)
        invalidCharacters.formUnion(.illegalCharacters)
        invalidCharacters.formUnion(.controlCharacters)
        var validName = name
            .components(separatedBy: invalidCharacters)
            .joined(separator: "")
        if validName.count < 1 {
            validName = UUID().uuidString
            PTLog.shared.join(self,
                              "invalid name for file [\(name)] changed to [\(validName)]",
                              level: .error)
            return (validName, false)
        }
        return (validName, name == validName)
    }

    /// 往系统钥匙串里面储存数据 value -> base64
    /// - Parameters:
    ///   - key: 键值
    ///   - value: 数据
    public static func convinceEncryptUsingMasterKey(value: String) -> String? {
        guard let aes = PTKeyChain.shared.masterCryptoEngine else {
            PTLog.shared.join(self,
                              "master crypto engine not initialized",
                              level: .error)
            return nil
        }
        return aes.encrypt(string: value)
    }

    /// 读取系统钥匙串的内容 base64 -> value
    /// - Parameter key: 键值
    /// - Returns: 数据
    public static func convinceDecryptUsingMasterKey(value: String) -> String? {
        guard let aes = PTKeyChain.shared.masterCryptoEngine else {
            PTLog.shared.join(self,
                              "master crypto engine not initialized",
                              level: .error)
            return nil
        }
        return aes.decryptString(base64: value)
    }
}
