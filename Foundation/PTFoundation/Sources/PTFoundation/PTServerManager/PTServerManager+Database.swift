//
//  PTServerManager.swift
//  PTFoundation
//
//  Created by Lakr Aream on 2/2/21.
//

import Foundation
import SQLite

/// 数据库的结构体
internal enum PTServerManagerDatabaseTypes {
    static let table = Table("MonitorRecord")
    static let id = Expression<String>("record_identity")
    static let server = Expression<String>("server_identity")
    static let timestamp = Expression<Double>("record_timestamp_since1970")
    static let status = Expression<String>("status_json")
}

extension PTServerManager {
    /// 确认表格存在 不存在就初始化
    /// - Returns: 是否成功
    typealias Succeed = Bool
    func ensureDatabaseTableExistsSucceed() -> Succeed {
        databaseLock.lock()
        defer { databaseLock.unlock() }
        #if DEBUG
            PTLog.shared.join(self,
                              "SQL database changes its table over time in development",
                              level: .verbose)
            PTLog.shared.join(self,
                              "use following command to drop a table",
                              level: .verbose)
            PTLog.shared.join(self,
                              "try db.run(PTServerManagerDatabaseTypes.table.drop())",
                              level: .verbose)
        #endif

        do {
            let db = try Connection(baseLocation.appendingPathComponent("database.sqlite3").path)
            try db.run(PTServerManagerDatabaseTypes.table.create(ifNotExists: true) { t in
                t.column(PTServerManagerDatabaseTypes.id, unique: true)
                t.column(PTServerManagerDatabaseTypes.server)
                t.column(PTServerManagerDatabaseTypes.timestamp)
                t.column(PTServerManagerDatabaseTypes.status)
            })
            database = db
        } catch {
            PTLog.shared.join(self,
                              "SQL failed to initialize with reason: \(error.localizedDescription)",
                              level: .critical)
            return false
        }
        return true
    }

    /// 添加服务器状态记录
    /// - Parameters:
    ///   - id: 服务器识别码
    ///   - info: 服务器状态
    ///   - date: 时间
    func recordServerStatus(serverDescriptor id: String, info: ServerInfo, date: Date = Date()) {
        databaseLock.lock()
        defer { databaseLock.unlock() }
        guard let db = database else {
            PTLog.shared.join(self,
                              "SQL database connection lost",
                              level: .error)
            return
        }
        let data = try? PTFoundation.jsonEncoder.encode(info)
        guard let d = data, let statusStr = String(data: d, encoding: .utf8) else {
            PTLog.shared.join(self,
                              "failed to compile server status string",
                              level: .error)
            return
        }
        do {
            try db.run(PTServerManagerDatabaseTypes.table.insert(
                PTServerManagerDatabaseTypes.id <- UUID().uuidString,
                PTServerManagerDatabaseTypes.server <- id,
                PTServerManagerDatabaseTypes.timestamp <- date.timeIntervalSince1970,
                PTServerManagerDatabaseTypes.status <- statusStr
            ))
        } catch {
            PTLog.shared.join(self,
                              "SQL database connection failed with reason: \(error.localizedDescription)",
                              level: .error)
            return
        }
    }

    /// 清理记录
    /// - Parameters:
    ///   - cleanInvalid: 清理不存在的数据 比如主机已删除
    ///   - cleanBeforeDate: 清理过期数据
    func cleanRecord(cleanInvalid: Bool = true, cleanBeforeDate: Date? = nil) {
        databaseLock.lock()
        defer { databaseLock.unlock() }
        guard let db = database else {
            PTLog.shared.join(self,
                              "SQL database connection lost",
                              level: .error)
            return
        }
        var invalidRecordIdentities = [String]()
        let decoder = JSONDecoder()
        do {
            for record in try db.prepare(PTServerManagerDatabaseTypes.table) {
                guard let id = try? record.get(PTServerManagerDatabaseTypes.id) else {
                    PTLog.shared.join(self,
                                      "SQL database failed to load record: \(record)",
                                      level: .error)
                    continue
                }
                do {
                    if cleanInvalid {
                        let status = try record.get(PTServerManagerDatabaseTypes.status) as String
                        if let data = status.data(using: .utf8) {
                            _ = try decoder.decode(PTServerManager.ServerInfo.self, from: data)
                        } else {
                            invalidRecordIdentities.append(id)
                        }
                    }
                    if let date = cleanBeforeDate {
                        let record_raw = try record.get(PTServerManagerDatabaseTypes.timestamp)
                        if Date(timeIntervalSince1970: record_raw).timeIntervalSince(date) < 0 {
                            invalidRecordIdentities.append(id)
                        }
                    }
                } catch {
                    PTLog.shared.join(self,
                                      "Invalid record found with id: \(id)",
                                      level: .error)
                    invalidRecordIdentities.append(id)
                }
            }
            for record in invalidRecordIdentities {
                let target = PTServerManagerDatabaseTypes.table.filter(PTServerManagerDatabaseTypes.id == record)
                try db.run(target.delete())
            }
        } catch {
            PTLog.shared.join(self,
                              "SQL database failed to load table",
                              level: .error)
        }
    }
    
    /// 删除全部历史记录
    public func purgeDatabase() {
        databaseLock.lock()
        defer { databaseLock.unlock() }
        guard let db = database else {
            PTLog.shared.join(self,
                              "SQL database connection lost",
                              level: .error)
            return
        }
        do {
            let table = PTServerManagerDatabaseTypes.table
            try db.run(table.drop(ifExists: true))
            try db.run(PTServerManagerDatabaseTypes.table.create(ifNotExists: true) { t in
                t.column(PTServerManagerDatabaseTypes.id, unique: true)
                t.column(PTServerManagerDatabaseTypes.server)
                t.column(PTServerManagerDatabaseTypes.timestamp)
                t.column(PTServerManagerDatabaseTypes.status)
            })
        } catch {
            PTLog.shared.join(self,
                              "SQL database failed to load table",
                              level: .critical)
            return
        }
        
    }
}
