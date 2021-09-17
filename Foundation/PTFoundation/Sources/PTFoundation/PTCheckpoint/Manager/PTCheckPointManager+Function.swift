//
//  PTCheckpointManager.swift
//  PTFoundation
//
//  Created by Lakr Aream on 12/31/20.
//

import Foundation

public extension PTCheckpointManager {
    /// 返回检查点数量
    /// - Returns: 不安全的独享数据表
    func obtainCheckpointCount() -> Int {
        executionLock.lock()
        let copy = container
        executionLock.unlock()
        var cnt = 0
        for (_, value) in copy {
            cnt += value.count
        }
        return cnt
    }

    /// 返回拷贝的检查点组
    /// - Returns: 不安全的独享数据表
    func obtainCheckpointList() -> [PTServerManager.ServerDescriptor?: CheckpointCollection] {
        executionLock.lock()
        let copy = container
        executionLock.unlock()
        return copy
    }

    /// 添加检查点
    /// - Parameter code: 对象
    func addCheckpoint(code: Checkpoint) {
        executionLock.lock()
        container[code.section, default: [:]][code.name] = code
        executionLock.unlock()
        synchronizeObjects()
    }

    /// 删除检查点
    /// - Parameters:
    ///   - name: 名字
    ///   - section: 组名
    func deleteCheckpointWith(name: String, inSection section: String) {
        executionLock.lock()
        container[section]?.removeValue(forKey: name)
        if container[section]?.count == 0 {
            container.removeValue(forKey: section)
        }
        executionLock.unlock()
        synchronizeObjects()
    }

    /// 取回检查点
    /// - Parameters:
    ///   - name: 名字
    ///   - section: 组名
    /// - Returns: 代码片段对象 如果有
    func retrieveCheckpointWith(name: String, inSection section: String) -> Checkpoint? {
        executionLock.lock()
        let ret = container[section]?[name]
        executionLock.unlock()
        return ret
    }
}
