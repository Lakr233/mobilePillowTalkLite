//
//  PTCheckpointManager.swift
//  PTFoundation
//
//  Created by Lakr Aream on 12/17/20.
//

import Foundation

// TODO: RUNLOOP

/// 检查点管理器
public final class PTCheckpointManager {
    /// 单例
    public static let shared = PTCheckpointManager()

    /// 给未分配主机的检查点存放内容
    internal static let unassignedCheckpointStoreKey = "NotAssigned"
    /// 储存父文件夹
    internal static let StoreBase = "Checkpoint"
    /// 储存位置
    internal var baseLocation = PTFoundation.uninitiatedURL

    public typealias CheckpointName = String
    public typealias CheckpointCollection = [CheckpointName: Checkpoint]
    /// 检查点
    internal var container: [PTServerManager.ServerDescriptor?: CheckpointCollection] = [:]

    // 锁
    internal var executionLock = NSLock()
    internal var fileSyncLock = NSLock()

    // 同步节流阀
    internal var syncThrottle = PTThrottle(minimumDelay: 1,
                                            queue: DispatchQueue.global(qos: .background))

    internal required init() {}
}
