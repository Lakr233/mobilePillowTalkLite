//
//  PTJavaScriptExecutor.swift
//  PTFoundation
//
//  Created by Lakr Aream on 12/18/20.
//

import Foundation
import JavaScriptCore

public final class PTJavaScriptExecutor {
    /// 环境变量类型定义 Key-Value
    public typealias EnvironmentVariable = [String: String]

    /// 执行内容
    public struct JavaScript {
        let variables: EnvironmentVariable
        let code: String
        let timeout: Double
        public init(vars: EnvironmentVariable, code: String, timeout: Double) {
            variables = vars
            self.code = code
            self.timeout = timeout
        }
    }

    /// 回执
    public struct JavaScriptRecipe {
        let didSucceed: Bool
        let error: String?
        let value: [String: String]
    }

    /// 单例
    public static let shared = PTJavaScriptExecutor()

    /// 拒绝外部初始化
    private init() {}

    /// 最大同步执行 N 个任务
    internal let concurrentControl = DispatchSemaphore(value: 6)
}
