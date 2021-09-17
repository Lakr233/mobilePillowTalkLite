//
//  PTCodeClipManager.swift
//  PTFoundation
//
//  Created by Lakr Aream on 12/18/20.
//

import Foundation

// 文件保存机制修改为只在 app 启动时读取本地数据 其他时间只写入

public final class PTCodeClipManager {
    /// 单例
    public static let shared = PTCodeClipManager()

    /// 储存文件夹名称
    internal static let StoreBase = "CodeClip"

    /// 储存位置
    internal var baseLocation = PTFoundation.uninitiatedURL

    /// 默认分组名称
    public static let defaultSectionName = "!$DEFAULT_SECTION$"

    /// 分组 -- 名称 --> 代码片段
    public typealias CodeClipCollection = [String: CodeClip]
    public typealias CodeClipGroupCollection = [String: CodeClipGroup]

    /// 内存储存 -- 分组名称 --> 分组
    internal var clipContainer: [String: CodeClipCollection] = [:]
    internal var groupContainer: [String: CodeClipGroupCollection] = [:]

    /// 两把锁
    internal var executionLock = NSLock()
    internal var fileSyncLock = NSLock()

    /// 节流阀
    internal var syncThrottle = PTThrottle(minimumDelay: 1,
                                            queue: DispatchQueue.global(qos: .background))

    private init() {}
}
