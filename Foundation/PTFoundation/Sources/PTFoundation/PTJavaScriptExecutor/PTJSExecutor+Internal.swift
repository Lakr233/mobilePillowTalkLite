//
//  PTJavaScriptExecutor+Internal.swift
//  PTFoundation
//
//  Created by Lakr Aream on 12/18/20.
//

import Foundation
import JavaScriptCore

private let PTJavaScriptFormatter = """
function PTJavaScriptMain() {
    let Env = %@;
    let PTResultRecipe = {
        code: 0,
        error: "",
        value: {}
    };
    %@;
    return PTResultRecipe;
};
PTJavaScriptMain();
"""

extension PTJavaScriptExecutor {
    typealias DidTimeout = Bool
    struct JSRecpieInternal {
        let timeout: DidTimeout
        let value: JSValue?
    }

    /// 执行脚本并监视是否超时
    /// - Parameters:
    ///   - context: 引擎上下文
    ///   - code: 脚本代码
    ///   - timeout: 超时时间
    /// - Returns: 是否超时
    func executeWithTimeoutWatched(context: JSContext,
                                   code: String,
                                   timeout: Double) -> JSRecpieInternal
    {
        // 获取迸发控制信号量 - 1
        let acquireControl = concurrentControl.wait(timeout: .now() + 6)
        // 信号量放行失败 返回处理失败
        if acquireControl == .timedOut {
            return .init(timeout: true, value: nil)
        }
        defer {
            // 如果获取成功则释放迸发控制信号量 double check + 1
            if acquireControl == .success { self.concurrentControl.signal() }
        }

        // 处理执行内容
        var jsValue: JSValue?
        let control = DispatchSemaphore(value: 0)

        // 分发到子线程进行执行 并在当前线程设置等待
        let queue = DispatchQueue(label: "wiki.qaq.JavaScripts.\(UUID())")
        queue.async {
            // 执行
            jsValue = context.evaluateScript(code)
            // 通知原线程 + 1
            control.signal()
        }
        // 等待子线程 - 1
        if timeout > 0 {
            let result = control.wait(timeout: .now() + timeout)
            if result == .timedOut {
                // 超时 干不掉子线程 直接返回

                /*  MARK: TODO FIX ME
                 *  let group = JSContextGetGroup(context.jsGlobalContextRef)
                 *  JSContextGroupSetExecutionTimeLimit(group)
                 */

                PTLog.shared.join(self, "PTJavaScriptExecutor reports an timeout executing script", level: .warning)
                return .init(timeout: true, value: nil)
            }
        } else {
            // MARK: TODO FIX ME 写入文档

            _ = control.wait(timeout: .now() + 1800)
        }

        // 执行成功返回
        return .init(timeout: false, value: jsValue)
    }

    /// 阻塞同步执行
    /// - Parameter object: 执行对象
    /// - Returns: 回执
    func atomicEvaluate(object: JavaScript) -> JavaScriptRecipe {
        // 初始化全新的上下文
        guard let context = JSContext() else {
            return .init(didSucceed: false,
                         error: "JSEngine failed to initialize",
                         value: [
                             "ExecExitCode": "-10002",
                             "ExecError": "JSEngine failed to initialize",
                         ])
        }
        // 错误容器
        var getError: String?
        // 设置错误回掉
        context.exceptionHandler = { _, exception in
            getError = exception?.toString() ?? "Unknown Exception"
        }

        // 导入环境变量
        let envJsonString: String
        if let json = try? PTFoundation.jsonEncoder.encode(object.variables),
           let str = String(data: json, encoding: .utf8)
        {
            envJsonString = str
        } else {
            envJsonString = "{}"
        }

        // 合成执行内容
        let execs = String(format: PTJavaScriptFormatter, envJsonString, object.code)

        // 执行并获取返回数据
        let jsResult = executeWithTimeoutWatched(context: context, code: execs, timeout: object.timeout)
        // 检查是否超时
        if jsResult.timeout {
            return .init(didSucceed: false,
                         error: "JSEngine reports timeout during execution",
                         value: [
                             "ExecExitCode": "-10000",
                             "ExecError": "JSEngine reports timeout during execution",
                         ])
        }

        // 处理不正确的返回内容
        guard let rawRecipe = jsResult.value?.toObject() as? [String: Any] else {
            return .init(didSucceed: false,
                         error: "JSEngine returns invalid values",
                         value: [
                             "ExecExitCode": "-10001",
                             "ExecError": "JSEngine returns invalid values",
                         ])
        }

        // 处理返回值
        var returnedVariables = [String: String]()
        if let recipeValue = rawRecipe["value"] as? [String: Any] {
            for (key, value) in recipeValue {
                if let value = value as? String {
                    returnedVariables[key] = value
                } else if let value = value as? Int {
                    returnedVariables[key] = String(value)
                } else if let value = value as? Double {
                    returnedVariables[key] = String(value)
                } else if let value = value as? Float {
                    returnedVariables[key] = String(value)
                } else if let value = value as? Bool {
                    returnedVariables[key] = String(value)
                }
            }
        }

        // 有错误返回失败
        if let error = getError {
            PTLog.shared.join(self, "evaluate script failed with reason \(error)", level: .warning)
            PTLog.shared.join(self, "\(object.code)", level: .warning)
            return .init(didSucceed: false, error: error, value: returnedVariables)
        }

        // 退出代码留给用户判断吧 执行成功不代表返回值一定是0啊
        // TODO: 写入文档
        if let code = rawRecipe["code"] as? Int {
            returnedVariables["ExecExitCode"] = String(code)
        } else {
            returnedVariables["ExecExitCode"] = "0" // 保证有返回值
        }

        // 有自定义错误也返回失败
        if let error = rawRecipe["error"] as? String, error.count > 0 {
            returnedVariables["ExecError"] = String(error)
            return .init(didSucceed: false, error: error, value: returnedVariables)
        }

        // 终于成功了
        return .init(didSucceed: true, error: nil, value: returnedVariables)
    }
}
