//
//  FunctionSet+SSH.swift
//  PTFoundation
//
//  Created by Lakr Aream on 12/13/20.
//

import Foundation
import NMSSH

/// SSH 方法集
public class PTServerSSHLinuxSelectors: PTServerAllocationSelectors {
    /// 共用集合
    public static let shared = PTServerSSHLinuxSelectors()
    /// 不允许外部初始化
    override internal required init() {}

    /// 连接句柄 简易类型擦除
    public struct PTSSHConnection {
        public let representedConnection: NMSSHSession
        public let springLoadedQueue: DispatchQueue
        init(connection: NMSSHSession, queue: DispatchQueue) {
            representedConnection = connection
            springLoadedQueue = queue
        }
    }

    /// 脚本集合
    /// 注意脚本以空格开头
    internal let outputSeparator = "[*******]"
    internal enum ScriptCollection: String, CaseIterable {
        case obtainProcessInfo =
            """
             /bin/cat /proc/stat && /bin/sleep 1 && echo '[*******]' && /bin/cat /proc/stat
            """
        case obtainMemoryInfo =
            """
             /bin/cat /proc/meminfo
            """
        case obtainFileSystemInfo =
            """
             /bin/df -B1
            """
        case obtainHostname =
            """
             /bin/hostname -f
            """
        case obtainUptime =
            """
             /bin/cat /proc/uptime
            """
        case obtainLoadavg =
            """
             /bin/cat /proc/loadavg
            """
        case obtainRelease =
            """
             /bin/cat /etc/os-release
            """
        case obtainNetworkInfo =
            """
             /bin/cat /proc/net/dev && /bin/sleep 1 && echo '[*******]' && /bin/cat /proc/net/dev
            """
    }

    /// 用于构建传递参数
    internal struct SystemLoadInternal {
        var runningProcess: Int = 0
        var totalProcess: Int = 0
        var load1avg: Float = 0
        var load5avg: Float = 0
        var load15avg: Float = 0
    }

    /// 连接凭证
    public struct PTSSHConnectionCandidate {
        let host: String
        let port: Int32
        let user: String
        let pass: String
        let keypass: String
        let treatPassAsKey: Bool
        internal init(host: String,
                      port: Int32,
                      user: String,
                      pass: String,
                      keypass: String,
                      treatPassAsKey: Bool)
        {
            self.host = host
            self.port = port
            self.user = user
            self.pass = pass
            self.keypass = keypass
            self.treatPassAsKey = treatPassAsKey
        }
    }

    /// 获取识别字符串 一般用于储存
    /// - Returns: 识别代号
    override
    public func obtainIdentity() -> String {
        String(describing: self)
    }

    /// 初始化连接
    /// - Parameter server: 服务器对象
    /// - Returns: 连接凭证 PTSSHConnectionCandidate
    override
    public func setupConnection(withServer server: PTServerManager.Server) -> Any? {
        guard let account = PTAccountManager.shared.retrieveAccountWith(key: server.accountDescriptor) else {
            return nil
        }

        switch account.type {
        case .secureShellWithPassword:
            guard let accessObject = account.obtainDecryptedObject() else {
                return nil
            }
            return PTSSHConnectionCandidate(host: server.host, port: server.port,
                                            user: accessObject.account, pass: accessObject.key, keypass: "",
                                            treatPassAsKey: false)
        case .secureShellWithKey:
            guard let accessObject = account.obtainDecryptedObject() else {
                return nil
            }
            guard let attach = accessObject.representedObject,
                  let keyStr = String(data: attach, encoding: .utf8)
            else {
                return nil
            }
            return PTSSHConnectionCandidate(host: server.host, port: server.port,
                                            user: accessObject.account, pass: keyStr, keypass: accessObject.key,
                                            treatPassAsKey: true)
        }
    }

    /// 获取用户名
    /// - Parameter candidate: 连接凭证 PTSSHConnectionCandidate
    /// - Returns: 用户名
    public func getUsername(withCandidate candidate: Any) -> String? {
        guard let ticket = candidate as? PTSSHConnectionCandidate else {
            return nil
        }
        return ticket.user
    }

    /// 获取密钥
    /// - Parameter candidate: 连接凭证 PTSSHConnectionCandidate
    /// - Returns: 密钥字符串
    public func getKeyFileString(withCandidate candidate: Any) -> String? {
        guard let ticket = candidate as? PTSSHConnectionCandidate else {
            return nil
        }
        if ticket.treatPassAsKey {
            return ticket.pass
        }
        return nil
    }

    /// 连接
    /// - Parameter candidate: 连接凭证 PTSSHConnectionCandidate
    /// - Returns: 连接的句柄 和 错误字符串 如果有
    public typealias PTSSHConnectionAttempt = (Any?, String?)
    override
    public func connect(withCandidate candidate: Any) -> PTSSHConnectionAttempt {
        guard let ticket = candidate as? PTSSHConnectionCandidate else {
            return (nil, "[SSH] Undefined/Unimplemented authenticate ticket type: \(candidate.self)")
        }
        let queue = DispatchQueue(label: "wiki.qaq.libssh2.serial.\(UUID().uuidString)")
        let sem = DispatchSemaphore(value: 0)
        var ret: PTSSHConnectionAttempt = (nil, nil)
        queue.sync {
            defer { sem.signal() }
            let ssh = NMSSHSession(host: ticket.host, port: Int(ticket.port), andUsername: ticket.user)
            ssh.connect()
            if !ssh.isConnected {
                ret = (nil, "[SSH] failed to connect")
                return
            }
            if ticket.treatPassAsKey {
                ssh.authenticateBy(inMemoryPublicKey: nil, privateKey: ticket.pass, andPassword: ticket.keypass)
            } else {
                ssh.authenticate(byPassword: ticket.pass)
            }
            if !ssh.isAuthorized {
                ret = (nil, "[SSH] failed to authorize")
                return
            }
            ret = (PTSSHConnection(connection: ssh, queue: queue), nil)
        }
        let _ = sem.wait(wallTimeout: .now() + 30)
        return ret
    }

    /// 断开连接
    /// - Parameter object: 连接句柄 PTSSHConnection
    override
    public func disconnect(withConnection connection: Any) {
        guard let object = connection as? PTSSHConnection else {
            PTLog.shared.join(self,
                              "invalid connection object feeded to execuotr, requires PTSSHConnection",
                              level: .error)
            return
        }
        let sem = DispatchSemaphore(value: 0)
        object.springLoadedQueue.sync {
            object.representedConnection.disconnect()
            sem.signal()
        }
        let _ = sem.wait(wallTimeout: .now() + 1)
    }

    /// 获取远端服务器信息
    /// - Parameters:
    /// - Parameter connection: 连接句柄 PTSSHConnection
    ///   - command: 脚本
    /// - Returns: 执行输出
    internal func downloadResultFrom(withConnection connection: Any, command: ScriptCollection) -> String? {
        guard let object = connection as? PTSSHConnection else {
            PTLog.shared.join(self,
                              "invalid connection object feeded to execuotr, requires PTSSHConnection",
                              level: .error)
            return nil
        }
        
        guard (
            object.representedConnection.isConnected
                && object.representedConnection.isAuthorized
        ) else {
            PTLog.shared.join(self,
                              "connection broken, cancel request",
                              level: .error)
            return nil
        }

        var result: String? = nil
        let sem = DispatchSemaphore(value: 0)
        object.springLoadedQueue.sync {
            result = object.representedConnection.channel.execute(command.rawValue, error: nil)
            sem.signal()
        }
        let _ = sem.wait(wallTimeout: .now() + 30)
        if result?.count ?? 0 < 1 { result = nil }
        return result
    }

    /// 获取服务器处理器信息
    /// - Parameter connection: 连接句柄 PTSSHConnection
    /// - Returns: 处理器信息
    override
    public func obtainServerProcessInfo(withConnection connection: Any) -> PTServerManager.ServerProcessInfo {
        guard let intake = downloadResultFrom(withConnection: connection, command: .obtainProcessInfo)
        else {
            PTLog.shared.join(self,
                              "failed to capture info from remote proc file system",
                              level: .error)
            return .init()
        }

        return buildServerProcessInfo(intake: intake)
    }

    /// 构建服务器处理器信息
    /// - Parameter raw: 执行脚本的输出对象
    /// - Returns: 处理器信息
    internal func buildServerProcessInfo(intake: String) -> PTServerManager.ServerProcessInfo {
        let sep = intake.components(separatedBy: outputSeparator)
        if sep.count != 2 {
            PTLog.shared.join(self,
                              "captured info from remote proc file system is invalid",
                              level: .error)
            return .init()
        }
        let priv = sep[0]
        let curr = sep[1]

        func buildUp(raw: String) -> (PTServerManager.ServerProcessStatus?, [String: PTServerManager.ServerProcessStatus]) {
            var result = [String: PTServerManager.ServerProcessStatus]()
            var summary: PTServerManager.ServerProcessStatus?
            for line in raw.components(separatedBy: "\n") where line.hasPrefix("cpu") {
                var line = line
                while line.contains("  ") {
                    line = line.replacingOccurrences(of: "  ", with: " ")
                }
                let cut = line.components(separatedBy: " ")
                if cut.count != 11 {
                    PTLog.shared.join(self,
                                      "information from remote system failed to match data set",
                                      level: .error)
                    PTLog.shared.join(self,
                                      "* \(line)",
                                      level: .error)
                    continue
                }
                let info = PTServerManager.ServerProcessStatus(user: Float(cut[1]) ?? 0,
                                                               nice: Float(cut[2]) ?? 0,
                                                               system: Float(cut[3]) ?? 0,
                                                               idle: Float(cut[4]) ?? 0,
                                                               iowait: Float(cut[5]) ?? 0,
                                                               irq: Float(cut[6]) ?? 0,
                                                               softIrq: Float(cut[7]) ?? 0,
                                                               steal: Float(cut[8]) ?? 0,
                                                               guest: Float(cut[9]) ?? 0)
                if cut[0] == "cpu" {
                    summary = info
                    continue
                }
                if result[cut[0]] != nil {
                    PTLog.shared.join(self,
                                      "information from remote system is broken",
                                      level: .error)
                    return (nil, [:])
                }
                result[cut[0]] = info
            }
            return (summary, result)
        }

        let resultPriv = buildUp(raw: priv)
        let resultCurr = buildUp(raw: curr)

        guard let privSum = resultPriv.0 else {
            PTLog.shared.join(self,
                              "captured info from remote proc file system is invalid",
                              level: .error)
            return .init()
        }
        let privAll = resultPriv.1
        guard let currSum = resultCurr.0 else {
            PTLog.shared.join(self,
                              "captured info from remote proc file system is invalid",
                              level: .error)
            return .init()
        }
        let currAll = resultCurr.1

        func calculateInfo(priv: PTServerManager.ServerProcessStatus,
                           curr: PTServerManager.ServerProcessStatus)
            -> PTServerManager.ServerProcessInfoCalculatedElement
        {
            let preAll = priv.user + priv.nice + priv.system + priv.idle + priv.iowait + priv.irq + priv.softIrq + priv.steal + priv.guest
            let nowAll = curr.user + curr.nice + curr.system + curr.idle + curr.iowait + curr.irq + curr.softIrq + curr.steal + curr.guest

            let total = nowAll - preAll
            let privUsedTotal = priv.user + priv.nice + priv.system + priv.iowait
            let currUsedTotal = curr.user + curr.nice + curr.system + curr.iowait

            return PTServerManager.ServerProcessInfoCalculatedElement(system: (curr.system - priv.system) / total * 100,
                                                                      user: (curr.user - priv.user) / total * 100,
                                                                      iowait: (curr.iowait - priv.iowait) / total * 100,
                                                                      nice: (curr.nice - priv.nice) / total * 100,
                                                                      sum: (currUsedTotal - privUsedTotal) / total * 100)
        }

        let sumInit: PTServerManager.ServerProcessInfoCalculatedElement = calculateInfo(priv: privSum, curr: currSum)
        var resultPerCore = [String: PTServerManager.ServerProcessInfoCalculatedElement]()

        for (key, priv) in privAll {
            if let curr = currAll[key] {
                resultPerCore[key] = calculateInfo(priv: priv, curr: curr)
            } else {
                PTLog.shared.join(self,
                                  "captured info from remote proc file system is invalid",
                                  level: .error)
                return .init()
            }
        }

        return PTServerManager.ServerProcessInfo(summary: sumInit, cores: resultPerCore)
    }

    /// 获取服务器内存信息
    /// - Parameter connection: 连接句柄 PTSSHConnection
    /// - Returns: 内存信息
    override
    public func obtainMemoryInfo(withConnection connection: Any) -> PTServerManager.ServerMemoryInfo {
        guard let intake = downloadResultFrom(withConnection: connection, command: .obtainMemoryInfo)
        else {
            PTLog.shared.join(self,
                              "failed to capture info from remote proc file system",
                              level: .error)
            return .init()
        }
        return buildMemoryInfo(intake: intake)
    }

    /// 构建服务器内存信息
    /// - Parameter raw: 执行脚本的输出对象
    /// - Returns: 内存信息
    internal func buildMemoryInfo(intake: String) -> PTServerManager.ServerMemoryInfo {
        var info = [String: Float]()
        for line in intake.components(separatedBy: "\n") where line.count > 0 {
            var line = line
            while line.contains("  ") {
                line = line.replacingOccurrences(of: "  ", with: " ")
            }
            line = line.replacingOccurrences(of: ":", with: "")
            let cut = line.components(separatedBy: " ")
            switch cut.count {
            case 2:
                continue
            case 3:
                if cut[2].uppercased() == "KB" {
                    info[cut[0].uppercased()] = Float(cut[1])
                }
            default:
                PTLog.shared.join(self, "remote memory info does not match to known [\(line)]", level: .verbose)
                continue
            }
        }
        return PTServerManager.ServerMemoryInfo(total: info["MemTotal".uppercased()] ?? 0,
                                                free: info["MemFree".uppercased()] ?? 0,
                                                buffers: info["Buffers".uppercased()] ?? 0,
                                                cached: info["Cached".uppercased()] ?? 0,
                                                swapTotal: info["SwapTotal".uppercased()] ?? 0,
                                                swapFree: info["SwapFree".uppercased()] ?? 0)
    }

    /// 获取服务器磁盘信息
    /// - Parameter connection: 连接句柄 PTSSHConnection
    /// - Returns: 磁盘信息
    override
    public func obtainServerFileSystemInfo(withConnection connection: Any) -> [PTServerManager.ServerFileSystemInfo] {
        guard let intake = downloadResultFrom(withConnection: connection, command: .obtainFileSystemInfo)
        else {
            PTLog.shared.join(self,
                              "failed to capture info from remote system",
                              level: .error)
            return []
        }
        return buildServerFileSystemInfo(intake: intake)
    }

    /// 构建服务器磁盘信息
    /// - Parameter raw: 执行脚本的输出对象
    /// - Returns: 磁盘信息
    internal func buildServerFileSystemInfo(intake: String) -> [PTServerManager.ServerFileSystemInfo] {
        var result = [PTServerManager.ServerFileSystemInfo]()
        for line in intake.components(separatedBy: "\n").dropFirst() where line.count > 0 {
            var line = line
            while line.contains("  ") {
                line = line.replacingOccurrences(of: "  ", with: " ")
            }
            let cut = line.components(separatedBy: " ")
            if cut.count != 6 {
                PTLog.shared.join(self,
                                  "remote file system info does not match to known [\(line)]",
                                  level: .verbose)
                continue
            }
            if cut[2] == "0" || cut[3] == "0" {
                // 忽略 Used = 0 || Available = 0 的文件系统 这应该不是真实的文件系统
                continue
            }
            let free = Int(cut[3]) ?? -1
            let used = Int(cut[2]) ?? -1
            if free < 0 || used < 0 {
                continue
            }
            result.append(PTServerManager.ServerFileSystemInfo(mountPoint: cut[5], free: free, used: used))
        }
        return result
    }

    /// 获取服务器系统信息
    /// - Parameter connection: 连接句柄 PTSSHConnection
    /// - Returns: 系统信息
    override
    public func obtainSystemInfo(withConnection connection: Any) -> PTServerManager.ServerSystemInfo {
        var hostname: String = "Unknown Host Name"
        if let intake = downloadResultFrom(withConnection: connection, command: .obtainHostname) {
            hostname = buildHostname(intake: intake)
        }

        var uptime: Int = 0
        if let intake = downloadResultFrom(withConnection: connection, command: .obtainUptime) {
            uptime = buildUptime(intake: intake)
        }

        var runningProcess: Int = 0
        var totalProcess: Int = 0
        var load1avg: Float = 0
        var load5avg: Float = 0
        var load15avg: Float = 0
        if let intake = downloadResultFrom(withConnection: connection, command: .obtainLoadavg) {
            let get = buildLoadStatus(intake: intake)
            runningProcess = get.runningProcess
            totalProcess = get.totalProcess
            load1avg = get.load1avg
            load5avg = get.load5avg
            load15avg = get.load15avg
        }

        var release: String = ""
        if let intake = downloadResultFrom(withConnection: connection, command: .obtainRelease) {
            release = buildReleaseName(intake: intake)
        }

        return .init(release: release,
                     uptimeInSec: uptime,
                     hostname: hostname,
                     runningProcs: runningProcess,
                     totalProcs: totalProcess,
                     load1: load1avg,
                     load5: load5avg,
                     load15: load15avg)
    }

    /// 构建服务器主机名
    /// - Parameter raw: 执行脚本的输出对象
    /// - Returns: 主机名称字符串
    internal func buildHostname(intake: String) -> String {
        intake.replacingOccurrences(of: "\n", with: "")
    }

    /// 构建服务器运行时间
    /// - Parameter raw: 执行脚本的输出对象
    /// - Returns: 运行时间
    internal func buildUptime(intake: String) -> Int {
        let get = intake
        guard let ans = Double(get
            .components(separatedBy: " ")
            .first ?? "")
        else {
            return 0
        }
        if ans < Double(Int.min + 5) || ans > Double(Int.max - 5) {
            return 0
        }
        return Int(ans)
    }

    /// 构建服务器负载信息
    /// - Parameter raw: 执行脚本的输出对象
    /// - Returns: 负载信息
    internal func buildLoadStatus(intake: String) -> SystemLoadInternal {
        var ret = SystemLoadInternal()
        var get = intake
        while get.contains("  ") {
            get = get.replacingOccurrences(of: "  ", with: " ")
        }
        let cut = get.components(separatedBy: " ")
        if cut.count != 5 {
            PTLog.shared.join(self,
                              "remote loadavg info does not match to known [\(get)]",
                              level: .verbose)
        } else {
            if let l1 = Float(cut[0]), l1 != .infinity { ret.load1avg = l1 } else { return .init() }
            if let l5 = Float(cut[1]), l5 != .infinity { ret.load5avg = l5 } else { return .init() }
            if let l15 = Float(cut[2]), l15 != .infinity { ret.load15avg = l15 } else { return .init() }
            let process = cut[3].components(separatedBy: "/")
            if process.count == 2,
               let running = Int(process[0]),
               let total = Int(process[1])
            {
                ret.runningProcess = running
                ret.totalProcess = total
            } else {
                return .init()
            }
        }
        return ret
    }

    /// 构建服务器发行版名称
    /// - Parameter raw: 执行脚本的输出对象
    /// - Returns: 名称
    internal func buildReleaseName(intake: String) -> String {
        var release: String = ""
        var pretty: String?
        var name: String?
        for item in intake.components(separatedBy: "\n") {
            if item.hasPrefix("PRETTY_NAME=") {
                pretty = String(item.dropFirst("PRETTY_NAME=".count))
                break
            }
            if item.hasPrefix("NAME=") {
                name = String(item.dropFirst("NAME=".count))
            }
        }
        if let name = pretty {
            if
                (name.hasPrefix("\"") || name.hasPrefix("\"")) ||
                (name.hasSuffix("'") || name.hasSuffix("'")),
                name.count > 2
            {
                release = String(name.dropFirst().dropLast())
            } else {
                release = name
            }
        } else {
            if let name = name {
                if
                    (name.hasPrefix("\"") || name.hasPrefix("\"")) ||
                    (name.hasSuffix("'") || name.hasSuffix("'")),
                    name.count > 2
                {
                    release = String(name.dropFirst().dropLast())
                } else {
                    release = name
                }
            } else {
                release = "Generic Linux"
            }
        }
        return release
    }

    /// 获取服务器网络信息
    /// - Parameter connection: 连接句柄 PTSSHConnection
    /// - Returns: 网络信息
    override
    public func obtainServerNetworkInfo(withConnection connection: Any) -> [PTServerManager.ServerNetworkInfo] {
        guard let intake = downloadResultFrom(withConnection: connection, command: .obtainNetworkInfo)
        else {
            PTLog.shared.join(self,
                              "failed to capture info from remote proc file system",
                              level: .error)
            return .init()
        }
        return buildServerNetworkInfo(intake: intake)
    }

    /// 构建服务器网络信息
    /// - Parameter raw: 执行脚本的输出对象
    /// - Returns: 网络信息
    internal func buildServerNetworkInfo(intake: String) -> [PTServerManager.ServerNetworkInfo] {
        let sep = intake.components(separatedBy: outputSeparator)
        if sep.count != 2 {
            PTLog.shared.join(self, "captured info from remote proc file system is invalid", level: .error)
            return .init()
        }
        let priv = sep[0]
        let curr = sep[1]

        typealias RxTxPair = (Int, Int)

        func build(str: String) -> [String: RxTxPair] {
            var result = [String: RxTxPair]()
            go: for item in str.components(separatedBy: "\n") where item.contains(":") {
                let sepName = item.components(separatedBy: ":")
                if sepName.count != 2 {
                    continue go
                }
                guard var key = sepName.first,
                      var payload = sepName.last
                else {
                    continue go
                }
                while key.hasPrefix(" ") {
                    key.removeFirst()
                }
                while key.hasSuffix(" ") {
                    key.removeLast()
                }
                while payload.contains("  ") {
                    payload = payload.replacingOccurrences(of: "  ", with: " ")
                }
                while payload.hasPrefix(" ") {
                    payload.removeFirst()
                }
                while payload.hasSuffix(" ") {
                    payload.removeLast()
                }
                let split = payload.components(separatedBy: " ")
                if split.count < 10 {
                    continue go
                }
                // 0     1       2    3    4    5     6          7
                // bytes packets errs drop fifo frame compressed multicast
                // 8     9       10   11   12   13    14      15
                // bytes packets errs drop fifo colls carrier compressed
                guard let rxBytes = Int(split[0]),
                      let txBytes = Int(split[8])
                else {
                    continue go
                }
                if result[key] != nil {
                    result.removeValue(forKey: key)
                    continue
                }
                result[key] = (rxBytes, txBytes)
            }
            return result
        }

        let getPriv = build(str: priv)
        let getCurr = build(str: curr)
        var result = [PTServerManager.ServerNetworkInfo]()
        for item in getPriv {
            if let target = getCurr[item.key] {
                let rxIncrease = target.0 - item.value.0
                let txIncrease = target.1 - item.value.1
                if rxIncrease < 0 || txIncrease < 0 {
                    continue
                }
                result.append(PTServerManager.ServerNetworkInfo(device: item.key, rxBytesPerSec: rxIncrease, txBytesPerSec: txIncrease))
            }
        }

        return result
    }

    public typealias OutputStreamBlock = (String) -> Void
    public typealias ShouldTerminateBlock = () -> (Bool)

    /// 执行脚本
    /// - Parameters:
    ///   - connection: 连接句柄 PTSSHConnection
    ///   - script: 脚本字符串
    ///   - requestPty: 使用模拟终端 使用模拟终端可以在断开连接时终止程序
    ///   - output: 输出流
    ///   - terminate: 是否需要终止
    ///   - withEnvironment: 执行环境
    /// - Returns: 退出状态
    override
    public func executeScript(withConnection connection: Any,
                              script: String,
                              requestPty: Bool,
                              withEnvironment: [String: String],
                              output: OutputStreamBlock?,
                              terminate: ShouldTerminateBlock?) -> Int?
    {
        guard let object = connection as? PTSSHConnection else {
            PTLog.shared.join(self, "invalid connection object feeded to executor, requires PTSSHConnection", level: .critical)
            return nil
        }
        
        let sem = DispatchSemaphore(value: 0)
        var exitCode: Int32 = 0
        
        object.springLoadedQueue.sync {
            
            defer { sem.signal() }
            
            object.representedConnection.channel.requestPty = requestPty
            object.representedConnection.channel.ptyTerminalType = .xterm
            object.representedConnection.channel.environmentVariables = withEnvironment

            // 为了防止 return 的时候还在处理输出 会把输出搞 broken
            let dispatchLock = NSLock()
            var error: NSError?
            object.representedConnection.channel.execute(script,
                                                         error: &error,
                                                         timeout: 0,
                                                         output: { str in
                                                             dispatchLock.lock()
                                                             output?(str)
                                                             dispatchLock.unlock()
                                                         },
                                                         terminator: terminate,
                                                         exitCode: &exitCode)
            if let error = error {
                PTLog.shared.join("SSH",
                                  "error raised from script execution: \(error.localizedDescription)",
                                  level: .error)
            }
            dispatchLock.lock()
            dispatchLock.unlock()
        }
        
        let _ = sem.wait(wallTimeout: .now() + 30)
        
        return Int(exitCode)
    }
    
    /// 打开 Shell
    /// - Parameters:
    ///   - connection: 连接句柄 PTSSHConnection
    ///   - withEnvironment: 执行环境
    ///   - delegate: 方法委托
    /// - Returns: 退出状态
    override
    internal func openShell(withConnection connection: Any,
                            withEnvironment: [String: String],
                            delegate: Any?) -> Any?
    {
        openShellWithSSH(withConnection: connection,
                  withEnvironment: withEnvironment,
                  delegate: delegate as? NMSSHChannelDelegate)
    }

    /// 打开 Shell
    /// - Parameters:
    ///   - connection: 连接句柄 PTSSHConnection
    ///   - withEnvironment: 执行环境
    ///   - delegate: 方法委托
    /// - Returns: 退出状态
    public func openShellWithSSH(withConnection connection: Any,
                          withEnvironment: [String: String],
                          delegate: NMSSHChannelDelegate? = nil) -> PTSSHConnection?
    {
        guard let object = connection as? PTSSHConnection else {
            PTLog.shared.join(self,
                              "invalid connection object feeded to executor, requires PTSSHConnection",
                              level: .critical)
            return nil
        }
        let sem = DispatchSemaphore(value: 0)
        var booted = false
        
        object.springLoadedQueue.sync {
            defer { sem.signal() }
            
            object.representedConnection.channel.requestPty = true
            object.representedConnection.channel.ptyTerminalType = .xterm
            object.representedConnection.channel.delegate = delegate

            guard (
                object.representedConnection.isConnected
                    && object.representedConnection.isAuthorized
            ) else {
                PTLog.shared.join(self,
                                  "connection broken, cancel request",
                                  level: .error)
                return
            }
            
            do {
                try object.representedConnection.channel.startShell()
            } catch {
                PTLog.shared.join(self,
                                  "failed to open shell",
                                  level: .error)
                return
            }
            
            // after start shell
            object.representedConnection.channel.environmentVariables = withEnvironment
            
            booted = true
        }
        let _ = sem.wait(wallTimeout: .now() + 30)
        return booted ? object : nil
    }
}
