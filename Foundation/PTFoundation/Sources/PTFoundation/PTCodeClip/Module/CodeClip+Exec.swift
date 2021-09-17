//
//  CodeClip.swift
//  PTFoundation
//
//  Created by Lakr Aream on 1/19/21.
//

import Foundation

extension CodeClip: Executable {
    // MARK: API

    /// 执行 此处拦截输出添加到 result 并验证超时
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
        if executor == nil || target == nil {
            let bad = ExecuteRecipe(code: -2,
                                    ouput: "",
                                    vars: [:],
                                    error: "Clip Invalid")
            return bad
        }

        // 提交内容到 GCD
        var result = ExecuteRecipe()
        let sem = DispatchSemaphore(value: 0)
        DispatchQueue.global(qos: .background).async {
            defer { sem.signal() }
            // 执行内容
            switch (self.executor!, self.target!) {
            case (Executor.js, Target.local):
                // 本地执行
                result = execDispatchWithJavaScriptAtLocal(env: env)
            case (Executor.bash, Target.remote):
                // 远程执行
                let start = Date()
                result = execDispatchWithBashAtRemoteAndWait(env: env,
                                                             output: output,
                                                             terminate: { () -> (Bool) in
                                                                 // 结束执行
                                                                 if self.timeout > 0, -Int32(start.timeIntervalSinceNow) > self.timeout {
                                                                     debugPrint("Execution timeout, force terminate!")
                                                                     return true
                                                                 }
                                                                 return terminate?() ?? false
                                                             })
            default:
                // 无法执行
                result = .init(code: -12, ouput: "", vars: [:], error: "Invalid Execution Info")
            }
        }

        // 准备控制超时
        var timeout = Double(self.timeout)
        if timeout < 0 { timeout = 2_147_483_647 }
        let didTimeout = sem.wait(timeout: .now() + timeout)
        if didTimeout == .timedOut {
            // 超时就丢弃全部数据提前返回 注意线程安全
            let bad = ExecuteRecipe(code: -2,
                                    ouput: "",
                                    vars: [:],
                                    error: "timeout")
            return bad
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
    public func execAsync(fromEnvironment env: ExecuteEnvironment? = nil,
                          queue: DispatchQueue = DispatchQueue.global(),
                          output: ((String) -> Void)? = nil,
                          terminate: (() -> (Bool))? = nil,
                          onComplete complete: @escaping (ExecuteRecipe) -> Void)
    {
        // 提交到 GCD 去
        queue.async {
            let ret = self.execute(fromEnvironment: env, output: output, terminate: terminate)
            complete(ret)
        }
    }

    // MARK: INTERNAL EXEC

    /// 执行 JavaScript 内容
    /// - Parameter env: 环境 包含变量和其他环境
    /// - Returns: 执行回执
    private func execDispatchWithJavaScriptAtLocal(env: ExecuteEnvironment)
        -> ExecuteRecipe
    {
        let object = PTJavaScriptExecutor.JavaScript(vars: env.payload,
                                                     code: code,
                                                     timeout: Double(timeout))
        let ret = PTJavaScriptExecutor.shared.evaluate(scriptObject: object)
        var code = 0
        if let read = ret.value["ExecExitCode"],
           let val = Int(read)
        {
            code = val
        } else {
            if ret.didSucceed {
                code = 0
            } else {
                code = -1
            }
        }
        return .init(code: code, ouput: "", vars: ret.value, error: ret.error)
    }

    /// 执行远程脚本并等待
    /// - Parameters:
    ///   - env: 环境 包含变量和其他
    ///   - output: 输出流
    ///   - terminate: 循环检测需要终止嘛
    /// - Returns: 执行回执
    private func execDispatchWithBashAtRemoteAndWait(env: ExecuteEnvironment,
                                                     output: ((String) -> Void)?,
                                                     terminate: (() -> (Bool))?)
        -> ExecuteRecipe
    {
        
        // 准备执行内容
        var result = ExecuteRecipe()
        var env = env
        var script: String = code

        //  如果用户选择了原地替换脚本中的变量
        if PTFoundation.requestingUserDefault(forKey: .shouldReplaceScriptEnvironment, defaultValue: false) {
            // TODO: DOC
            // 直接替换脚本内的变量 $.varName.$ 带着 $..$ 一起替换
            // example: echo $.myName.$ -> echo "Lakr Aream"
            // where->: myName = "Lakr Aream"
            for item in env.payload {
                let result = script.replacingOccurrences(of: "$.\(item.key).$", with: "\(item.value)")
                script = result
            }
            debugPrint(script)
            // 清空
            env.payload = [:]
        }
        
        // 如果设置内没有启用环境变量
        if !PTFoundation.requestingUserDefault(forKey: .allowEnvironmentVariableInScript, defaultValue: true) {
            env.payload = [:]
        }

        // 准备连接到服务器
        guard let serverDescriptor = env.server,
              let server = PTServerManager.shared.obtainServer(withKey: serverDescriptor),
              let account = PTAccountManager.shared.retrieveAccountWith(key: server.accountDescriptor)
        else {
            result.code = -13
            result.error = "Invalid Server Info"
            return result
        }
        let functions = account.selectors
        guard let connectionCandidate = functions.setupConnection(withServer: server) else {
            result.code = -14
            result.error = "Connection Setup Failed"
            return result
        }
        let connectionPass = functions.connect(withCandidate: connectionCandidate)
        guard let connection = connectionPass.0 else {
            result.code = -15
            result.error = connectionPass.1
            return result
        }

        // 初始化执行
        let lock = NSLock()
        var buffer = ""
        var retVar: [String: String] = [:]
        let block = { (str: String) in
            lock.lock()
            buffer.append(str)
            output?(str)
            lock.unlock()
        }

        // 提交执行
        guard let execResult = functions.executeScript(withConnection: connection,
                                                       script: script,
                                                       requestPty: true,
                                                       withEnvironment: env.payload,
                                                       output: block,
                                                       terminate: terminate)
        else {
            result.code = -16
            result.error = "Broken Payload"
            return result
        }
        result.code = execResult
        result.ouput = buffer

        let resultVarBuilder = buffer
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: "\n\n", with: "\n")
            .components(separatedBy: "\n")
        for line in resultVarBuilder where line.count > 0 {
            let sep = line.components(separatedBy: " ")
            // 如果检测到了 PILLOWTALK_SET_VAR
            if line.hasPrefix("PILLOWTALK_SET_VAR "), sep.count >= 3 {
                let key = sep[1]
                var value = ""
                for item in sep.dropFirst().dropFirst() {
                    value += "\(item) "
                }
                while value.hasSuffix(" ") {
                    value.removeLast()
                }
                // 读取设置的变量
                retVar[key] = value
            }
        }
        result.vars = retVar
        
        return result
    }
}
