//
//  CodeClip.swift
//  PTFoundation
//
//  Created by Lakr Aream on 12/18/20.
//

import Foundation

public struct CodeClip: Codable, Hashable, PTUIRepresentable {
    /// 执行器类型
    public enum Executor: String, Codable {
        case bash
        case js
    }

    /// 执行目标类型
    public enum Target: String, Codable {
        case remote
        case local
    }

    /// 名称
    public var name: String {
        didSet {
            assert(name.count > 1, "CodeClip name must be longer than 0")
        }
    }

    /// 图标
    public var icon: String?
    /// 脚本
    public var code: String
    /// 分组
    public var section: String {
        didSet {
            if section.count < 1 {
                section = PTCodeClipManager.defaultSectionName
            }
        }
    }

    /// 超时
    public var timeout: Int
    /// 执行器
    public var executor: Executor?
    /// 目标
    public var target: Target?

    /// 初始化
    /// - Parameters:
    ///   - name: 名称
    ///   - icon: 图标
    ///   - code: 脚本
    ///   - section: 分组
    ///   - timeout: 超时
    ///   - executor: 执行器
    ///   - target: 执行目标
    public init(name: String = "",
                icon: String? = nil,
                code: String = "",
                section: String = "",
                timeout: Int = 0,
                executor: Executor? = nil,
                target: Target? = nil)
    {
        self.name = PTFoundation.obtainValidNameForFile(origName: name).0
        self.icon = icon
        self.code = code
        self.section = PTFoundation.obtainValidNameForFile(origName: section).0
        self.timeout = timeout
        self.executor = executor
        self.target = target
    }

    // MARK: CODER

    public func encodeToData() -> Data? {
        try? PTFoundation.plistEncoder.encode(self)
    }

    public static func decodeFromData(data: Data) -> Self? {
        try? PTFoundation.plistDecoder.decode(Self.self, from: data)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(icon)
        hasher.combine(section)
    }

    public static func == (lhs: CodeClip, rhs: CodeClip) -> Bool {
        lhs.name == rhs.name && lhs.section == rhs.section
    }
}
