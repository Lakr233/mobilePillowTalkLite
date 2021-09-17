//
//  PTCodeClipManager.swift
//  PTFoundation
//
//  Created by Lakr Aream on 12/24/20.
//

import Foundation

extension PTCodeClipManager {
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

        baseLocation = toDir.appendingPathComponent(PTCodeClipManager.StoreBase)
        if PTFoundation.ensureDirExists(atLocation: baseLocation) != nil {
            return .filePermissionDenied
        }

        // 从本地加载数据
        let contextDir = baseLocation
        var validObjectCount = 0
        do {
            // 拿到全部的分组名称
            let sectionNames = try FileManager.default.contentsOfDirectory(atPath: contextDir.path)
            for sectionName in sectionNames {
                let contextBase = contextDir.appendingPathComponent(sectionName)
                // 检查分组内的文件
                do {
                    guard let fileNames = try? FileManager.default.contentsOfDirectory(atPath: contextBase.path) else {
                        continue
                    }
                    for fileName in fileNames {
                        let fullPath = contextBase.appendingPathComponent(fileName) // 已经包含 .plist
                        let data = try Data(contentsOf: fullPath)
                        if let object = CodeClip.decodeFromData(data: data) {
                            clipContainer[sectionName, default: [:]][object.name] = object
                            validObjectCount += 1
                        } else if let object = CodeClipGroup.decodeFromData(data: data) {
                            groupContainer[sectionName, default: [:]][object.name] = object
                            validObjectCount += 1
                        } else {
                            PTLog.shared.join(self,
                                              "failed to decode file at \(fullPath.path), removing it",
                                              level: .error)
                            try FileManager.default.removeItem(at: fullPath)
                        }
                    }
                } catch {
                    try FileManager.default.removeItem(at: contextBase)
                }
            }
        } catch {
            debugPrint(error)
            PTFoundation.runtimeErrorCall(.filePermissionDenied)
        }

        PTLog.shared.join(self,
                          "setup reported \(validObjectCount) codes",
                          level: .info)

        return nil
    }

    /// 同步数据 保存内存的数据到本地
    func synchronizeObjects() {
        syncThrottle.throttle {
            // 复制
            self.executionLock.lock()
            let clipCapture = self.clipContainer
            let groupCapture = self.groupContainer
            self.executionLock.unlock()

            // 开始写
            self.fileSyncLock.lock()

            let contextDir = self.baseLocation

            // 清理磁盘数据 处理不存在的分组
            do {
                // 拿到全部的分组名称
                let sectionNames = try FileManager.default.contentsOfDirectory(atPath: contextDir.path)
                for sectionName in sectionNames {
                    let contextBase = contextDir.appendingPathComponent(sectionName)
                    // 分组已经不存在了
                    if !(clipCapture.keys.contains(sectionName)
                        || groupCapture.keys.contains(sectionName))
                    {
                        try FileManager.default.removeItem(at: contextBase)
                        continue
                    }
                    // 检查分组内的文件
                    let fileNames = try FileManager.default.contentsOfDirectory(atPath: contextBase.path)
                    for fileNameRaw in fileNames {
                        let fileName = fileNameRaw.hasSuffix("plist")
                            ? String(fileNameRaw.dropLast(".plist".count))
                            : fileNameRaw
                        // 康康这个 clip 或者 group 是不是在内存中还存在
                        if clipCapture[sectionName, default: [:]][fileName] == nil,
                           groupCapture[sectionName, default: [:]][fileName] == nil
                        {
                            let path = contextBase.appendingPathComponent(fileNameRaw)
                            try FileManager.default.removeItem(at: path)
                        }
                    }
                    // 其他数据不做处理 因为很快要覆盖了
                }
            } catch {
                PTFoundation.runtimeErrorCall(.filePermissionDenied)
            }

            // 创建全部分组目录
            for sectionName in [String](clipCapture.keys) + [String](groupCapture.keys) {
                let error = PTFoundation.ensureDirExists(atLocation: contextDir.appendingPathComponent(sectionName))
                if error != nil {
                    PTFoundation.runtimeErrorCall(.filePermissionDenied)
                }
            }

            // 覆盖全部的文件
            do {
                for (clipSection, clipCollection) in clipCapture {
                    for (clipName, clipObject) in clipCollection {
                        let path = contextDir
                            .appendingPathComponent(clipSection)
                            .appendingPathComponent(clipName)
                            .appendingPathExtension("plist")
                        guard let data = clipObject.encodeToData() else {
                            PTLog.shared.join(self,
                                              "failed to encode clip object, ignoring",
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

                // 以下代码和上面这部分和上面几乎一致
                for (clipSection, clipCollection) in groupCapture {
                    for (clipName, clipObject) in clipCollection {
                        let path = contextDir
                            .appendingPathComponent(clipSection)
                            .appendingPathComponent(clipName)
                            .appendingPathExtension("plist")
                        guard let data = clipObject.encodeToData() else {
                            PTLog.shared.join(self,
                                              "failed to encode clip object, ignoring",
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
                debugPrint(error)
                PTFoundation.runtimeErrorCall(.filePermissionDenied)
            }

            self.fileSyncLock.unlock()

            PTLog.shared.join(self, "configuration sync completed", level: .info)
        }
    }
}
