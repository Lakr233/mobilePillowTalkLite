//
//  PTServerManager.swift
//  PTFoundation
//
//  Created by Lakr Aream on 12/13/20.
//

import Foundation

extension PTServerManager {
    /// 调用接口启用 runloop
    func initializeRunLoop() {
        let event = PTRunLoop.Event(type: .timer, throttlingInterval: 0.5) {
            self.executionLock.lock()
            let copied = self.serverContainer
            self.executionLock.unlock()
            self.runLoopDispatcherLock.lock()
            self.runLoopDispatcher(copiedContainer: copied)
            self.runLoopDispatcherLock.unlock()
        }
        // 延迟启动
        DispatchQueue.global().asyncAfter(deadline: .now() + 3) {
            PTRunLoop.shared.registerEvent(withObject: event)
        }
    }

    // 需要在短时间内处理完全部事情 所以使用分发机制 此处不干活
    func runLoopDispatcher(copiedContainer: [String: ServerObject]) {
        // 遍历全部被观测服务器
        let captureDate = Date()
        let keys = copiedContainer.keys
        for key in keys {
            // 获取服务器对象
            if let serverObject = copiedContainer[key],
               serverElegantForUpdate(serverObject: serverObject, batchTimeStamp: captureDate)
            {
                // 进入状态
                if serverObject.supervisionStatus == nil {
                    serverObject.supervisionStatus = .init(serverDescriptor: serverObject.server.uuid)
                }
                serverObject.supervisionStatus?.pendingUpdate = true
                PTNotificationCenter.shared.postNotification(withName: .ServerManager_ServerStatusUpdated,
                                                             attachment: serverObject.server.uuid)
                // 派遣更新
                supervisionConcurrentQueue.async {
                    self.serverSupervisionUpdateAtomically(fromServer: serverObject)
                }
            }
        }
    }

    /// 服务器符合自动更新的规范 需要更新
    /// - Parameters:
    ///   - serverObject: 服务器对象
    ///   - batchTimeStamp: 批量更新时间戳
    /// - Returns: 是否满足条件
    func serverElegantForUpdate(serverObject: ServerObject, batchTimeStamp: Date = Date()) -> Bool {
        // 并没有在更新
        if serverObject.supervised, !(serverObject.supervisionStatus?.pendingUpdate ?? false) {
            // 检查上次更新的时间间隔
            let previousUpdateTimestamp = serverObject.supervisionStatus?.previousUpdate
                ?? Date(timeIntervalSince1970: 0)
            let supervisionInterval = serverObject.server.supervisionTimeInterval
            // 检查时间间隔数据是否合法
            if supervisionInterval <= 0 {
                PTLog.shared.join(self,
                                  "server supervised update canceled due to negative intreval\(supervisionInterval) on \(serverObject.server.obtainPossibleName())",
                                  level: .warning)
                return false
            }
            // 如果时间间隔已经超过目标间隔
            if Int(batchTimeStamp.timeIntervalSince(previousUpdateTimestamp)) >= supervisionInterval {
                return true
            }
        }
        return false
    }

    /// 完成服务器状态更新 包含取消正在更新关键字并通知数据库
    /// - Parameters:
    ///   - server: 服务器引用
    ///   - errorOccurred: 是否包含错误
    func finalizeServerStatusUpdate(fromServer server: ServerObject, errorOccurred: Bool) {
        if server.supervisionStatus == nil {
            server.supervisionStatus = .init(serverDescriptor: server.server.uuid)
        }
        server.supervisionStatus?.previousUpdate = Date()
        server.supervisionStatus?.pendingUpdate = false
        server.supervisionStatus?.statusUpdated = !errorOccurred
        server.supervisionStatus?.errorOccurred = errorOccurred
        PTNotificationCenter.shared.postNotification(withName: .ServerManager_ServerStatusUpdated,
                                                     attachment: server.server.uuid)
    }

    /// 更新服务器信息 atomically
    /// - Parameter server: 服务器对象
    @discardableResult
    func serverSupervisionUpdateAtomically(fromServer server: ServerObject) -> ServerInfo? {
        // 派遣时锁定资源
//        server.supervisionStatus?.pendingUpdate = true
        guard let info = acquireServerInfo(fromServer: server.server) else {
            // 错误由具体处理方法打印
            finalizeServerStatusUpdate(fromServer: server, errorOccurred: true)
            return nil
        }
        if server.supervisionStatus == nil {
            server.supervisionStatus = .init(serverDescriptor: server.server.uuid)
        }
        let date = Date()
        server.supervisionStatus?.information = info
        finalizeServerStatusUpdate(fromServer: server, errorOccurred: false)

        databaseConcurrentQueue.async {
            if !PTFoundation.requestingUserDefault(forKey: .supervisionRecordEnabled, defaultValue: true) {
                return
            }
            self.recordServerStatus(serverDescriptor: server.server.uuid, info: info, date: date)
        }

        synchronizeObjects()

        return info
    }
}
