//
//  CodeClipGroup.swift
//  PTFoundation
//
//  Created by Lakr Aream on 1/19/21.
//

import Foundation

extension CodeClipGroup: Executable {
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
        // 回执
        var recipe = ExecuteRecipe()
        var outputSummary = ""
        var currentVars = env.payload
        // 执行每个脚本
        for (index, element) in payloads.enumerated() {
            output?("[\(name)] Executing CodeClip at Index: \(index)\n")
            let thisEnv = ExecuteEnvironment(payload: currentVars, server: env.server)
            let result = element.code.execute(fromEnvironment: thisEnv,
                                              output: output,
                                              terminate: terminate)
            recipe = result
            outputSummary.append(result.ouput)
            for item in result.vars {
                currentVars[item.key] = item.value
            }
            if recipe.code < 0 {
                return recipe
            }
        }
        recipe.vars = currentVars
        recipe.ouput = outputSummary
        return recipe
    }

    /// 异步执行
    /// - Parameters:
    ///   - env: 环境 包含变量和其他环境
    ///   - queue: 执行队列
    ///   - output: 输出流
    ///   - terminate: 循环检测需要终止嘛
    ///   - complete: 完成回掉
    public func execAsync(fromEnvironment env: ExecuteEnvironment? = nil,
                          queue: DispatchQueue = DispatchQueue.global(),
                          output: ((String) -> Void)? = nil,
                          terminate: (() -> (Bool))? = nil,
                          onComplete complete: @escaping (ExecuteRecipe) -> Void)
    {
        queue.async {
            let ret = self.execute(fromEnvironment: env, output: output, terminate: terminate)
            complete(ret)
        }
    }
}
