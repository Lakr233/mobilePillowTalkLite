//
//  Checkpoint.swift
//  PTFoundation
//
//  Created by Lakr Aream on 4/16/21.
//

import Foundation

public extension Checkpoint {
    /// 触发器
    struct Trigger: Codable {
        /// 描述检查点的执行方式
        public enum Kind: String, Codable {
            // 两次间隔达到描述
            case timeInterval
            // 计划任务 在对应时间点触发
            case timeSchedule
            // 手动执行
            case manual
        }

        public let type: Kind
        public let representedValue: String

        public func triggerElegantForExecution() -> Bool {
            // TODO: FIX ME IMPL
            true
        }
    }

    /// 需求类型
    struct Requirement: Codable {
        /// 需求类型
        public enum Kind: String, Codable {
            case contains // 包含
            case returnValue // 返回值以 Int 方式匹配
            case matchCaseSensitive // 匹配全部字符串 包含大小写
            case matchCaseInsensitive // 匹配全部字符串 不包含大小写
            case matchRegularExpression // 正则表达式匹配全部
            case matchNumberValue // 将确认数据为数字并匹配数值
        }

        /// 需求类型
        public let type: Kind
        /// 检查值的健
        public let key: String?
        /// 值需要根据类型满足这个 value
        public let representedValue: String
        public init(type: Kind, key: String?, value: String) {
            self.type = type
            self.key = key
            representedValue = value
        }
    }

    /// 步骤
    struct Step: Codable {
        /// 类型 指定了查找的位置
        public enum Kind: String, Codable {
            case CodeClip
            case CodeGroup
        }

        /// clip or group
        public var type: Kind
        /// 名称
        public var name: String
        /// 分组
        public var section: String
        /// 目标 一般保存服务器 如果有就优先使用 覆盖检查点内的 server
        public var target: String?
        /// 需求
        public var requirement: [Requirement]
        public init(type: Kind,
                    name: String,
                    section: String,
                    target: String?,
                    requirement: [Requirement])
        {
            self.type = type
            self.name = name
            self.section = section
            self.target = target
            self.requirement = requirement
        }
    }
}
