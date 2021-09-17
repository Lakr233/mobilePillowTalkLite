//
//  Checkpoint.swift
//  PTFoundation
//
//  Created by Lakr Aream on 1/1/21.
//

import Foundation

/// 检查点
public struct Checkpoint: Codable, Hashable {
    /// 名称
    public let name: String
    /// 分组
    public let section: String
    /// 服务器 可选 比如本地检查点就可以没有
    public let server: String?

    /// 触发器
    public let trigger: Trigger

    /// 最终需求
    public let finalRequirement: [Requirement]
    /// 执行步骤
    public let steps: [Step]

    public init(name: String,
                section: String,
                server: String? = nil,
                trigger: Trigger,
                requirement: [Requirement],
                steps: [Step])
    {
        self.name = PTFoundation.obtainValidNameForFile(origName: name).0
        self.section = PTFoundation.obtainValidNameForFile(origName: section).0
        self.server = server
        self.trigger = trigger
        finalRequirement = requirement
        self.steps = steps
    }

    public init(name: String,
                section: String,
                server: String?,
                trigger: @escaping () -> (Trigger),
                requirement: @escaping () -> ([Requirement]),
                steps: @escaping () -> ([Step]))
    {
        self.name = PTFoundation.obtainValidNameForFile(origName: name).0
        self.section = PTFoundation.obtainValidNameForFile(origName: section).0
        self.server = server
        self.trigger = trigger()
        finalRequirement = requirement()
        self.steps = steps()
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
        hasher.combine(section)
    }

    public static func == (lhs: Checkpoint, rhs: Checkpoint) -> Bool {
        lhs.name == rhs.name && lhs.section == rhs.section
    }
}
