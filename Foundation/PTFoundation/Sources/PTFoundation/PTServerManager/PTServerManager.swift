//
//  PTServerManager.swift
//  PTFoundation
//
//  Created by Lakr Aream on 12/12/20.
//

import Foundation
import SQLite

public final class PTServerManager {
    public typealias ServerDescriptor = String

    /// 注册中断 用于注册失败的时候提供回掉信息
    public enum RegistrationInterrupt {
        // 重复注册
        /*
         对于服务器数据之间的比较
         对比是否一致 <--> 对比识别号
         对比是否重复 <--> 主机名 + 端口 + 用户名 [登录凭证不算在内]
         */
        case duplicated
        // 无效的数据
        /*
         地址不合法等
         */
        case badInfo
    }

    /// 注册解决方案 在中断处理过后返回给注册方法
    public enum RegistrationSolution {
        // 继续注册 由于会生成新的服务器识别号 所以不会有问题的
        case continueRegistration
        // 取消注册 什么变化都不会发生
        case abortRegistration
    }

    /// 注意 这里是 class 引用传递
    internal class ServerObject: Codable {
        var server: Server
        var supervised: Bool
        var supervisionStatus: ServerStatus?
        internal init(server: PTServerManager.Server,
                      supervisionStatus: PTServerManager.ServerStatus? = nil)
        {
            self.server = server
            supervised = server.supervisionTimeInterval > 0
            self.supervisionStatus = supervisionStatus
        }
    }

    /// 单例模式
    public static let shared = PTServerManager()

    /// 储存
    internal static let StoreBase = "Servers"
    /// 储存的位置 初始化位于调用内
    internal var baseLocation = PTFoundation.uninitiatedURL

    /// 内存中的服务器状态
    internal var serverContainer: [String: ServerObject] = [:]

    /// 锁
    internal var executionLock = NSLock()
    internal var fileSyncLock = NSLock()
    internal var runLoopDispatcherLock = NSLock()
    internal var databaseLock = NSLock()

    /// 数据库
    internal var database: Connection?

    /// 同步数据的节流阀
    internal let syncThrottle = PTThrottle(minimumDelay: 1,
                                            queue: DispatchQueue.global(qos: .background))

    /// 迸发队列
    internal let supervisionConcurrentQueue = DispatchQueue(label: "wiki.qaq.PTServerManager.concurrentUpdate",
                                                            attributes: .concurrent)
    internal let databaseConcurrentQueue = DispatchQueue(label: "wiki.qaq.PTServerManager.concurrentUpdate",
                                                         attributes: .concurrent)

    /// 正在获取服务器信息的队列数量
    internal var supervisionInProgressCount: Int = 0

    /// 私有初始化
    private init() {}

    // 备注
    /*
     最大监视数量交给UI去决定吧
     */
}
