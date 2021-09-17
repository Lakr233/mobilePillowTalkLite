//
//  Checkpoint.swift
//  PTFoundation
//
//  Created by Lakr Aream on 1/19/21.
//

import Foundation

extension Checkpoint: Executable {
    /// 执行
    /// - Parameters:
    ///   - env: 环境 包含变量和其他环境
    ///   - output: 输出流
    ///   - terminate: 循环检测需要终止嘛
    /// - Returns: 执行回执
    @discardableResult
    public func execute(fromEnvironment env: ExecuteEnvironment? = nil,
                        output: ((String) -> Void)? = nil,
                        terminate: (() -> (Bool))? = nil)
        -> ExecuteRecipe
    {
        // 创建环境
        var env =
            env != nil
                ? env!
                : ExecuteEnvironment(payload: [:], server: nil)
        for (key, value) in PTFoundation.obtainExecutionEnvironment() {
            env.payload[key] = value
        }

        // 检查
        if env.server != nil {
            PTLog.shared.join(self,
                              "Executing Checkpoint does not allow any serverDescriptor in ExecuteEnvironment",
                              level: .error)
            #if DEBUG
                PTFoundation.runtimeErrorCall(.badExecutionLogic)
            #else
                return .init(code: -15, ouput: "", vars: [:], error: "Executing Checkpoint does not allow any serverDescriptor in ExecuteEnvironment")
            #endif
        }

        // 准备内容
        var result = ExecuteRecipe()
        var currentVars = env.payload

        for (index, step) in steps.enumerated() {
            output?("[\(name)] Executing Checkpoint at Index: \(index)")
            switch step.type {
            case .CodeClip:
                // 取得内容
                guard let code = PTCodeClipManager.shared.retrieveCodeClipWith(name: step.name, inSection: step.section) else {
                    result.code = -16
                    result.error = "Retrieve CodeClip Failed"
                    return result
                }
                // 决定服务器
                let server =
                    step.target != nil
                        ? step.target
                        : self.server
                let currentEnv = ExecuteEnvironment(payload: currentVars, server: server)
                // 执行内容
                let ret = code.execute(fromEnvironment: currentEnv, output: output, terminate: terminate)
                // 更新执行回执
                result = ret
                for item in ret.vars {
                    currentVars[item.key] = item.value
                }
                result.vars = currentVars
                // 开始检查这一步是否有效
                if result.code < 0 {
                    result.code = -1
                    result.error = "Execution interrupted via negative exit code"
                    return result
                }
                // 需求检查
                let validation = vaildateStep(retVal: ret, reqs: step.requirement)
                if !validation.0 {
                    result.code = -1
                    result.error = "Execution interrupted cause requirement(s) not met for this step: \(validation.1 ?? "Unknown Error")"
                    return result
                }
            case .CodeGroup:
                // 取得内容
                guard let code = PTCodeClipManager.shared.retrieveCodeClipGroupWith(name: step.name, inSection: step.section) else {
                    result.code = -16
                    result.error = "Execution Interrupted via Negative Exit Code or Requirements Not Match"
                    return result
                }
                // 决定服务器
                let server =
                    step.target != nil
                        ? step.target
                        : self.server
                let currentEnv = ExecuteEnvironment(payload: currentVars, server: server)
                // 执行内容
                let ret = code.execute(fromEnvironment: currentEnv, output: output, terminate: terminate)
                // 更新执行回执
                result = ret
                for item in ret.vars {
                    currentVars[item.key] = item.value
                }
                result.vars = currentVars
                // 开始检查这一步是否有效
                if result.code < 0 {
                    result.code = -1
                    result.error = "Execution interrupted via negative exit code"
                    return result
                }
                // 需求检查
                let validation = vaildateStep(retVal: ret, reqs: step.requirement)
                if !validation.0 {
                    result.code = -1
                    result.error = "Execution interrupted cause requirement(s) not met for this step: \(validation.1 ?? "Unknown Error")"
                    return result
                }
            }
        }
        let finalValidation = vaildateStep(retVal: result, reqs: finalRequirement)
        if !finalValidation.0 {
            result.code = -1
            result.error = "Final requirement(s) not met: \(finalValidation.1 ?? "Unknown Error")"
            return result
        }
        return result
    }

    /// 异步执行
    /// - Parameters:
    ///   - env: 环境 包含变量和其他环境
    ///   - queue: 执行队列
    ///   - output: 输出流
    ///   - terminate: 循环检测需要终止嘛
    ///   - complete: 完成回掉
    public func execAsync(fromEnvironment env: ExecuteEnvironment?,
                          queue: DispatchQueue,
                          output: ((String) -> Void)? = nil,
                          terminate: (() -> (Bool))? = nil,
                          onComplete complete: @escaping (ExecuteRecipe) -> Void)
    {
        queue.async {
            let ret = execute(fromEnvironment: env,
                              output: output,
                              terminate: terminate)
            complete(ret)
        }
    }

    /// 检查当前步骤是否合法
    /// - Parameters:
    ///   - retVal: 返回值列表
    ///   - reqs: 需求列表
    /// - Returns: 是否符合要求
    internal func vaildateStep(retVal: ExecuteRecipe, reqs: [Requirement]) -> (Bool, String?) {
        for item in reqs {
            let descriptor = "[\(item.key ?? "$NULL")] : \(item.type.rawValue) -> \(item.representedValue)"
            switch item.type {
            case .matchCaseInsensitive: // 匹配内容 忽略大小写
                guard let key = item.key, let read = retVal.vars[key] else {
                    return (false, descriptor)
                }
                if read.lowercased() != item.representedValue.lowercased() {
                    return (false, descriptor)
                }
            case .matchCaseSensitive: // 匹配内容 包含大小写
                guard let key = item.key, let read = retVal.vars[key] else {
                    return (false, descriptor)
                }
                if read != item.representedValue {
                    return (false, descriptor)
                }
            case .matchRegularExpression: // 正则表达式匹配
                guard let key = item.key, let read = retVal.vars[key] else {
                    return (false, descriptor)
                }
                let wholeRange = read.startIndex ..< read.endIndex
                guard let match = read.range(of: item.representedValue, options: .regularExpression) else {
                    return (false, descriptor)
                }
                if wholeRange != match {
                    return (false, descriptor)
                }
            case .matchNumberValue: // 将确认数据为数字并匹配数值
                guard let except = Float(item.representedValue),
                      let key = item.key, let read = retVal.vars[key],
                      let val = Float(read)
                else {
                    return (false, descriptor)
                }
                if except != val {
                    return (false, descriptor)
                }
            case .returnValue: // 返回值
                guard let val = Int(item.representedValue) else {
                    return (false, descriptor)
                }
                if retVal.code != val {
                    return (false, descriptor)
                }
            case .contains: // 包含
                guard let key = item.key, let read = retVal.vars[key] else {
                    return (false, descriptor)
                }
                if !read.contains(item.representedValue) {
                    return (false, descriptor)
                }
            }
        }
        return (true, nil)
    }
}
