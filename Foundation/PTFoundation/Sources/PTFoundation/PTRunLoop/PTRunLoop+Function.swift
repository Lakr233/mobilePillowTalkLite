//
//  PTRunLoop.swift
//  PTFoundation
//
//  Created by Lakr Aream on 12/17/20.
//

import Foundation

public extension PTRunLoop {
    /// 请求初始化 RunLoop 如果已经初始化就忽略请求
    func initlization() {
        if currentStatus == .initialized {
            PTLog.shared.join(self,
                              "runloop initlization skipped due to activated",
                              level: .warning)
            return
        }

        executionLock.lock()
        // 通知状态改变 未初始化 -> 开始初始化
        currentStatus = .beginInitial
        callRegisteredLifeCycleListenerAtomically()

        // 通知状态改变 开始初始化 -> 正在运行
        initializeRunLoopDispatcher()
        executionLock.unlock()
    }

    /// 析构 RunLoop 只能 Call 一次
    func teardown() {
        executionLock.lock()
        // 通知状态改变 运行 -> 开始析构
        currentStatus = .beginTeardown
        callRegisteredLifeCycleListenerAtomically()

        // 等待派遣函数退出
        shouldTearDown = true
        tearDownSemaphore.wait()

        // 通知状态改变 开始析构 -> 死亡
        currentStatus = .dead
        callRegisteredLifeCycleListenerAtomically()

        // 清理类属性信息
        tearDownCompleted = true
        executionLock.unlock()
    }

    /// 注册事件
    /// - Parameter event: 事件对象
    func registerEvent(withObject event: Event) {
        if event.type == .trigger && event.condition == nil {
            PTLog.shared.join(self,
                              "trigger event must be registered with a condition",
                              level: .error)
            return
        }
        executionLock.lock()
        events.append(event)
        executionLock.unlock()
    }

    /// 删除事件
    /// - Parameter uuid: 事件 uuid
    func removeEvent(withUUID uuid: String) {
        executionLock.lock()
        var newEvents = [Event]()
        for event in events where event.uuid != uuid {
            newEvents.append(event)
        }
        events = newEvents
        executionLock.unlock()
    }

    /// 注册生命周期事件
    /// - Parameter event: 事件对象
    func registerLifeCycleEvent(withObject object: LifeCycleBlock) {
        executionLock.lock()
        lifeCycleEvents.append(object)
        executionLock.unlock()
    }

    /// 删除生命周期事件
    /// - Parameter uuid: 事件 uuid
    func removeLifeCycleEvent(withUUID uuid: String) {
        executionLock.lock()
        var newEvents = [LifeCycleBlock]()
        for event in lifeCycleEvents where event.uuid != uuid {
            newEvents.append(event)
        }
        lifeCycleEvents = newEvents
        executionLock.unlock()
    }
}
