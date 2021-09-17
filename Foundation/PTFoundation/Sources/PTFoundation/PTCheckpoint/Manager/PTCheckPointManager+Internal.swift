//
//  PTCheckpointManager.swift
//  PTFoundation
//
//  Created by Lakr Aream on 12/31/20.
//

import Foundation

extension PTCheckpointManager {
    /// 初始化
    /// - Parameter toDir: 可读写目录
    /// - Returns: 错误 如果有
    func initialization(toDir: URL) -> PTFoundation.InitializationError? {
        executionLock.lock()
        defer {
            executionLock.unlock()
        }

        if PTFoundation.ensureDirExists(atLocation: toDir) != nil {
            return .filePermissionDenied
        }

        baseLocation = toDir.appendingPathComponent(PTCheckpointManager.StoreBase)
        if PTFoundation.ensureDirExists(atLocation: baseLocation) != nil {
            return .filePermissionDenied
        }

        // 从本地加载数据
        let contextDir = baseLocation
        var validObjectCount = 0
        do {
            // 拿到全部的分组名称
            let ServerDescriptors = try FileManager.default.contentsOfDirectory(atPath: contextDir.path)
            for sectionName in ServerDescriptors {
                let contextBase = contextDir.appendingPathComponent(sectionName)
                // 检查分组内的文件
                guard let fileNames = try? FileManager.default.contentsOfDirectory(atPath: contextBase.path) else {
                    continue
                }
                for fileName in fileNames {
                    let fullPath = contextBase.appendingPathComponent(fileName) // 已经包含 .plist
                    let data = try Data(contentsOf: fullPath)
                    if let object = Checkpoint.decodeFromData(data: data) {
                        container[
                            sectionName == PTCheckpointManager.unassignedCheckpointStoreKey
                                ? nil
                                : sectionName,
                            default: [:]
                        ][object.name] = object
                        validObjectCount += 1
                    } else {
                        PTLog.shared.join(self,
                                          "failed to decode file at \(fullPath.path), removing it",
                                          level: .error)
                        try FileManager.default.removeItem(at: fullPath)
                    }
                }
            }
        } catch {
            PTFoundation.runtimeErrorCall(.filePermissionDenied)
        }

        PTLog.shared.join(self,
                          "initialization reported \(validObjectCount) checkpoint(s)",
                          level: .info)

        return nil
    }

    /// 同步内存的数据到本地
    func synchronizeObjects() {
        syncThrottle.throttle {
            // 复制
            self.executionLock.lock()
            let capture = self.container
            self.executionLock.unlock()

            // 开始写
            self.fileSyncLock.lock()

            let contextDir = self.baseLocation

            // 清理磁盘数据 处理不存在的分组
            do {
                // 拿到全部的分组名称
                let ServerDescriptors = try FileManager.default.contentsOfDirectory(atPath: contextDir.path)
                for ServerDescriptor in ServerDescriptors {
                    let contextBase = contextDir.appendingPathComponent(ServerDescriptor)
                    // 服务器已经没有检查点的 并且文件夹名称不是未分配 删除文件夹并继续
                    if capture.keys.contains(ServerDescriptor), ServerDescriptor != PTCheckpointManager.unassignedCheckpointStoreKey {
                        try FileManager.default.removeItem(at: contextBase)
                        continue
                    }
                    // 检查分组内的文件
                    let checkpointNames = try FileManager.default.contentsOfDirectory(atPath: contextBase.path)
                    for checkpointNameRaw in checkpointNames {
                        let fileName = checkpointNameRaw.hasSuffix("plist")
                            ? String(checkpointNameRaw.dropLast(".plist".count))
                            : checkpointNameRaw
                        // 康康这个 checkpoint 是不是在内存中还存在
                        if capture[ServerDescriptor, default: [:]][fileName] == nil {
                            let path = contextBase.appendingPathComponent(checkpointNameRaw)
                            // 删掉
                            try FileManager.default.removeItem(at: path)
                        }
                    }
                    // 其他数据不做处理 因为很快要覆盖了
                }
            } catch {
                PTFoundation.runtimeErrorCall(.filePermissionDenied)
            }

            // 创建全部分组目录
            var dirs = [String]()
            for ServerDescriptor in capture.keys {
                if let ServerDescriptor = ServerDescriptor {
                    dirs.append(ServerDescriptor)
                } else {
                    dirs.append(PTCheckpointManager.unassignedCheckpointStoreKey)
                }
            }
            for ServerDescriptor in dirs {
                let error = PTFoundation.ensureDirExists(atLocation: contextDir.appendingPathComponent(ServerDescriptor))
                if error != nil {
                    PTFoundation.runtimeErrorCall(.filePermissionDenied)
                }
            }

            // 覆盖全部的文件
            do {
                for (ServerDescriptor, checkpoints) in capture {
                    for (checkpointName, checkpointObject) in checkpoints {
                        let path = contextDir
                            .appendingPathComponent(ServerDescriptor ?? PTCheckpointManager.unassignedCheckpointStoreKey)
                            .appendingPathComponent(checkpointName)
                            .appendingPathExtension("plist")
                        guard let data = checkpointObject.encodeToData() else {
                            PTLog.shared.join(self,
                                              "failed to encode checkpoint object, ignoring",
                                              level: .error)
                            continue
                        }
                        // 如果有就删掉
                        if FileManager.default.fileExists(atPath: path.path) {
                            try FileManager.default.removeItem(at: path)
                        }
                        // 写进去
                        try data.write(to: path, options: .atomic)
                    }
                }
            } catch {
                PTFoundation.runtimeErrorCall(.filePermissionDenied)
            }

            self.fileSyncLock.unlock()

            PTLog.shared.join(self, "configuration sync completed", level: .info)
        }
    }
}
