//
//  PTNotificationCenter.swift
//  PTFoundation
//
//  Created by Lakr Aream on 1/9/21.
//

import Foundation

/// 通知中心 要不改名叫 EventBus 吧
public final class PTNotificationCenter {
    /// 单例
    public static let shared = PTNotificationCenter()
    /// 私有初始化
    private init() {}

    /// 提供的通知类型
    public enum NotificationName: String {
        /// 服务器注册状态改变
        case ServerManager_RegistrationChanged
        /// 服务器状态改变
        case ServerManager_ServerStatusUpdated

        /// 检查点注册状态改变
        case Checkpoint_RegistrationChanged

        /// 代码片段注册状态改变
        case CodeClip_RegistrationChanged
    }

    /// 回掉携带的信息
    public struct NotificationInfo {
        public let name: NotificationName
        public let representedObject: Any?
    }

    /// 注册对象
    public struct NotificationLink {
        public typealias NotificationBlock = (NotificationInfo) -> Void

        public let uuid: String = UUID().uuidString

        let name: NotificationName
        let block: NotificationBlock
        let throttle: PTThrottle?

        public init(name: NotificationName,
                    throttle: PTThrottle? = nil,
                    block: @escaping NotificationBlock)
        {
            self.name = name
            self.throttle = throttle
            self.block = block
        }

        /// 发送通知
        /// - Parameter representedObject: 携带的对象
        public func notificationSend(representedObject: Any?) {
            PTNotificationCenter.notificationQueue.async {
                let info = NotificationInfo(name: name, representedObject: representedObject)
                if let throttle = throttle {
                    throttle.throttle {
                        block(info)
                    }
                } else {
                    block(info)
                }
            }
        }
    }

    /// 注册的通知
    internal var notifications: [NotificationName: [NotificationLink]] = [:]

    /// 防止把字典写爆
    internal var executionLock = NSLock()

    /// 发消息要切换到自己的队列
    internal static var notificationQueue = DispatchQueue(label: "wiki.qaq.PTNotificationCenter.concurrentPost", attributes: .concurrent)
}
