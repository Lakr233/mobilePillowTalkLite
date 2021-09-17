//
//  PTRunLoop.swift
//  PTFoundation
//
//  Created by Lakr Aream on 12/17/20.
//

import Foundation

extension PTRunLoop {
    /// 创建循环
    func initializeRunLoopDispatcher() {
        // 延迟 +1s 来避免启动时候负载过高
        PTRunLoop.runLoopQueue.asyncAfter(deadline: .now() + 1) {
            // 初始化完成 通知监听对象
            self.currentStatus = .initialized
            self.callRegisteredLifeCycleListenerAtomically()
            self.initializationCompleted = true

            // 开始主循环
            while !self.shouldTearDown {
                autoreleasepool {
                    self.dispatchRegisteredServiceIfNeeded()
                }
                usleep(useconds_t(Double(1_000_000 * PTRunLoop.runLoopThrottleInterval)))
            }

            // 通知循环已退出
            self.tearDownSemaphore.signal()
        }
    }

    /// 派发任务
    func dispatchRegisteredServiceIfNeeded() {
        events.forEach { event in
            if event.type == .trigger {
                dispatchTriggerEvent(event: event)
            } else if event.type == .timer {
                dispatchTimerEvent(event: event)
            } else {
                PTLog.shared.join(self,
                                  "invalid event object with type \(event.type.rawValue)",
                                  level: .error)
            }
        }
    }

    /// 派遣状态事件 由调用对象决定是否执行
    /// - Parameter event: 事件
    func dispatchTriggerEvent(event: Event) {
        // 所有的 trigger event 都需要包含 condition block
        guard let condition = event.condition else {
            PTLog.shared.join(self,
                              "trigger event missing condition block",
                              level: .error)
            return
        }
        if !condition() { return }
        func executeEvent() {
            event.lastExecute = Date()
            PTRunLoop.runLoopQueue.async { event.block() }
        }
        if let date = event.lastExecute {
            if -date.timeIntervalSinceNow >= event.throttlingInterval {
                executeEvent()
            }
        } else {
            executeEvent()
        }
    }

    /// 派遣定时任务 同样需要检查自定义条件
    /// - Parameter event: 定时任务
    func dispatchTimerEvent(event: Event) {
        // 不符合状态要求
        if let condition = event.condition {
            if !condition() { return }
        }
        func executeEvent() {
            event.lastExecute = Date()
            PTRunLoop.runLoopQueue.async { event.block() }
        }
        if let date = event.lastExecute {
            if -date.timeIntervalSinceNow >= event.throttlingInterval {
                executeEvent()
            }
        } else {
            executeEvent()
        }
    }

    /// 通知状态改变回掉
    /// 不上锁了 自己注意
    func callRegisteredLifeCycleListenerAtomically() {
        let status = currentStatus
        for item in lifeCycleEvents.sorted(by: { a, b -> Bool in
            a.priority >= b.priority
        }) {
            item.block(status)
        }
    }
}
