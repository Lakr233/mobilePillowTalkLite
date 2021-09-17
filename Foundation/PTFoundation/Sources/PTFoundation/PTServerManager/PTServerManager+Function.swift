//
//  PTServerManager.swift
//  PTFoundation
//
//  Created by Lakr Aream on 12/14/20.
//

import Foundation

public extension PTServerManager {
    /// 注册服务器实例 上执行锁
    /// - Parameters:
    ///   - object: 被注册对象
    ///   - onRecoverableError: 在遇到如服务器重复但id不同时询问策略
    /// - Returns: 注册成功返回服务器ID 反之返回nil
    typealias RegistrationInterruptBlock = ((RegistrationInterrupt, Any?) -> (RegistrationSolution))
    @discardableResult
    func createServer(withObject object: Server,
                      onRecoverableError: RegistrationInterruptBlock? = nil) -> ServerDescriptor?
    {
        // 注册还是上锁比较好
        executionLock.lock()
        let copied = serverContainer
        executionLock.unlock()

        // 检查识别码是否重复
        if copied[object.uuid] != nil {
            PTLog.shared.join(self,
                              "registration aborted due to udid collision",
                              level: .error)
            return nil
        }
        // 检查主机地址和端口是否重复
        guard let account = PTAccountManager.shared.retrieveAccountWith(key: object.accountDescriptor) else {
            PTLog.shared.join(self,
                              "registration aborted due to empty account provided",
                              level: .error)
            return nil
        }
        if let duplicated = locateServerIfExists(withHost: object.host,
                                                 andPort: object.port,
                                                 andUsername: account.obtainDecryptedObject()?.account ?? "")
        {
            if let interruptSolution = onRecoverableError {
                // 发起中断请求
                let result = interruptSolution(RegistrationInterrupt.duplicated, duplicated)
                if result != .continueRegistration {
                    // 取消注册
                    PTLog.shared.join(self,
                                      "requested registration abort on server \(object.uuid)",
                                      level: .warning)
                    return nil
                }
            } else {
                PTLog.shared.join(self,
                                  "registration aborted due to unhandled interrupt",
                                  level: .warning)
                return nil
            }
        }

        let serverObject = ServerObject(server: object)
        executionLock.lock()
        serverContainer[object.uuid] = serverObject
        executionLock.unlock()
        PTLog.shared.join(self,
                          "registering server \(object.uuid)",
                          level: .info)

        synchronizeObjects(triggeredByServer: object.uuid)
        return object.uuid
    }

    /// 根据地址和端口查找服务器 上读写锁
    /// - Parameters:
    ///   - host: 地址
    ///   - port: 端口
    /// - Returns: 服务器对象
    func locateServerIfExists(withHost host: String,
                              andPort port: Int32,
                              andUsername name: String) -> Server?
    {
        executionLock.lock()
        let copied = serverContainer
        executionLock.unlock()
        for (_, value) in copied {
            if value.server.host == host, value.server.port == port {
                // 检查用户名
                if let account = PTAccountManager.shared.retrieveAccountWith(key: value.server.accountDescriptor) {
                    if account.obtainDecryptedObject()?.account == name {
                        return value.server
                    }
                }
            }
        }
        return nil
    }

    /// 删除注册的服务器 上执行锁 同时删除所属账户对象
    /// - Parameter uuid: 服务器ID
    /// - Returns: 删除的服务器对象
    @discardableResult
    func removeServerFromRegisteredList(withKey uuid: ServerDescriptor) -> Server? {
        executionLock.lock()
        defer {
            executionLock.unlock()
            synchronizeObjects(triggeredByServer: uuid)
        }
        if let serverObject = serverContainer[uuid] {
            PTLog.shared.join(self,
                              "removing server \(uuid)",
                              level: .info)
            serverContainer.removeValue(forKey: uuid)
            PTAccountManager.shared.removeAccount(withKey: serverObject.server.accountDescriptor)
            return serverObject.server
        } else {
            PTLog.shared.join(self,
                              "the server being removed was not found \(uuid)",
                              level: .warning)
            return nil
        }
    }

    /// 从监视服务器列表中删除服务器 不会中断已经分发的RunLoop  上执行锁
    /// - Parameter uuid: 服务器ID
    func removeServerFromSupervisedList(withKey uuid: ServerDescriptor) {
        executionLock.lock()
        defer {
            executionLock.unlock()
            synchronizeObjects(triggeredByServer: uuid)
        }
        guard let serverObject = serverContainer[uuid] else {
            PTLog.shared.join(self,
                              "the server being un-supervised was not found \(uuid)",
                              level: .error)
            return
        }
        serverObject.server.supervisionTimeInterval = 0
        serverObject.supervised = false
    }

    /// 监视服务器
    /// - Parameters:
    ///   - uuid: 识别号
    ///   - interval: 时间间隔
    func superviseOnServer(withKey uuid: ServerDescriptor, interval: Int) {
        executionLock.lock()
        defer {
            executionLock.unlock()
            synchronizeObjects(triggeredByServer: uuid)
        }
        if interval <= 0 {
            PTLog.shared.join(self,
                              "invalid supervised interval \(interval) on \(uuid)",
                              level: .error)
            return
        }
        guard let serverObject = serverContainer[uuid] else {
            PTLog.shared.join(self,
                              "the server going to be supervised was not found \(uuid)",
                              level: .error)
            return
        }
        serverObject.server.supervisionTimeInterval = interval
        serverObject.supervised = true
        // 好像没必要清空他
//        serverObject.supervisionStatus = nil
    }

    /// 返回已注册服务器数量
    /// - Returns: Int
    func obtainRegisteredServerCount() -> Int {
        executionLock.lock()
        let copied = serverContainer
        executionLock.unlock()
        return copied.count
    }

    /// 返回正在监视的服务器数量
    /// - Returns: Int
    func obtainSupervisedServerCount() -> Int {
        executionLock.lock()
        let copied = serverContainer
        executionLock.unlock()
        return copied.filter { _, val -> Bool in
            val.supervised
        }.count
    }

    /// 返回已注册的服务器列表 上执行锁
    /// - Returns: 服务器对象数组
    func obtainServerList() -> [Server] {
        executionLock.lock()
        let copied = serverContainer
        executionLock.unlock()
        return copied.map { _, val -> Server in
            val.server
        }
    }

    /// 返回全部服务器栏目分组名称 未排序
    /// - Returns: 未排序栏目分组名称列表
    func obtainRegisteredServerSectionList() -> [String] {
        executionLock.lock()
        let copied = serverContainer
        executionLock.unlock()
        var ret = Set<String>()
        for (_, val) in copied {
            ret.insert(val.server.obtainSectionName())
        }
        return [String](ret)
    }

    /// 使用分组名字返回分组内的服务器列表 未排序
    /// - Parameter name: 分组名
    /// - Returns: 服务器列表
    func obtainServersWithinSection(name: String) -> [Server] {
        executionLock.lock()
        let copied = serverContainer
        executionLock.unlock()
        var ret = [Server]()
        for (_, val) in copied where val.server.obtainSectionName() == name {
            ret.append(val.server)
        }
        return ret
    }

    /// 返回被监视的服务器列表 上执行锁
    /// - Returns: 服务器对象数组
    func obtainSupervisedServerList() -> [Server] {
        executionLock.lock()
        let copied = serverContainer
        executionLock.unlock()
        var ret = [Server]()
        for (_, val) in copied where val.supervised {
            ret.append(val.server)
        }
        return ret
    }

    /// 用id查找已注册的服务器
    /// - Parameter uuid: id
    /// - Returns: 服务器 查询失败返回nil
    func obtainServer(withKey uuid: ServerDescriptor) -> Server? {
        executionLock.lock()
        let ret = serverContainer[uuid]?.server.copy()
        executionLock.unlock()
        return ret
    }

    /// 用id查找已注册的服务器的状态
    /// - Parameter uuid: id
    /// - Returns: 服务器 查询失败返回nil
    func obtainServerStatus(withKey uuid: ServerDescriptor) -> ServerStatus? {
        executionLock.lock()
        let ret = serverContainer[uuid]?.supervisionStatus
        executionLock.unlock()
        return ret
    }

    /// 检查服务器是否正在被监视
    /// - Parameter uuid: id
    /// - Returns: 是否被监视
    func isServerSupervised(withKey uuid: ServerDescriptor) -> Bool {
        executionLock.lock()
        let ret = serverContainer[uuid]?.supervised ?? false
        executionLock.unlock()
        return ret
    }

    /// 检查服务器是否正在更新状态信息
    /// - Parameter uuid: id
    /// - Returns: 是否正在更新
    func isServerInUpdate(withKey uuid: ServerDescriptor) -> Bool {
        executionLock.lock()
        let get = serverContainer[uuid]
        executionLock.unlock()
        return get?.supervisionStatus?.pendingUpdate ?? false
    }

    /// 返回服务器状态 如果不存在则选择是否立即拉取 拉去完成会写入主缓存
    /// - Parameter uuid: id
    /// - Parameter useCache: 是否使用缓存
    /// - Parameter acquireIfNeeded: 未找到数据时是否立即拉取数据并等待
    /// - Returns: 服务器信息
    func obtainServerStatusInfoAtomically(withKey uuid: ServerDescriptor,
                                          useCache: Bool,
                                          acquireIfNeeded: Bool) -> ServerInfo?
    {
        executionLock.lock()
        let copied = serverContainer
        executionLock.unlock()
        guard let serverObject = copied[uuid] else {
            PTLog.shared.join(self,
                              "the server being asked was not found \(uuid)",
                              level: .error)
            return nil
        }
        var ret: ServerInfo?
        if useCache {
            ret = serverObject.supervisionStatus?.information
        }
        if ret == nil, acquireIfNeeded {
            ret = serverSupervisionUpdateAtomically(fromServer: serverObject)
        }
        return ret
    }

    /// 立即更新被监视的服务器信息
    /// - Parameter server: 句柄
    func updateServerSupervisionInfoNow(withKey uuid: ServerDescriptor) {
        var qualified = true
        executionLock.lock()
        let copied = serverContainer
        if serverContainer[uuid]?.supervisionStatus?.pendingUpdate ?? false == true {
            qualified = false
        } else {
            var status = serverContainer[uuid]?.supervisionStatus
            if status == nil {
                status = .init(serverDescriptor: uuid)
            }
            status?.pendingUpdate = true
            serverContainer[uuid]?.supervisionStatus = status
        }
        executionLock.unlock()
        guard let serverObject = copied[uuid] else {
            PTLog.shared.join(self,
                              "the server being asked to update was not found \(uuid)",
                              level: .error)
            return
        }
        if !qualified {
            PTLog.shared.join(self,
                              "the server being asked to update is updating \(uuid)",
                              level: .error)
            return
        }
        PTNotificationCenter.shared.postNotification(withName: .ServerManager_ServerStatusUpdated, attachment: uuid)
        supervisionConcurrentQueue.async {
            self.serverSupervisionUpdateAtomically(fromServer: serverObject)
        }
    }

    /// 更新服务器对象内 tags 属性
    /// - Parameters:
    ///   - handler: 服务器句柄
    ///   - modify: 该 block 会传回 tags 属性 需要传入修改后的 tags (return modified)
    typealias ServerTagModificationBlock = ([Server.ServerTag: String]) -> ([Server.ServerTag: String])
    func updateTagsForServer(withKey uuid: String,
                             modify: ServerTagModificationBlock)
    {
        executionLock.lock()
        defer {
            executionLock.unlock()
            synchronizeObjects(triggeredByServer: uuid)
        }
        guard let serverObject = serverContainer[uuid] else {
            PTLog.shared.join(self,
                              "the server being asked to modify was not found \(uuid)",
                              level: .error)
            return
        }
        let tags = modify(serverObject.server.tags)
        serverObject.server.tags = tags
    }

    /// 获取正在刷新的队列数量
    /// - Returns: 数量
    func obtainAcquireInProgressCount() -> Int {
        executionLock.lock()
        let value = supervisionInProgressCount
        executionLock.unlock()
        return value
    }

    /// 获取服务器历史状态的记录
    ///   - id: 服务器识别码
    /// - Returns: 信息记录集
    func obtainStatusRecordForServer(serverDescriptor: PTServerManager.ServerDescriptor) -> [TimeInterval: ServerInfo] {
        guard let db = database else {
            PTLog.shared.join(self,
                              "SQL database connection lost",
                              level: .error)
            return [:]
        }
        var result: [TimeInterval: ServerInfo] = [:]
        do {
            for record in try db.prepare(PTServerManagerDatabaseTypes.table) {
                let identity = record[PTServerManagerDatabaseTypes.server]
                if identity != serverDescriptor {
                    continue
                }
                let status = record[PTServerManagerDatabaseTypes.status]
                if let data = status.data(using: .utf8),
                   let serverInfo = try? PTFoundation.jsonDecoder.decode(ServerInfo.self,
                                                                         from: data)
                {
                    result[record[PTServerManagerDatabaseTypes.timestamp]] = serverInfo
                }
            }
        } catch {
            PTLog.shared.join(self,
                              "database raised an error during prepare",
                              level: .error)
            return [:]
        }
        return result
    }

    /// 打开 shell 连接
    /// - Parameters:
    ///   - serverDescriptor: 服务器识别码
    ///   - withEnvironment: 执行环境
    ///   - withDelegate: 要求选择 delegate 目前是  [NMSSHChannelDelegate]
    /// - Returns: representedConnection [NMSSHChannel]
    func openShellConnection(onServer serverDescriptor: PTServerManager.ServerDescriptor,
                             withEnvironment: [String: String],
                             withDelegate: Any?) -> Any?
    {
        executionLock.lock()
        let read = serverContainer[serverDescriptor]
        executionLock.unlock()
        guard let server = read?.server else {
            PTLog.shared.join(self,
                              "shell request server not found",
                              level: .error)
            return nil
        }

        // 准备连接
        let accountDescriptor = server.accountDescriptor
        guard let account = PTAccountManager.shared.retrieveAccountWith(key: accountDescriptor) else {
            PTLog.shared.join(self,
                              "retrieve server account candidate failed",
                              level: .error)
            return nil
        }

        let function = account.selectors

        guard let connectionCandidate = function.setupConnection(withServer: server) else {
            PTLog.shared.join(self,
                              "retrieve server connection candidate failed",
                              level: .error)
            return nil
        }
        let connectionObject = function.connect(withCandidate: connectionCandidate)
        guard let connection = connectionObject.0 else {
            PTLog.shared.join(self,
                              "connection to server at \(server.host):\(server.port) failed with error \(connectionObject.1 ?? "unknown")",
                              level: .error)
            return nil
        }

        return function.openShell(withConnection: connection,
                                  withEnvironment: withEnvironment,
                                  delegate: withDelegate)
    }
}
