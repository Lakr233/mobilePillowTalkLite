//
//  PTRunLoop.swift
//  PTFoundation
//
//  Created by Lakr Aream on 12/17/20.
//

import Foundation

/// RunLoop 用于派遣事件 精度不高
public final class PTRunLoop {
    /// 节流阀
    static let runLoopThrottleInterval: Double = 0.2
    /// 队列
    static let runLoopQueue = DispatchQueue(label: "wiki.qaq.PillowTalk.RunLoop", attributes: .concurrent)

    /// 单例
    static let shared = PTRunLoop()
    private init() {}

    // 析构完成
    internal var tearDownCompleted = false {
        willSet {
            if tearDownCompleted {
                PTFoundation.runtimeErrorCall(.badExecutionLogic)
            }
        }
    }

    // 初始化完成
    internal var initializationCompleted = false {
        willSet {
            if tearDownCompleted {
                PTFoundation.runtimeErrorCall(.badExecutionLogic)
            }
            if initializationCompleted {
                PTFoundation.runtimeErrorCall(.badExecutionLogic)
            }
        }
    }

    /// 状态
    public enum RunLoopStatus: String {
        case uninitiated
        case beginInitial
        case initialized
        case beginTeardown
        case dead
    }

    /// 通知是否需要析构
    internal var shouldTearDown: Bool = false
    /// 析构函数将等待派遣函数退出
    internal var tearDownSemaphore: DispatchSemaphore = .init(value: 0)
    /// 当前状态
    internal var currentStatus: RunLoopStatus = .uninitiated

    /// 状态改变调用
    public struct LifeCycleBlock {
        let uuid: String
        let block: (RunLoopStatus) -> Void
        let priority: Int
        public init(block: @escaping (PTRunLoop.RunLoopStatus) -> Void,
                    withPriority priority: Int = 0)
        {
            uuid = UUID().uuidString
            self.block = block
            self.priority = priority
        }
    }

    /// 当 RunLoop 状态改变的时候调用全部的方法
    internal var lifeCycleEvents: [LifeCycleBlock] = []

    /// 执行锁
    internal var executionLock = NSLock()

    /// 注册调用
    public class Event {
        public enum RunLoopType: String {
            case timer
            case trigger
        }

        public typealias ConditionBlock = () -> (Bool)

        let uuid: String
        let type: RunLoopType
        let condition: ConditionBlock?
        let throttlingInterval: Double
        let block: () -> Void
        var lastExecute: Date?

        public required init(type: RunLoopType,
                             condition: ConditionBlock? = nil,
                             throttlingInterval: Double,
                             block: @escaping (() -> Void))
        {
            uuid = UUID().uuidString
            self.type = type
            self.condition = condition
            self.throttlingInterval = throttlingInterval
            self.block = block
            lastExecute = nil
        }
    }

    internal var events: [Event] = []
}
