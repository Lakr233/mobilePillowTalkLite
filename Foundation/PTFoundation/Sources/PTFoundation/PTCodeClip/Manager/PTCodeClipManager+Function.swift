//
//  PTCodeClipManager.swift
//  PTFoundation
//
//  Created by Lakr Aream on 12/24/20.
//

import Foundation

public extension PTCodeClipManager {
    /// 返回拷贝的代码片段
    /// - Returns: 不安全的独享数据表
    func obtainCodeClipList() -> [String: [String: CodeClip]] {
        executionLock.lock()
        let copy = clipContainer
        executionLock.unlock()
        return copy
    }

    /// 返回拷贝的代码片段组
    /// - Returns: 不安全的独享数据表
    func obtainCodeClipGroupList() -> [String: [String: CodeClipGroup]] {
        executionLock.lock()
        let copy = groupContainer
        executionLock.unlock()
        return copy
    }

    /// 返回拷贝的代码片段的 分组列表
    /// - Returns: 不安全的独享数据表
    func obtainCodeClipSectionNames() -> [String] {
        executionLock.lock()
        let copy = [String](clipContainer.keys)
        executionLock.unlock()
        return copy
    }

    /// 返回拷贝的代码片段组的 分组列表
    /// - Returns: 不安全的独享数据表
    func obtainCodeClipGroupSectionNames() -> [String] {
        executionLock.lock()
        let copy = [String](groupContainer.keys)
        executionLock.unlock()
        return copy
    }

    /// 添加代码片段 如果重复会复写
    /// - Parameter code: 对象
    func addCodeClip(code: CodeClip) {
        executionLock.lock()
        clipContainer[code.section, default: [:]][code.name] = code
        executionLock.unlock()
        synchronizeObjects()
        PTNotificationCenter.shared.postNotification(withName: .CodeClip_RegistrationChanged)
    }

    /// 添加代码片段组 如果重复会复写
    /// - Parameter code: 对象
    func addCodeClipGroup(codeGroup: CodeClipGroup) {
        executionLock.lock()
        groupContainer[codeGroup.section, default: [:]][codeGroup.name] = codeGroup
        executionLock.unlock()
        synchronizeObjects()
        PTNotificationCenter.shared.postNotification(withName: .CodeClip_RegistrationChanged)
    }

    /// 删除代码片段
    /// - Parameters:
    ///   - name: 名字
    ///   - section: 组名
    func deleteCodeClipWith(name: String, inSection section: String) {
        executionLock.lock()
        clipContainer[section, default: [:]].removeValue(forKey: name)
        if clipContainer[section]?.count == 0 {
            clipContainer.removeValue(forKey: section)
        }
        executionLock.unlock()
        synchronizeObjects()
        PTNotificationCenter.shared.postNotification(withName: .CodeClip_RegistrationChanged)
    }

    /// 查询包含该代码片段的代码组
    /// - Parameters:
    ///   - name: 名字
    ///   - section: 组名
    func referencedCodeGroupContainsClip(name: String, inSection section: String) -> [CodeClipGroup] {
        var lookup = [CodeClipGroup]()
        executionLock.lock()
        let capture = groupContainer
        executionLock.unlock()
        for (_, collection) in capture {
            for (_, group) in collection {
                var found = false
                look: for step in group.payloads {
                    if step.code.name == name, step.code.section == section {
                        found = true
                        break look
                    }
                }
                if found {
                    lookup.append(group)
                }
            }
        }
        return lookup
    }

    /// 删除代码片段组
    /// - Parameters:
    ///   - name: 名字
    ///   - section: 组名
    func deleteCodeClipGroupWith(name: String, inSection section: String) {
        executionLock.lock()
        groupContainer[section, default: [:]].removeValue(forKey: name)
        if groupContainer[section]?.count == 0 {
            groupContainer.removeValue(forKey: section)
        }
        executionLock.unlock()
        synchronizeObjects()
        PTNotificationCenter.shared.postNotification(withName: .CodeClip_RegistrationChanged)
    }

    /// 取回代码片段
    /// - Parameters:
    ///   - name: 名字
    ///   - section: 组名
    /// - Returns: 代码片段对象 如果有
    func retrieveCodeClipWith(name: String, inSection section: String) -> CodeClip? {
        executionLock.lock()
        let copy = clipContainer[section]?[name]
        executionLock.unlock()
        return copy
    }

    /// 取回代码片段组
    /// - Parameters:
    ///   - name: 名字
    ///   - section: 组名
    /// - Returns: 代码片段组对象 如果有
    func retrieveCodeClipGroupWith(name: String, inSection section: String) -> CodeClipGroup? {
        executionLock.lock()
        let copy = groupContainer[section]?[name]
        executionLock.unlock()
        return copy
    }

    /// 判断对象是否需要获取远程主机
    /// - Parameter withAnyCode: 任何 CodeClip 或者 CodeClipGroup
    /// - Returns: 是否真的需要咯
    func determineIfRemoteTargetRequired(withAnyCode code: Any) -> Bool {
        if let clip = code as? CodeClip {
            return !(clip.target == .local && clip.executor == .js)
        } else if let group = code as? CodeClipGroup {
            for step in group.payloads {
                let clip = step.code
                if !(clip.target == .local && clip.executor == .js) {
                    return true
                }
            }
            return false
        }
        #if DEBUG
            PTLog.shared.join(self,
                              "invalid object found, withAnyCode code: Any requires CodeClip/CodeClipGroup ",
                              level: .critical)
            PTFoundation.runtimeErrorCall(.badExecutionLogic)
        #else
            return false
        #endif
    }
}
