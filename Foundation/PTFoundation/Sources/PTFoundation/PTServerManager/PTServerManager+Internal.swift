//
//  PTServerManager.swift
//  PTFoundation
//
//  Created by Lakr Aream on 12/14/20.
//

import Foundation

extension PTServerManager {
    /// 初始化 初始化完成以后就只写不读了
    /// - Parameter toDir: 可读写目录
    /// - Returns: 错误 如果有
    func initialization(toDir: URL, requireRunLoop: Bool) -> PTFoundation.InitializationError? {
        // 二次检查
        if PTFoundation.ensureDirExists(atLocation: toDir) != nil {
            return .filePermissionDenied
        }

        // 创建根储存
        baseLocation = toDir.appendingPathComponent(PTServerManager.StoreBase)
        if PTFoundation.ensureDirExists(atLocation: baseLocation) != nil {
            return .filePermissionDenied
        }

        // 注册的储存路径
        let path = baseLocation
            .appendingPathComponent("Registration")
            .appendingPathExtension("plist")

        // 如果文件存在就读取
        if FileManager.default.fileExists(atPath: path.path) {
            do {
                let read = try Data(contentsOf: path)
                if read.count > 0 {
                    let items = try PTFoundation.plistDecoder.decode([String: ServerObject].self, from: read)
                    serverContainer = items
                }
            } catch {
                PTLog.shared.join(self,
                                  "failed to load server registration status from file",
                                  level: .critical)
                return .filePermissionDenied
            }
        }

        // 重制更新状态
        for (_, value) in serverContainer {
            value.supervised = value.server.supervisionTimeInterval > 0
            value.supervisionStatus?.pendingUpdate = false
        }

        // 创建数据库
        if !ensureDatabaseTableExistsSucceed() {
            return .serverManagerDatabaseInitializationFailed
        }

        synchronizeObjects(triggeredByServer: nil)

        PTLog.shared.join(self,
                          "initialization reported \(serverContainer.count) server(s) registered",
                          level: .info)

        serverContainer.filter { _, val -> Bool in
            val.supervised
        }.forEach { _, val in
            PTLog.shared.join(self,
                              "supervision started for: \(val.server.obtainPossibleName())",
                              level: .info)
        }

        if requireRunLoop {
            initializeRunLoop()
        }

        return nil
    }

    /// 拉取服务器信息
    /// - Parameter server: 服务器对象
    /// - Returns: 信息结构体
    func acquireServerInfo(fromServer server: Server) -> ServerInfo? {
        executionLock.lock()
        supervisionInProgressCount += 1
        executionLock.unlock()
        defer {
            executionLock.lock()
            supervisionInProgressCount -= 1
            executionLock.unlock()
        }
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

        let start = Date()
        PTLog.shared.join(self,
                          "Updating server \(server.uuid) status dispatched \(Int(start.timeIntervalSince1970))",
                          level: .info)

        // will disconnect after return
        // will wait for it after dispatch
        defer {
            function.disconnect(withConnection: connection)
        }

        var processInfo: ServerProcessInfo?
        var memoryInfos: ServerMemoryInfo?
        var fileSystemInfos: [ServerFileSystemInfo]?
        var systemInfos: ServerSystemInfo?
        var networkInfos: [ServerNetworkInfo]?

        let group = DispatchGroup()
        let queue = DispatchQueue(label: "server.update.\(server.uuid)", attributes: .concurrent)

        group.enter()
        queue.async {
            // 本来想搞迸发的。。。
            // 结果直接 fatal 糊脸
            let ServerProcessInfos: ServerProcessInfo = function.obtainServerProcessInfo(withConnection: connection)
            processInfo = ServerProcessInfos
            let ServerMemoryInfos: ServerMemoryInfo = function.obtainMemoryInfo(withConnection: connection)
            memoryInfos = ServerMemoryInfos
            let ServerFileSystemInfos: [ServerFileSystemInfo] = function.obtainServerFileSystemInfo(withConnection: connection)
            fileSystemInfos = ServerFileSystemInfos
            let ServerSystemInfos: ServerSystemInfo = function.obtainSystemInfo(withConnection: connection)
            systemInfos = ServerSystemInfos
            let ServerNetworkInfos: [ServerNetworkInfo] = function.obtainServerNetworkInfo(withConnection: connection)
            networkInfos = ServerNetworkInfos
            group.leave()
        }

        // WallTimeout will keep track on the time that spent even if the app suspended
        let result = group.wait(wallTimeout: .now() + 18) // TODO: UserDefault
        if result == .timedOut {
            PTLog.shared.join(self,
                              "update process on server: \(server.uuid) failed with timeout wall reached",
                              level: .error)
            return nil
        }

        guard let pi = processInfo,
              let mi = memoryInfos,
              let fi = fileSystemInfos,
              let si = systemInfos,
              let ni = networkInfos
        else {
            PTLog.shared.join(self,
                              "update process on server: \(server.uuid) failed with at least one empty information returned from subprocess",
                              level: .error)
            return nil
        }
        
        if pi == ServerProcessInfo() && mi == ServerMemoryInfo() {
            PTLog.shared.join(self,
                              "update process on server: \(server.uuid) failed with too many broken information returned from subprocess",
                              level: .error)
            return nil
        }

        let information = ServerInfo(ServerProcessInfo: pi,
                                     ServerFileSystemInfo: fi,
                                     ServerMemoryInfo: mi,
                                     ServerSystemInfo: si,
                                     ServerNetworkInfo: ni)
        PTLog.shared.join(self,
                          "Updated server \(server.uuid) status in \(Int(Date().timeIntervalSince(start)))s  \(information.ServerSystemInfo.releaseName) <-> \(server.obtainPossibleName())",
                          level: .info)
        return information
    }

    func synchronizeObjects(triggeredByServer uuid: ServerDescriptor? = nil) {
        // 节流阀
        syncThrottle.throttle {
            // 合成撰写数据
            do {
                // 引用传递 encode 完成再解锁吧
                self.executionLock.lock()
                let copied = self.serverContainer
                let data = try PTFoundation.plistEncoder.encode(copied)
                self.executionLock.unlock()

                self.fileSyncLock.lock()
                try data.write(to: self.baseLocation
                    .appendingPathComponent("Registration")
                    .appendingPathExtension("plist"),
                    options: .atomic)
                self.fileSyncLock.unlock()
            } catch {
                self.fileSyncLock.unlock()
                PTFoundation.runtimeErrorCall(.resourceBroken)
            }

            debugPrint("PTServerManager sync completed")
        }

        // triggeredByServer
        PTNotificationCenter.shared.postNotification(withName: .ServerManager_RegistrationChanged,
                                                     attachment: uuid)
    }
}
