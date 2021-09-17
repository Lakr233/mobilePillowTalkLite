//
//  PTLog.swift
//  PTFoundation
//
//  Created by Lakr Aream on 12/15/20.
//

import Foundation

public extension PTLog {
    /// 检查是否是啰嗦模式
    /// - Returns: 真假
    func isVerbose() -> Bool {
        if let config = logConfig {
            return config.baseLevel == .verbose
        }
        return false
    }
    
    /// 获取全部日志的文件路径
    /// - Returns: 日志文件路径数组
    func obtainAllLogFilePath() -> [String] {
        var ret = [String]()
        if let base = currentLogFileDirLocation,
           let items = try? FileManager.default.contentsOfDirectory(atPath: base.path) {
            for item in items where item.hasPrefix("PTLog") {
                ret.append(base.appendingPathComponent(item).path)
            }
        }
        return ret
    }
    
    /// 获取当前的全部日志和记录
    /// - Returns: 日志内容
    func obtainCurrentLogContent() -> String {
        var str = ""
        if let path = currentLogFileLocation?.path,
           let read = try? String(contentsOfFile: path, encoding: .utf8) {
            str = read
        }
        return str
    }
    
    /// 添加日志并写入本地文件
    /// - Parameters:
    ///   - kind: 种类
    ///   - message: 消息
    ///   - level: 等级
    func join(_ kind: String, _ message: String, level: PTLogLevel = .info) {
        // 上锁
        executionLock.lock()
        defer { executionLock.unlock() }

        // 初始化格式化用具缓存
        if self.formatter == nil {
            self.formatter = DateFormatter()
            self.formatter!.dateFormat = "yyyy.MM.dd HH:mm:ss"
        }
        guard let formatter = self.formatter else {
            #if DEBUG
                fatalError("PTLog failed to create date formatter")
            #else
                print("PTLog failed to create date formatter")
                return
            #endif
        }
        // 创建输出的实际内容
        let content: String
        if lastTag == kind {
            content = "* |\(level.rawValue)| \(formatter.string(from: Date()))| \(message)"
        } else {
            lastTag = kind
            content = "[\(kind)]\n* |\(level.rawValue)| \(formatter.string(from: Date()))| \(message)"
        }
        // 输出到 stdout
        print(content)
        // 检查文件句柄
        guard let handler = logFileHandler else {
            print("PTLog failed to open file handler")
            return
        }
        // TODO: 性能优化 这里可能会比较耗时
        if let data = content.appending("\n").data(using: .utf8) {
            handler.write(data)
        } else {
            // 避免死循环
            // PTFoundation.reportError("bad content data!", from: self)
            #if DEBUG
                fatalError("PTLog failed to create log data using utf8")
            #else
                print("PTLog failed to create log data using utf8")
                return
            #endif
        }
    }

    /// 添加日志并写入本地文件
    /// - Parameters:
    ///   - kind: 种类
    ///   - message: 消息
    ///   - level: 等级
    func join(_ kind: Any, _ message: String, level: PTLogLevel = .info) {
        join(String(describing: kind.self), message, level: level)
    }

    /// 获取最后一份日志的内容
    /// - Returns: 完整文件路径和文件名 和 内容
    /// - Parameter baseLocation: 存放日志的文件夹
    func obtainPreviousLogContent(baseLocation: URL) -> (String?, String?) {
        let realPath = baseLocation.appendingPathComponent(PTLog.StoreBase, isDirectory: true)
        // 获取全部的文件名
        guard let rawSubitems = try? FileManager
            .default
            .contentsOfDirectory(atPath: realPath.path)
        else {
            return (nil, nil)
        }
        var invalidFile = [String]()
        let initDateFormatter = DateFormatter()
        initDateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        guard let item = rawSubitems.sorted { (a, b) -> Bool in
            // 如果文件名长度不是38 那大概率没法搞 优先删除
            if a.count != 38 || b.count != 38 {
                if a.count != 39 { invalidFile.append(a) }
                if b.count != 39 { invalidFile.append(b) }
                return a < b
            }
            // 裁剪两个数据 "PTLog_" "_ACAF51D1.log"
            let dateStrA = String(a.dropFirst(6).dropLast(13))
            let dateStrB = String(b.dropFirst(6).dropLast(13))
            let dateA = initDateFormatter.date(from: dateStrA)
            let dateB = initDateFormatter.date(from: dateStrB)
            if let dateA = dateA, let dateB = dateB {
                // A 到 B 的时间戳间隔大于0 表示 A 比较晚 要删除 B
                return dateA.timeIntervalSince(dateB) < 0
            } else {
                if dateA == nil { invalidFile.append(a) }
                if dateB == nil { invalidFile.append(b) }
                // 不能恢复文件日期
                return a < b
            }
        }.filter({ name in
            !invalidFile.contains(name)
        }).last else {
            return (nil, nil)
        }
        return (realPath.appendingPathComponent(item).path, try? String(contentsOf: realPath.appendingPathComponent(item)))
    }
}
