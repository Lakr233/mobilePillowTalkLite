//
//  CodeClipGroup.swift
//  PTFoundation
//
//  Created by Lakr Aream on 12/28/20.
//

import Foundation

public struct CodeClipGroup: Codable, Hashable, PTUIRepresentable {
    /// 表示要执行的每一步
    public struct Element: Codable {
        public let code: CodeClip
        // 目前只允许在同一台主机上执行
//        public let serverDescriptor: String?
        public init(code: CodeClip /* , serverDescriptor _: String? */ ) {
            self.code = code
//            self.serverDescriptor = serverDescriptor
        }
    }

    /// 执行的内容
    public var payloads: [Element] = []

    /// 名称
    public var name: String {
        didSet {
            assert(name.count > 1, "CodeClip name must be longer than 0")
        }
    }

    /// 图标
    public var icon: String?
    /// 分组
    public var section: String {
        didSet {
            if section.count < 1 {
                section = PTCodeClipManager.defaultSectionName
            }
        }
    }

    /// 初始化
    /// - Parameters:
    ///   - payloads: 执行内容
    ///   - name: 名称
    ///   - icon: 图标
    ///   - section: 分组
    public init(payloads: [Element],
                name: String,
                icon: String? = nil,
                section: String)
    {
        self.name = PTFoundation.obtainValidNameForFile(origName: name).0
        self.icon = icon
        self.section = PTFoundation.obtainValidNameForFile(origName: section).0
        self.payloads = payloads
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

    public static func == (lhs: CodeClipGroup, rhs: CodeClipGroup) -> Bool {
        lhs.name == rhs.name && lhs.section == rhs.section
    }
}
