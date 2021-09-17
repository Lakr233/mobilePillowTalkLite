//
//  PTNotificationCenter.swift
//  PTFoundation
//
//  Created by Lakr Aream on 1/9/21.
//

import Foundation

public extension PTNotificationCenter {
    /// 发送通知
    /// - Parameters:
    ///   - withName: 通知名称 通常指代事件名称
    ///   - attachment: 发送一个对象 可选
    func postNotification(withName: NotificationName, attachment: Any? = nil) {
        executionLock.lock()
        defer { executionLock.unlock() }
        guard let objects = notifications[withName] else {
            return
        }
        objects.forEach { link in
            link.notificationSend(representedObject: attachment)
        }
    }

    /// 注册通知
    /// - Parameters:
    ///   - name: 通知名称 通常指代事件名称
    ///   - link: 通知对象
    func registeringNotification(withLink link: NotificationLink) {
        executionLock.lock()
        notifications[link.name, default: []].append(link)
        executionLock.unlock()
    }

    /// 删除注册的通知
    /// - Parameters:
    ///   - key: 通知对象的 uuid
    ///   - name: 通知对象的名称 通常指代事件名称
    func removeNotificatino(withKey key: String,
                            underName name: NotificationName)
    {
        executionLock.lock()
        let orig = notifications[name, default: []]
        var new = [NotificationLink]()
        for link in orig where link.uuid != key {
            new.append(link)
        }
        notifications[name, default: []] = new
        executionLock.unlock()
    }
}
