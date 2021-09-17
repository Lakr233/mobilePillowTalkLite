//
//  AES.swift
//  PTFoundation
//
//  Created by Lakr Aream on 12/15/20.
//

import CommonCrypto
import Foundation

public struct AES {
    private let key: Data
    private let iv: Data

    /// 初始化 AES 引擎
    /// - Parameters:
    ///   - initKey: 要求足够长 大于或等于 32
    ///   - initIV: 要求足够长 大于或等于 16
    internal init?(key initKey: String, iv initIV: String) {
        // 初始化密钥 核查长度要求
        if initKey.count < kCCKeySizeAES128 || initIV.count < kCCBlockSizeAES128 {
            debugPrint("Error \(#file) \(#line): Failed to set key(\(initKey.count))[\(kCCKeySizeAES128)] or iv(\(initIV.count))[\(kCCBlockSizeAES128)], too short.")
            return nil
        }
        // 修改 key 到指定长度
        var initKey = initKey
        while initKey.count < 32 { // 防止意外
            initKey += initKey
        }
        while initKey.count > 32 {
            initKey.removeLast()
        }
        guard initKey.count == kCCKeySizeAES128 || initKey.count == kCCKeySizeAES256,
              let keyData = initKey.data(using: .utf8)
        else {
            debugPrint("Error \(#file) \(#line): Failed to set a key, data invalid")
            return nil
        }
        // 修改 iv 到指定长度
        var initIV = initIV
        while initIV.count < kCCBlockSizeAES128 { // 防止意外
            initIV += initIV
        }
        while initIV.count > kCCBlockSizeAES128 {
            initIV.removeLast()
        }
        guard initIV.count == kCCBlockSizeAES128, let ivData = initIV.data(using: .utf8) else {
            debugPrint("Error \(#file) \(#line): Failed to set an initial vector.")
            return nil
        }
        // 储存
        key = keyData
        iv = ivData
    }

    // MARK: - API

    /// 加密数据 返回 base64 编码后的字符串
    /// - Parameter data: 被加密的数据
    /// - Returns: 数据被 base64 编码后的字符串
    public func encrypt(data: Data) -> String? {
        guard let result = crypt(data: data, option: CCOperation(kCCEncrypt)) else {
            return nil
        }
        guard let base64 = String(data: result.base64EncodedData(), encoding: .utf8) else {
            return nil
        }
        return base64
    }

    /// 加密数据 返回 base64 编码后的字符串
    /// - Parameter string: 被加密字符串
    /// - Returns: 数据被 base64 编码后的字符串
    public func encrypt(string: String) -> String? {
        guard let data = string.data(using: .utf8) else {
            return nil
        }
        guard let result = crypt(data: data, option: CCOperation(kCCEncrypt)) else {
            return nil
        }
        guard let base64 = String(data: result.base64EncodedData(), encoding: .utf8) else {
            return nil
        }
        return base64
    }

    /// 解密数据
    /// - Parameter base64: 数据被 base64 编码后的字符串
    /// - Returns: 数据
    public func decrypt(base64: String) -> Data? {
        guard let data = Data(base64Encoded: base64) else {
            return nil
        }
        guard let decryptedData = crypt(data: data, option: CCOperation(kCCDecrypt)) else {
            return nil
        }
        return decryptedData
    }

    /// 解密数据
    /// - Parameter base64: base64 编码后的数据
    /// - Returns: 数据
    public func decrypt(base64: Data) -> Data? {
        guard let data = Data(base64Encoded: base64) else {
            return nil
        }
        guard let decryptedData = crypt(data: data, option: CCOperation(kCCDecrypt)) else {
            return nil
        }
        return decryptedData
    }

    /// 解密字符串
    /// - Parameter base64: 数据被 base64 编码后的字符串
    /// - Returns: 数据
    public func decryptString(base64: String) -> String? {
        guard let data = Data(base64Encoded: base64) else {
            return nil
        }
        guard let decryptedData = crypt(data: data, option: CCOperation(kCCDecrypt)) else {
            return nil
        }
        return String(data: decryptedData, encoding: .utf8)
    }

    /// 解密字符串
    /// - Parameter base64: base64 编码后的数据
    /// - Returns: 数据
    public func decryptString(base64: Data) -> String? {
        guard let data = Data(base64Encoded: base64) else {
            return nil
        }
        guard let decryptedData = crypt(data: data, option: CCOperation(kCCDecrypt)) else {
            return nil
        }
        return String(data: decryptedData, encoding: .utf8)
    }

    // MARK: - INTERNAL

    private func crypt(data: Data?, option: CCOperation) -> Data? {
        guard let data = data else { return nil }

        let cryptLength = data.count + kCCBlockSizeAES128
        var cryptData = Data(count: cryptLength)

        let keyLength = key.count
        let options = CCOptions(kCCOptionPKCS7Padding)

        var bytesLength = Int(0)

        let status = cryptData.withUnsafeMutableBytes { cryptBytes in
            data.withUnsafeBytes { dataBytes in
                iv.withUnsafeBytes { ivBytes in
                    key.withUnsafeBytes { keyBytes in
                        CCCrypt(option, CCAlgorithm(kCCAlgorithmAES), options, keyBytes.baseAddress, keyLength, ivBytes.baseAddress, dataBytes.baseAddress, data.count, cryptBytes.baseAddress, cryptLength, &bytesLength)
                    }
                }
            }
        }

        guard UInt32(status) == UInt32(kCCSuccess) else {
            debugPrint("Error: Failed to crypt data. Status \(status)")
            return nil
        }

        cryptData.removeSubrange(bytesLength ..< cryptData.count)
        return cryptData
    }
}
