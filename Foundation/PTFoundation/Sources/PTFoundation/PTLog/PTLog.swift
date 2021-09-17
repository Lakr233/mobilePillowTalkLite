//
//  PTLog.swift
//  PTFoundation
//
//  Created by Lakr Aream on 12/11/20.
//

import Foundation

public final class PTLog {
    /// 初始化的传入信息
    public struct PTLogConfig {
        // 存档位置 传入根目录 会创建新的文件夹
        var baseLocation: URL
        // 日志的过滤等级 TODO 目前还没有实现过滤
        var baseLevel: PTLogLevel
        public init(location: URL, level: PTLogLevel) {
            baseLocation = location
            baseLevel = level
        }
    }

    /// 日志的等级
    public enum PTLogLevel: String {
        case verbose // 全部日志 啰嗦模式
        case info // 正常输出 比方说什么时候服务器更新了
        case warning // 可恢复警告 比如用户写错了数据 但是这个不致命 这个方法可以忽略该错误继续运行
        case error // 错误 方法内不可恢复的错误 比方说服务器连不上了 遇到了 方法就退出
        case critical // 程序必须退出或关闭的错误 比如目录不可写
    }

    /// 留存的日志数量 商榷 128份 TODO
    internal static let PTLogMaxLogFileCount = 128
    /// 创建的文件夹名称 有点想换成 Journal
    internal static let StoreBase = "Logs"
    /// 共享实例
    public static let shared = PTLog()

    public var currentLogFileLocation: URL?
    public var currentLogFileDirLocation: URL?
    #if DEBUG
        /// 文件句柄 理论上只会写一次
        internal var logFileHandler: FileHandle? {
            didSet {
                if let oldValue = oldValue {
                    debugPrint("PTLog - logFileHandler was modified, oldValue is NOT nil! \(oldValue)")
                }
            }
        }
    #else
        /// 文件句柄
        internal var logFileHandler: FileHandle?
    #endif
    /// 保存传入的配置文件
    internal var logConfig: PTLogConfig?
    /// 写入日志所需要的线程安全锁
    internal let executionLock = NSLock()
    /// 上一次写入的 tag 用于优化输出的颜值
    internal var lastTag: String?
    /// 日志输出时间格式化加速缓存
    internal var formatter: DateFormatter?

    /// 不开放 init()
    private init() {}
}
