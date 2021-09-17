//
//  PTLog.swift
//  PTFoundation
//
//  Created by Lakr Aream on 4/12/21.
//

import Foundation

extension PTLog {
    /// 初始化
    /// - Parameter config: 传入配置
    /// - Returns: 初始化错误 如有
    func initialization(withConfiguration config: PTLogConfig) -> PTFoundation.InitializationError? {
        logConfig = config

        if PTFoundation.ensureDirExists(atLocation: config.baseLocation) != nil {
            return .filePermissionDenied
        }
        let storeLocationDir = config.baseLocation.appendingPathComponent(PTLog.StoreBase, isDirectory: true)
        if PTFoundation.ensureDirExists(atLocation: storeLocationDir) != nil {
            return .filePermissionDenied
        }
        currentLogFileDirLocation = storeLocationDir
        
        // 创建文件
        /*
         后面 sorted 会对他排序
         PTLog_2021-03-01_22-10-43_ACAF51D1.log
         前缀   |          |        |       .后缀
               日期        |        |
                          时间      |
                                   随机编码
         */

        // 日期数据格式 后面清理日志数据的时候要用
        let initDateFormatter = DateFormatter()
        initDateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"

        var logFileLocation: URL
        do {
            let dateName = String(initDateFormatter.string(from: Date()))
            // 随机编码
            let suffix = String(UUID().uuidString.dropLast(28)) // "-C36C-495A-93FC-0C247A3E6E5F".count
            // 创建文件名
            let name = "PTLog_" + dateName + "_" + suffix + ".log"
            #if DEBUG
                // 检查文件名
                assert(!name.contains(" "), "\(#file) \(#line) invalid log file name: \(name)")
                assert(name.count == 38, "\(#file) \(#line) invalid log file name: \(name)")
                // "PTLog_2021-03-01_22-10-43_ACAF51D1.log".count
            #endif
            logFileLocation = storeLocationDir.appendingPathComponent(name)
            // 以防万一有非洲人中奖
            try? FileManager.default.removeItem(at: logFileLocation)
            // 稍后创建文件
        }

        // 删除旧日志 稍后创建文件以免把刚创建的给删了
        do {
            // 获取全部的文件名
            let rawSubitems = try FileManager.default.contentsOfDirectory(atPath: storeLocationDir.path)
            // 如果文件过多
            if rawSubitems.count > PTLog.PTLogMaxLogFileCount {
                // 排序不能依靠 sorted
                let subitems = rawSubitems.sorted { a, b -> Bool in
                    // 如果文件名长度不是38 那大概率没法搞 优先删除
                    if a.count != 38 || b.count != 38 {
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
                        // 不能恢复文件日期 很奇怪 那就优先删除
                        return a < b
                    }
                }
                let deleteCount = subitems.count - PTLog.PTLogMaxLogFileCount
                if deleteCount > 0 {
                    // 需要删除
                    for index in 0 ..< deleteCount {
                        #if DEBUG
                            assert(index < subitems.count && index >= 0, "\(#file) \(#line) bad index")
                        #else
                            if index < subitems.count, index >= 0 {
                                continue
                            }
                        #endif
                        let file = storeLocationDir.appendingPathComponent("\(subitems[index])")
                        debugPrint("[PTLog] cleaning log file[\(index)] at: \(file.path)")
                        do {
                            try FileManager.default.removeItem(at: file)
                        } catch {
                            print("[PTLog] failed to delete old logs at: \(file)")
                            return .filePermissionDenied
                        }
                    }
                }
            }
        } catch {
            // 这里算是遇到了不可恢复的问题 因为不可读写
            print("[PTLog] \(#file) \(#line) failed to enumerate contents of directory: \(storeLocationDir)")
            return .filePermissionDenied
        }

        // 创建文件
        FileManager.default.createFile(atPath: logFileLocation.path, contents: nil, attributes: nil)
        print("[PTLog] \(logFileLocation.path)")

        // 打开文件句柄
        if let handler = FileHandle(forWritingAtPath: logFileLocation.path) {
            logFileHandler = handler
        } else {
            return .filePermissionDenied
        }

        currentLogFileLocation = logFileLocation

        // 没有错误
        return nil
    }
}
